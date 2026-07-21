function normalizeVerificationStatus(status) {
  if (status === 'verifier_approved') return 'under_review';
  return status;
}

const { isDoctorLiveNow } = require('../utils/doctorPresence');

function toNurse(doc) {
  if (!doc) return null;
  const d = doc.toObject ? doc.toObject() : doc;
  const lastActiveAt = d.lastActiveAt ?? null;
  return {
    id: d.id,
    firstName: d.firstName,
    lastName: d.lastName,
    email: d.email,
    mobileNumber: d.mobileNumber,
    countryCode: d.countryCode || '91',
    profilePicture: d.profilePicture,
    gender: d.gender,
    dateOfBirth: d.dateOfBirth,
    languagesSpoken: d.languagesSpoken || [],
    emergencyContactName: d.emergencyContactName,
    emergencyContactNumber: d.emergencyContactNumber,
    qualification: d.qualification,
    registrationNumber: d.registrationNumber,
    nursingCouncil: d.nursingCouncil,
    nuid: d.nuid,
    yearsOfExperience: d.yearsOfExperience,
    specialization: d.specialization,
    nursingSkills: d.nursingSkills || [],
    address: d.address,
    city: d.city,
    state: d.state,
    pincode: d.pincode,
    latitude: d.latitude,
    longitude: d.longitude,
    serviceRadiusKm: d.serviceRadiusKm,
    availableForHomeVisit: d.availableForHomeVisit !== false,
    homeVisitFee: d.homeVisitFee,
    homeVisitOfferFee: d.homeVisitOfferFee,
    shiftAvailability: d.shiftAvailability,
    bankAccountHolderName: d.bankAccountHolderName,
    bankAccountNumber: d.bankAccountNumber,
    ifscCode: d.ifscCode,
    bankName: d.bankName,
    verificationStatus: normalizeVerificationStatus(d.verificationStatus),
    rejectionReason: d.rejectionReason,
    isApproved: Boolean(d.isApproved),
    approvalNotes: d.approvalNotes,
    averageRating: d.averageRating ?? null,
    ratingCount: d.ratingCount ?? 0,
    lastActiveAt,
    isLiveNow: isDoctorLiveNow(lastActiveAt),
    createdAt: d.createdAt,
    updatedAt: d.updatedAt,
  };
}

module.exports = { toNurse };
