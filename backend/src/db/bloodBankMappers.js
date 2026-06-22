function normalizeVerificationStatus(status) {
  if (status === 'verifier_approved') return 'under_review';
  return status;
}

function toBloodBank(doc) {
  if (!doc) return null;
  const d = doc.toObject ? doc.toObject() : doc;
  return {
    id: d.id,
    institutionName: d.institutionName,
    licenseNumber: d.licenseNumber,
    contactPerson: d.contactPerson,
    email: d.email,
    mobileNumber: d.mobileNumber,
    countryCode: d.countryCode || '91',
    profilePicture: d.profilePicture,
    emergencyContact: d.emergencyContact,
    address: d.address,
    city: d.city,
    state: d.state,
    pincode: d.pincode,
    latitude: d.latitude,
    longitude: d.longitude,
    bloodGroupsAvailable: d.bloodGroupsAvailable || [],
    hasApheresis: Boolean(d.hasApheresis),
    hasComponentSeparation: Boolean(d.hasComponentSeparation),
    available24x7: Boolean(d.available24x7),
    verificationStatus: normalizeVerificationStatus(d.verificationStatus),
    rejectionReason: d.rejectionReason,
    isApproved: Boolean(d.isApproved),
    approvalNotes: d.approvalNotes,
    createdAt: d.createdAt,
    updatedAt: d.updatedAt,
  };
}

module.exports = { toBloodBank };
