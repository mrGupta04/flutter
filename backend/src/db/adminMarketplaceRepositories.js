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

module.exports = {
  getAdminMarketplaceOverview,
  listAdminBookings,
};
