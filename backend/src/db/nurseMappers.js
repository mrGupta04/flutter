function normalizeVerificationStatus(status) {
  if (status === 'verifier_approved') return 'under_review';
  return status;
}

function toNurse(doc) {
  if (!doc) return null;
  const d = doc.toObject ? doc.toObject() : doc;
  return {
    id: d.id,
    firstName: d.firstName,
    lastName: d.lastName,
    email: d.email,
    mobileNumber: d.mobileNumber,
    countryCode: d.countryCode || '91',
    profilePicture: d.profilePicture,
    qualification: d.qualification,
    registrationNumber: d.registrationNumber,
    nursingCouncil: d.nursingCouncil,
    yearsOfExperience: d.yearsOfExperience,
    specialization: d.specialization,
    address: d.address,
    city: d.city,
    state: d.state,
    pincode: d.pincode,
    latitude: d.latitude,
    longitude: d.longitude,
    availableForHomeVisit: Boolean(d.availableForHomeVisit),
    shiftAvailability: d.shiftAvailability,
    verificationStatus: normalizeVerificationStatus(d.verificationStatus),
    rejectionReason: d.rejectionReason,
    isApproved: Boolean(d.isApproved),
    approvalNotes: d.approvalNotes,
    createdAt: d.createdAt,
    updatedAt: d.updatedAt,
  };
}

module.exports = { toNurse };
