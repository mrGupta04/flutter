function normalizeVerificationStatus(status) {
  if (status === 'verifier_approved') return 'under_review';
  return status;
}

function toScanCenter(doc) {
  if (!doc) return null;
  const d = doc.toObject ? doc.toObject() : doc;
  return {
    id: d.id,
    centerName: d.centerName,
    ownerName: d.ownerName,
    email: d.email,
    mobileNumber: d.mobileNumber,
    countryCode: d.countryCode || '91',
    profilePicture: d.profilePicture,
    address: d.address,
    city: d.city,
    state: d.state,
    pincode: d.pincode,
    latitude: d.latitude,
    longitude: d.longitude,
    gstNumber: d.gstNumber,
    licenseNumber: d.licenseNumber,
    operatingHours: d.operatingHours,
    homeVisitAvailable: Boolean(d.homeVisitAvailable),
    available24x7: Boolean(d.available24x7),
    cashPaymentEnabled: Boolean(d.cashPaymentEnabled ?? true),
    offeredScans: d.offeredScans || [],
    offers: d.offers || [],
    appointmentSlots: d.appointmentSlots || [],
    centerImages: d.centerImages || [],
    documents: d.documents || [],
    averageRating: d.averageRating ?? 4.5,
    reviewCount: d.reviewCount ?? 0,
    verificationStatus: normalizeVerificationStatus(d.verificationStatus),
    rejectionReason: d.rejectionReason,
    documentRequestNote: d.documentRequestNote,
    isApproved: Boolean(d.isApproved),
    approvalNotes: d.approvalNotes,
    createdAt: d.createdAt,
    updatedAt: d.updatedAt,
  };
}

module.exports = { toScanCenter };
