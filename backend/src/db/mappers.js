const { isDoctorLiveNow } = require('../utils/doctorPresence');

function normalizeVerificationStatus(status) {
  if (status === 'verifier_approved') return 'under_review';
  return status;
}

function toDoctor(doc) {
  if (!doc) return null;
  const d = doc.toObject ? doc.toObject() : doc;
  const lastActiveAt = d.lastActiveAt ?? null;
  return {
    id: d.id || (d._id != null ? String(d._id) : undefined),
    firstName: d.firstName,
    lastName: d.lastName,
    email: d.email,
    emailVerified: Boolean(d.emailVerified),
    emailVerifiedAt: d.emailVerifiedAt,
    mobileNumber: d.mobileNumber,
    phoneVerified: Boolean(d.phoneVerified),
    phoneVerifiedAt: d.phoneVerifiedAt,
    profilePicture: d.profilePicture,
    gender: d.gender,
    dateOfBirth: d.dateOfBirth,
    medicalRegistrationNumber: d.medicalRegistrationNumber,
    medicalCouncilName: d.medicalCouncilName,
    specializations: d.specializations || [],
    qualification: d.qualification,
    yearsOfExperience: d.yearsOfExperience,
    clinicName: d.clinicName,
    consultationFee: d.consultationFee,
    onlineConsultFee: d.onlineConsultFee,
    homeVisitFee: d.homeVisitFee,
    visitSiteFee: d.visitSiteFee,
    offersOnlineConsult: Boolean(d.offersOnlineConsult),
    offersBookHome: Boolean(d.offersBookHome),
    offersVisitSite: Boolean(d.offersVisitSite),
    languagesSpoken: d.languagesSpoken || [],
    bio: d.bio,
    address: d.address,
    city: d.city,
    state: d.state,
    pincode: d.pincode,
    latitude: d.latitude,
    longitude: d.longitude,
    medicalLicenseUrl: d.medicalLicenseUrl,
    governmentIdUrl: d.governmentIdUrl,
    degreeCertificateUrl: d.degreeCertificateUrl,
    clinicProofUrl: d.clinicProofUrl,
    hospitalPhoto1Url: d.hospitalPhoto1Url,
    hospitalPhoto2Url: d.hospitalPhoto2Url,
    hospitalPhoto3Url: d.hospitalPhoto3Url,
    hospitalPhoto4Url: d.hospitalPhoto4Url,
    hospitalPhoto5Url: d.hospitalPhoto5Url,
    bankAccountNumber: d.bankAccountNumber,
    ifscCode: d.ifscCode,
    payoutMethod: d.payoutMethod || 'bank',
    upiId: d.upiId,
    cancelledChequeUrl: d.cancelledChequeUrl,
    aadhaarLast4: d.aadhaarLast4,
    aadhaarCardUrl: d.aadhaarCardUrl,
    aadhaarVerified: Boolean(d.aadhaarVerified),
    aadhaarVerifiedAt: d.aadhaarVerifiedAt,
    verificationStatus: normalizeVerificationStatus(d.verificationStatus),
    rejectionReason: d.rejectionReason,
    isApproved: Boolean(d.isApproved),
    approvalNotes: d.approvalNotes,
    createdAt: d.createdAt,
    updatedAt: d.updatedAt,
    lastActiveAt,
    isLiveNow: isDoctorLiveNow(lastActiveAt),
    averageRating: d.averageRating ?? null,
    ratingCount: d.ratingCount ?? 0,
  };
}

function toDocument(doc) {
  if (!doc) return null;
  const d = doc.toObject ? doc.toObject() : doc;
  return {
    id: d.id,
    doctorId: d.doctorId,
    nurseId: d.nurseId,
    ambulanceId: d.ambulanceId,
    vehicleId: d.vehicleId,
    driverId: d.driverId,
    documentType: d.documentType,
    fileUrl: d.fileUrl,
    fileName: d.fileName,
    fileSize: d.fileSize,
    mimeType: d.mimeType,
    status: d.status,
    rejectionReason: d.rejectionReason,
    uploadedAt: d.uploadedAt || d.createdAt,
    verifiedAt: d.verifiedAt,
    verifiedBy: d.verifiedBy,
  };
}

module.exports = { toDoctor, toDocument };
