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
    ownerName: d.ownerName || d.contactPerson,
    licenseNumber: d.licenseNumber,
    governmentRegistrationNumber: d.governmentRegistrationNumber,
    gstNumber: d.gstNumber,
    contactPerson: d.contactPerson || d.ownerName,
    email: d.email,
    mobileNumber: d.mobileNumber,
    countryCode: d.countryCode || '91',
    profilePicture: d.profilePicture,
    logoUrl: d.logoUrl,
    description: d.description,
    emergencyContact: d.emergencyContact,
    whatsappNumber: d.whatsappNumber,
    landlineNumber: d.landlineNumber,
    emailSupport: d.emailSupport,
    address: d.address,
    city: d.city,
    state: d.state,
    pincode: d.pincode,
    latitude: d.latitude,
    longitude: d.longitude,
    openingTime: d.openingTime,
    closingTime: d.closingTime,
    workingDays: d.workingDays || [],
    available24x7: Boolean(d.available24x7),
    emergencyBloodSupply: Boolean(d.emergencyBloodSupply),
    facilities: d.facilities || [],
    bloodGroupsAvailable: d.bloodGroupsAvailable || [],
    hasApheresis: Boolean(d.hasApheresis),
    hasComponentSeparation: Boolean(d.hasComponentSeparation),
    homeDeliveryAvailable: Boolean(d.homeDeliveryAvailable),
    hospitalDeliveryAvailable: Boolean(d.hospitalDeliveryAvailable),
    cashPaymentEnabled: d.cashPaymentEnabled !== false,
    bloodComponents: d.bloodComponents || [],
    offers: d.offers || [],
    galleryImages: d.galleryImages || [],
    documents: d.documents || [],
    averageRating: d.averageRating ?? 4.5,
    reviewCount: d.reviewCount ?? 0,
    verificationStatus: normalizeVerificationStatus(d.verificationStatus),
    rejectionReason: d.rejectionReason,
    documentRequestNote: d.documentRequestNote,
    isApproved: Boolean(d.isApproved),
    approvalNotes: d.approvalNotes,
    isSuspended: Boolean(d.isSuspended),
    suspensionReason: d.suspensionReason,
    createdAt: d.createdAt,
    updatedAt: d.updatedAt,
  };
}

module.exports = { toBloodBank };
