const ConsultationBooking = require('./models/ConsultationBooking');
const Patient = require('./models/Patient');
const LabBooking = require('./models/LabBooking');
const ScanBooking = require('./models/ScanBooking');
const AmbulanceBooking = require('./models/AmbulanceBooking');
const BloodOrder = require('./models/BloodOrder');
const Doctor = require('./models/Doctor');
const Nurse = require('./models/Nurse');
const Lab = require('./models/Lab');
const ScanCenter = require('./models/ScanCenter');
const Ambulance = require('./models/Ambulance');
const BloodBank = require('./models/BloodBank');

async function getAdminMarketplaceOverview() {
  const [
    patients,
    doctorsPending,
    nursesPending,
    labsPending,
    scansPending,
    ambulancesPending,
    bloodBanksPending,
    consultBookings,
    labBookings,
    scanBookings,
    ambulanceBookings,
    bloodOrders,
    confirmedConsults,
    paidBlood,
  ] = await Promise.all([
    Patient.countDocuments(),
    Doctor.countDocuments({ verificationStatus: { $in: ['under_review', 'pending'] } }),
    Nurse.countDocuments({ verificationStatus: { $in: ['under_review', 'pending'] } }),
    Lab.countDocuments({ verificationStatus: { $in: ['under_review', 'pending'] } }),
    ScanCenter.countDocuments({ verificationStatus: { $in: ['under_review', 'pending'] } }),
    Ambulance.countDocuments({ verificationStatus: { $in: ['under_review', 'pending'] } }),
    BloodBank.countDocuments({ verificationStatus: { $in: ['under_review', 'pending'] } }),
    ConsultationBooking.countDocuments(),
    LabBooking.countDocuments(),
    ScanBooking.countDocuments(),
    AmbulanceBooking.countDocuments(),
    BloodOrder.countDocuments(),
    ConsultationBooking.find({ status: 'confirmed', paymentStatus: 'paid' })
      .select('consultationFee')
      .lean(),
    BloodOrder.find({ paymentStatus: 'paid' }).select('totalAmount').lean(),
  ]);

  const consultRevenue = confirmedConsults.reduce(
    (sum, b) => sum + (Number(b.consultationFee) || 0),
    0,
  );
  const bloodRevenue = paidBlood.reduce(
    (sum, b) => sum + (Number(b.totalAmount) || 0),
    0,
  );

  const recentConsults = await ConsultationBooking.find()
    .sort({ createdAt: -1 })
    .limit(20)
    .lean();

  const recent = recentConsults.map((b) => ({
    id: b.id,
    type: 'consultation',
    title: b.patientName || 'Patient',
    subtitle: b.consultationType || 'consult',
    status: b.status,
    amount: b.consultationFee || 0,
    createdAt: b.createdAt,
  }));

  return {
    stats: {
      patients,
      pendingApprovals:
        doctorsPending +
        nursesPending +
        labsPending +
        scansPending +
        ambulancesPending +
        bloodBanksPending,
      totalBookings:
        consultBookings + labBookings + scanBookings + ambulanceBookings + bloodOrders,
      consultBookings,
      labBookings,
      scanBookings,
      ambulanceBookings,
      bloodOrders,
      revenueInr: consultRevenue + bloodRevenue,
    },
    pendingByType: {
      doctors: doctorsPending,
      nurses: nursesPending,
      labs: labsPending,
      scanCenters: scansPending,
      ambulances: ambulancesPending,
      bloodBanks: bloodBanksPending,
    },
    recentBookings: recent,
  };
}

async function listAdminBookings({ page = 1, pageSize = 30 } = {}) {
  const consults = await ConsultationBooking.find()
    .sort({ createdAt: -1 })
    .limit(pageSize)
    .lean();
  const labs = await LabBooking.find().sort({ createdAt: -1 }).limit(pageSize).lean();
  const scans = await ScanBooking.find().sort({ createdAt: -1 }).limit(pageSize).lean();
  const ambulances = await AmbulanceBooking.find()
    .sort({ createdAt: -1 })
    .limit(pageSize)
    .lean();

  const items = [
    ...consults.map((b) => ({
      id: b.id,
      category: 'consultation',
      patientName: b.patientName,
      providerName: b.doctorId || b.nurseId,
      status: b.status,
      paymentStatus: b.paymentStatus,
      amount: b.consultationFee || 0,
      createdAt: b.createdAt,
      label: b.consultationType,
    })),
    ...labs.map((b) => ({
      id: b.id,
      category: 'lab',
      patientName: b.patientName,
      providerName: b.labName,
      status: b.status,
      paymentStatus: b.paymentStatus,
      amount: b.totalAmount || 0,
      createdAt: b.createdAt,
      label: 'Lab test',
    })),
    ...scans.map((b) => ({
      id: b.id,
      category: 'scan',
      patientName: b.patientName,
      providerName: b.scanCenterName,
      status: b.status,
      paymentStatus: b.paymentStatus,
      amount: b.totalAmount || 0,
      createdAt: b.createdAt,
      label: b.scanName,
    })),
    ...ambulances.map((b) => ({
      id: b.id,
      category: 'ambulance',
      patientName: b.patientName,
      providerName: b.ambulanceServiceName,
      status: b.status,
      paymentStatus: null,
      amount: 0,
      createdAt: b.createdAt,
      label: 'Ambulance',
    })),
  ]
    .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
    .slice(0, pageSize);

  return {
    bookings: items,
    pagination: {
      currentPage: page,
      pageSize,
      totalCount: items.length,
    },
  };
}

function doctorDisplayName(doctor) {
  if (!doctor) return null;
  const name = [doctor.firstName, doctor.lastName].filter(Boolean).join(' ').trim();
  return name || doctor.email || doctor.id;
}

function computeFinalOutcome(booking, now = new Date()) {
  if (booking.paymentStatus === 'failed') return 'defect';
  if (booking.paymentStatus === 'refunded') return 'refunded';
  if (booking.status === 'cancelled') return 'cancelled';

  const slotEnd = booking.slotEnd ? new Date(booking.slotEnd) : null;
  const pastSlot = slotEnd && slotEnd.getTime() < now.getTime();

  if (booking.consultationType === 'online_consult') {
    const doctorJoined = Boolean(booking.doctorJoinedAt);
    const patientJoined = Boolean(booking.patientJoinedAt);
    if (booking.videoCallEndedAt && doctorJoined && patientJoined) {
      return 'successful';
    }
    if (pastSlot) {
      if (doctorJoined && patientJoined) return 'successful';
      if (!doctorJoined && !patientJoined) return 'defect';
      if (!doctorJoined) return 'defect';
      if (!patientJoined) return 'defect';
    }
    if (booking.status === 'confirmed' && booking.paymentStatus === 'paid') {
      return 'in_progress';
    }
    return booking.status || 'pending';
  }

  if (booking.consultationType === 'book_home') {
    if (booking.doctorRejectedAt) return 'defect';
    if (booking.visitProgress === 'completed' || booking.visitCompletedAt) {
      return 'successful';
    }
    if (
      ['en_route', 'arrived', 'visit_started'].includes(booking.visitProgress) ||
      booking.visitStartedAt
    ) {
      return 'in_progress';
    }
    if (pastSlot && booking.status === 'confirmed') return 'defect';
    if (
      booking.status === 'confirmed' ||
      booking.status === 'awaiting_doctor_approval' ||
      booking.status === 'approved_pending_payment'
    ) {
      return 'in_progress';
    }
    return booking.status || 'pending';
  }

  // hospital / clinic visit
  if (booking.doctorRejectedAt) return 'defect';
  if (booking.appointmentVerifiedAt) return 'successful';
  if (pastSlot && booking.status === 'confirmed') return 'defect';
  if (
    booking.status === 'confirmed' ||
    booking.status === 'awaiting_doctor_approval' ||
    booking.status === 'approved_pending_payment'
  ) {
    return 'in_progress';
  }
  return booking.status || 'pending';
}

function isNurseBooking(booking) {
  return (
    booking?.providerType === 'nurse' ||
    (Boolean(booking?.nurseId) && !booking?.doctorId)
  );
}

/** Normalized provider/patient event times for admin session rows. */
function sessionActionTimes(booking) {
  const providerWord = isNurseBooking(booking) ? 'Nurse' : 'Doctor';
  if (booking.consultationType === 'online_consult') {
    return {
      doctorActionLabel: `${providerWord} joined`,
      doctorActionAt: booking.doctorJoinedAt || null,
      patientActionLabel: 'User joined',
      patientActionAt: booking.patientJoinedAt || null,
    };
  }
  if (booking.consultationType === 'book_home') {
    return {
      doctorActionLabel: `${providerWord} started visit`,
      doctorActionAt:
        booking.visitStartedAt ||
        (['en_route', 'arrived', 'visit_started', 'completed'].includes(
          booking.visitProgress,
        )
          ? booking.updatedAt
          : null) ||
        booking.doctorApprovedAt ||
        null,
      patientActionLabel: 'Patient confirmed',
      patientActionAt: booking.paidAt || booking.createdAt || null,
    };
  }
  // hospital / clinic visit
  return {
    doctorActionLabel: `${providerWord} approved`,
    doctorActionAt: booking.doctorApprovedAt || null,
    patientActionLabel: 'Patient checked in',
    patientActionAt: booking.appointmentVerifiedAt || null,
  };
}

async function listAdminConsultationBookings({
  consultationType,
  providerType = 'doctor',
  page = 1,
  pageSize = 50,
  status,
  paymentStatus,
  search,
} = {}) {
  const filter = {};
  const andClauses = [];

  if (providerType === 'nurse') {
    andClauses.push({
      $or: [
        { providerType: 'nurse' },
        {
          nurseId: { $exists: true, $nin: [null, ''] },
          $or: [{ doctorId: null }, { doctorId: '' }, { doctorId: { $exists: false } }],
        },
      ],
    });
  } else {
    andClauses.push({
      $or: [
        { providerType: 'doctor' },
        { doctorId: { $exists: true, $nin: [null, ''] } },
      ],
    });
  }

  if (consultationType) filter.consultationType = consultationType;
  if (status) filter.status = status;
  if (paymentStatus) filter.paymentStatus = paymentStatus;
  if (search?.trim()) {
    const regex = new RegExp(
      String(search).trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&'),
      'i',
    );
    andClauses.push({
      $or: [
        { patientName: regex },
        { patientMobile: regex },
        { patientEmail: regex },
        { id: regex },
        { doctorId: regex },
        { nurseId: regex },
      ],
    });
  }
  if (andClauses.length) filter.$and = andClauses;

  const totalCount = await ConsultationBooking.countDocuments(filter);
  const docs = await ConsultationBooking.find(filter)
    .sort({ createdAt: -1 })
    .skip((page - 1) * pageSize)
    .limit(pageSize)
    .lean();

  const doctorIds = [...new Set(docs.map((d) => d.doctorId).filter(Boolean))];
  const nurseIds = [...new Set(docs.map((d) => d.nurseId).filter(Boolean))];
  const [doctors, nurses] = await Promise.all([
    doctorIds.length
      ? Doctor.find({ id: { $in: doctorIds } })
          .select(
            'id firstName lastName email mobileNumber specializations profilePicture verificationStatus clinicName city state',
          )
          .lean()
      : [],
    nurseIds.length
      ? Nurse.find({ id: { $in: nurseIds } })
          .select(
            'id firstName lastName email mobileNumber qualification profilePicture verificationStatus city state yearsOfExperience',
          )
          .lean()
      : [],
  ]);
  const doctorById = Object.fromEntries(doctors.map((d) => [d.id, d]));
  const nurseById = Object.fromEntries(nurses.map((n) => [n.id, n]));
  const now = new Date();

  const bookings = docs.map((b) => {
    const nurseBooking = isNurseBooking(b);
    const doctor = doctorById[b.doctorId] || null;
    const nurse = nurseById[b.nurseId] || null;
    const provider = nurseBooking ? nurse : doctor;
    const providerName =
      doctorDisplayName(provider) ||
      (nurseBooking ? b.nurseId : b.doctorId) ||
      (nurseBooking ? 'Nurse' : 'Doctor');
    const actions = sessionActionTimes(b);
    return {
      id: b.id,
      providerType: nurseBooking ? 'nurse' : 'doctor',
      consultationType: b.consultationType,
      patientId: b.patientId || null,
      patientName: b.patientName,
      patientMobile: b.patientMobile,
      patientEmail: b.patientEmail || null,
      patientAddress: b.patientAddress || null,
      patientCity: b.patientCity || null,
      doctorId: b.doctorId || null,
      nurseId: b.nurseId || null,
      providerId: nurseBooking ? b.nurseId : b.doctorId,
      doctorName: providerName,
      providerName,
      doctorSpecialty:
        doctor?.specializations?.[0] || nurse?.qualification || null,
      clinicName: doctor?.clinicName || null,
      paymentStatus: b.paymentStatus,
      bookingStatus: b.status,
      amount: b.amountPaid ?? b.consultationFee ?? 0,
      currency: b.currency || 'INR',
      paidAt: b.paidAt || null,
      slotStart: b.slotStart,
      slotEnd: b.slotEnd,
      doctorJoinedAt: b.doctorJoinedAt || null,
      patientJoinedAt: b.patientJoinedAt || null,
      doctorActionLabel: actions.doctorActionLabel,
      doctorActionAt: actions.doctorActionAt,
      patientActionLabel: actions.patientActionLabel,
      patientActionAt: actions.patientActionAt,
      videoCallStartedAt: b.videoCallStartedAt || null,
      videoCallEndedAt: b.videoCallEndedAt || null,
      doctorApprovedAt: b.doctorApprovedAt || null,
      doctorRejectedAt: b.doctorRejectedAt || null,
      visitProgress: b.visitProgress || null,
      visitStartedAt: b.visitStartedAt || null,
      visitCompletedAt: b.visitCompletedAt || null,
      appointmentCode: b.appointmentCode || null,
      appointmentVerifiedAt: b.appointmentVerifiedAt || null,
      finalOutcome: computeFinalOutcome(b, now),
      createdAt: b.createdAt,
      updatedAt: b.updatedAt,
    };
  });

  return {
    bookings,
    pagination: {
      currentPage: page,
      pageSize,
      totalCount,
      totalPages: Math.max(1, Math.ceil(totalCount / pageSize)),
    },
  };
}

async function getAdminConsultationBookingDetail(id) {
  const booking = await ConsultationBooking.findOne({ id }).lean();
  if (!booking) {
    const err = new Error('Booking not found');
    err.statusCode = 404;
    throw err;
  }

  const nurseBooking = isNurseBooking(booking);
  const [doctor, nurse, patient] = await Promise.all([
    booking.doctorId
      ? Doctor.findOne({ id: booking.doctorId }).lean()
      : null,
    booking.nurseId
      ? Nurse.findOne({ id: booking.nurseId }).lean()
      : null,
    booking.patientId
      ? Patient.findOne({ id: booking.patientId }).lean()
      : null,
  ]);

  const provider = nurseBooking ? nurse : doctor;
  const actions = sessionActionTimes(booking);
  const summary = {
    id: booking.id,
    providerType: nurseBooking ? 'nurse' : 'doctor',
    consultationType: booking.consultationType,
    patientId: booking.patientId || null,
    patientName: booking.patientName,
    patientMobile: booking.patientMobile,
    patientEmail: booking.patientEmail || null,
    patientAddress: booking.patientAddress || null,
    patientCity: booking.patientCity || null,
    doctorId: booking.doctorId || null,
    nurseId: booking.nurseId || null,
    providerId: nurseBooking ? booking.nurseId : booking.doctorId,
    doctorName:
      doctorDisplayName(provider) ||
      (nurseBooking ? booking.nurseId : booking.doctorId) ||
      (nurseBooking ? 'Nurse' : 'Doctor'),
    providerName:
      doctorDisplayName(provider) ||
      (nurseBooking ? booking.nurseId : booking.doctorId) ||
      (nurseBooking ? 'Nurse' : 'Doctor'),
    paymentStatus: booking.paymentStatus,
    bookingStatus: booking.status,
    amount: booking.amountPaid ?? booking.consultationFee ?? 0,
    currency: booking.currency || 'INR',
    paidAt: booking.paidAt || null,
    slotStart: booking.slotStart,
    slotEnd: booking.slotEnd,
    doctorJoinedAt: booking.doctorJoinedAt || null,
    patientJoinedAt: booking.patientJoinedAt || null,
    doctorActionLabel: actions.doctorActionLabel,
    doctorActionAt: actions.doctorActionAt,
    patientActionLabel: actions.patientActionLabel,
    patientActionAt: actions.patientActionAt,
    videoCallStartedAt: booking.videoCallStartedAt || null,
    videoCallEndedAt: booking.videoCallEndedAt || null,
    doctorApprovedAt: booking.doctorApprovedAt || null,
    doctorRejectedAt: booking.doctorRejectedAt || null,
    visitProgress: booking.visitProgress || null,
    visitStartedAt: booking.visitStartedAt || null,
    visitCompletedAt: booking.visitCompletedAt || null,
    appointmentCode: booking.appointmentCode || null,
    appointmentVerifiedAt: booking.appointmentVerifiedAt || null,
    finalOutcome: computeFinalOutcome(booking),
    createdAt: booking.createdAt,
    updatedAt: booking.updatedAt,
  };

  return {
    ...summary,
    booking,
    doctor: doctor
      ? {
          id: doctor.id,
          firstName: doctor.firstName,
          lastName: doctor.lastName,
          name: doctorDisplayName(doctor),
          email: doctor.email,
          mobileNumber: doctor.mobileNumber,
          specializations: doctor.specializations || [],
          qualification: doctor.qualification,
          clinicName: doctor.clinicName,
          address: doctor.address,
          city: doctor.city,
          state: doctor.state,
          pincode: doctor.pincode,
          profilePicture: doctor.profilePicture,
          verificationStatus: doctor.verificationStatus,
          offersOnlineConsult: doctor.offersOnlineConsult,
          offersBookHome: doctor.offersBookHome,
          offersVisitSite: doctor.offersVisitSite,
        }
      : null,
    nurse: nurse
      ? {
          id: nurse.id,
          firstName: nurse.firstName,
          lastName: nurse.lastName,
          name: doctorDisplayName(nurse),
          email: nurse.email,
          mobileNumber: nurse.mobileNumber,
          qualification: nurse.qualification,
          yearsOfExperience: nurse.yearsOfExperience,
          city: nurse.city,
          state: nurse.state,
          profilePicture: nurse.profilePicture,
          verificationStatus: nurse.verificationStatus,
        }
      : null,
    provider: nurseBooking
      ? nurse
        ? {
            id: nurse.id,
            role: 'nurse',
            name: doctorDisplayName(nurse),
            email: nurse.email,
            mobileNumber: nurse.mobileNumber,
            qualification: nurse.qualification,
            yearsOfExperience: nurse.yearsOfExperience,
            city: nurse.city,
            state: nurse.state,
            profilePicture: nurse.profilePicture,
            verificationStatus: nurse.verificationStatus,
          }
        : null
      : doctor
        ? {
            id: doctor.id,
            role: 'doctor',
            name: doctorDisplayName(doctor),
            email: doctor.email,
            mobileNumber: doctor.mobileNumber,
            specializations: doctor.specializations || [],
            qualification: doctor.qualification,
            clinicName: doctor.clinicName,
            city: doctor.city,
            state: doctor.state,
            profilePicture: doctor.profilePicture,
            verificationStatus: doctor.verificationStatus,
          }
        : null,
    patient: patient
      ? {
          id: patient.id,
          firstName: patient.firstName,
          lastName: patient.lastName,
          name:
            [patient.firstName, patient.lastName].filter(Boolean).join(' ').trim() ||
            booking.patientName,
          email: patient.email,
          mobileNumber: patient.mobileNumber,
          gender: patient.gender,
          dateOfBirth: patient.dateOfBirth,
          city: patient.city,
          state: patient.state,
          profilePicture: patient.profilePicture,
        }
      : {
          id: booking.patientId || null,
          name: booking.patientName,
          email: booking.patientEmail || null,
          mobileNumber: booking.patientMobile,
        },
  };
}

function computeDiagnosticFinalOutcome(booking) {
  if (booking.paymentStatus === 'failed') return 'defect';
  if (booking.paymentStatus === 'refunded') return 'refunded';
  if (['cancelled', 'rejected'].includes(booking.status)) return 'defect';
  if (booking.reportAcceptedByUserAt || booking.status === 'completed') {
    return 'successful';
  }
  if (
    booking.reportSubmittedAt ||
    booking.reportUrl ||
    ['report_ready', 'processing', 'sample_collected', 'in_progress', 'confirmed'].includes(
      booking.status,
    )
  ) {
    return 'in_progress';
  }
  return booking.status || 'pending';
}

async function listAdminDiagnosticBookings({
  kind = 'lab',
  page = 1,
  pageSize = 50,
  status,
  paymentStatus,
  search,
} = {}) {
  const Model = kind === 'scan' ? ScanBooking : LabBooking;
  const filter = {};
  if (status) filter.status = status;
  if (paymentStatus) filter.paymentStatus = paymentStatus;
  if (search?.trim()) {
    const regex = new RegExp(
      String(search).trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&'),
      'i',
    );
    filter.$or = [
      { patientName: regex },
      { patientMobile: regex },
      { patientEmail: regex },
      { id: regex },
      ...(kind === 'scan'
        ? [{ scanCenterName: regex }, { scanName: regex }, { scanCenterId: regex }]
        : [{ labName: regex }, { labId: regex }]),
    ];
  }

  const totalCount = await Model.countDocuments(filter);
  const docs = await Model.find(filter)
    .sort({ createdAt: -1 })
    .skip((page - 1) * pageSize)
    .limit(pageSize)
    .lean();

  const providerIds = [
    ...new Set(
      docs
        .map((d) => (kind === 'scan' ? d.scanCenterId : d.labId))
        .filter(Boolean),
    ),
  ];
  const providers = providerIds.length
    ? await (kind === 'scan' ? ScanCenter : Lab)
        .find({ id: { $in: providerIds } })
        .select(
          kind === 'scan'
            ? 'id centerName ownerName email mobileNumber city state verificationStatus'
            : 'id labName ownerName email mobileNumber city state verificationStatus',
        )
        .lean()
    : [];
  const providerById = Object.fromEntries(providers.map((p) => [p.id, p]));

  const bookings = docs.map((b) => {
    const provider = providerById[kind === 'scan' ? b.scanCenterId : b.labId];
    const providerName =
      (kind === 'scan'
        ? provider?.centerName || b.scanCenterName
        : provider?.labName || b.labName) || 'Provider';
    const sampleCollected = Boolean(
      b.sampleCollectedAt ||
        (kind === 'lab'
          ? ['sample_collected', 'processing', 'report_ready', 'completed'].includes(
              b.status,
            )
          : ['in_progress', 'report_ready', 'completed'].includes(b.status)),
    );
    const reportSubmitted = Boolean(
      b.reportSubmittedAt ||
        b.reportUrl ||
        ['report_ready', 'completed'].includes(b.status),
    );
    const acceptedByUser = Boolean(
      b.reportAcceptedByUserAt || b.status === 'completed',
    );
    return {
      id: b.id,
      kind,
      patientId: b.patientId || null,
      patientName: b.patientName,
      patientMobile: b.patientMobile,
      patientEmail: b.patientEmail || null,
      providerId: kind === 'scan' ? b.scanCenterId : b.labId,
      providerName,
      serviceLabel:
        kind === 'scan'
          ? b.scanName
          : (b.items || []).map((i) => i.testName).filter(Boolean).join(', ') ||
            'Lab tests',
      collectionType: b.collectionType || null,
      paymentStatus: b.paymentStatus,
      bookingStatus: b.status,
      amount: b.totalAmount || 0,
      scheduledDate: b.scheduledDate,
      timeSlot: b.timeSlot,
      sampleCollected,
      sampleCollectedAt: b.sampleCollectedAt || null,
      reportSubmitted,
      reportSubmittedAt: b.reportSubmittedAt || null,
      reportUrl: b.reportUrl || null,
      acceptedByUser,
      reportAcceptedByUserAt: b.reportAcceptedByUserAt || null,
      finalOutcome: computeDiagnosticFinalOutcome(b),
      createdAt: b.createdAt,
      updatedAt: b.updatedAt,
    };
  });

  return {
    bookings,
    pagination: {
      currentPage: page,
      pageSize,
      totalCount,
      totalPages: Math.max(1, Math.ceil(totalCount / pageSize)),
    },
  };
}

async function getAdminDiagnosticBookingDetail(kind, id) {
  const Model = kind === 'scan' ? ScanBooking : LabBooking;
  const booking = await Model.findOne({ id }).lean();
  if (!booking) {
    const err = new Error('Booking not found');
    err.statusCode = 404;
    throw err;
  }

  const providerId = kind === 'scan' ? booking.scanCenterId : booking.labId;
  const [provider, patient] = await Promise.all([
    providerId
      ? (kind === 'scan' ? ScanCenter : Lab).findOne({ id: providerId }).lean()
      : null,
    booking.patientId
      ? Patient.findOne({ id: booking.patientId }).lean()
      : null,
  ]);

  const sampleCollected = Boolean(
    booking.sampleCollectedAt ||
      (kind === 'lab'
        ? ['sample_collected', 'processing', 'report_ready', 'completed'].includes(
            booking.status,
          )
        : ['in_progress', 'report_ready', 'completed'].includes(booking.status)),
  );
  const reportSubmitted = Boolean(
    booking.reportSubmittedAt ||
      booking.reportUrl ||
      ['report_ready', 'completed'].includes(booking.status),
  );
  const acceptedByUser = Boolean(
    booking.reportAcceptedByUserAt || booking.status === 'completed',
  );

  return {
    id: booking.id,
    kind,
    patientId: booking.patientId || null,
    patientName: booking.patientName,
    patientMobile: booking.patientMobile,
    patientEmail: booking.patientEmail || null,
    providerId,
    providerName:
      (kind === 'scan'
        ? provider?.centerName || booking.scanCenterName
        : provider?.labName || booking.labName) || 'Provider',
    serviceLabel:
      kind === 'scan'
        ? booking.scanName
        : (booking.items || []).map((i) => i.testName).filter(Boolean).join(', ') ||
          'Lab tests',
    collectionType: booking.collectionType || null,
    paymentStatus: booking.paymentStatus,
    bookingStatus: booking.status,
    amount: booking.totalAmount || 0,
    scheduledDate: booking.scheduledDate,
    timeSlot: booking.timeSlot,
    sampleCollected,
    sampleCollectedAt: booking.sampleCollectedAt || null,
    reportSubmitted,
    reportSubmittedAt: booking.reportSubmittedAt || null,
    reportUrl: booking.reportUrl || null,
    reportFileName: booking.reportFileName || null,
    acceptedByUser,
    reportAcceptedByUserAt: booking.reportAcceptedByUserAt || null,
    finalOutcome: computeDiagnosticFinalOutcome(booking),
    booking,
    provider: provider
      ? {
          id: provider.id,
          name:
            kind === 'scan'
              ? provider.centerName || provider.ownerName
              : provider.labName || provider.ownerName,
          email: provider.email,
          mobileNumber: provider.mobileNumber,
          city: provider.city,
          state: provider.state,
          verificationStatus: provider.verificationStatus,
        }
      : null,
    patient: patient
      ? {
          id: patient.id,
          name:
            [patient.firstName, patient.lastName].filter(Boolean).join(' ').trim() ||
            booking.patientName,
          email: patient.email,
          mobileNumber: patient.mobileNumber,
          city: patient.city,
          state: patient.state,
          profilePicture: patient.profilePicture,
        }
      : {
          id: booking.patientId || null,
          name: booking.patientName,
          email: booking.patientEmail || null,
          mobileNumber: booking.patientMobile,
        },
  };
}

module.exports = {
  getAdminMarketplaceOverview,
  listAdminBookings,
  listAdminConsultationBookings,
  getAdminConsultationBookingDetail,
  listAdminDiagnosticBookings,
  getAdminDiagnosticBookingDetail,
};
