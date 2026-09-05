function toBloodInventory(doc) {
  if (!doc) return null;
  const d = doc.toObject ? doc.toObject() : doc;
  return {
    id: d.id,
    bloodBankId: d.bloodBankId,
    bloodGroup: d.bloodGroup,
    availableUnits: d.availableUnits ?? 0,
    reservedUnits: d.reservedUnits ?? 0,
    expiredUnits: d.expiredUnits ?? 0,
    unavailableUnits: d.unavailableUnits ?? 0,
    totalUnits: d.totalUnits ?? 0,
    componentType: d.componentType || 'whole_blood',
    storageLocation: d.storageLocation,
    publicVisibility: d.publicVisibility || 'inherit',
    lowStockThreshold: d.lowStockThreshold,
    criticalStockThreshold: d.criticalStockThreshold,
    expiryDates: d.expiryDates || [],
    lastUpdated: d.lastUpdated || d.updatedAt,
    createdAt: d.createdAt,
    updatedAt: d.updatedAt,
  };
}

function toBloodOrder(doc) {
  if (!doc) return null;
  const d = doc.toObject ? doc.toObject() : doc;
  return {
    id: d.id,
    bloodBankId: d.bloodBankId,
    patientId: d.patientId,
    patientName: d.patientName,
    patientMobile: d.patientMobile,
    patientEmail: d.patientEmail,
    patientAge: d.patientAge,
    patientGender: d.patientGender,
    hospitalName: d.hospitalName,
    hospitalAddress: d.hospitalAddress,
    doctorName: d.doctorName,
    doctorContact: d.doctorContact,
    requiredDate: d.requiredDate,
    requiredTime: d.requiredTime,
    requestType: d.requestType || (d.isEmergency ? 'emergency' : 'normal'),
    reservationId: d.reservationId,
    reservationExpiresAt: d.reservationExpiresAt,
    bloodGroup: d.bloodGroup,
    componentType: d.componentType,
    units: d.units,
    prescriptionUrl: d.prescriptionUrl,
    deliveryMethod: d.deliveryMethod,
    deliveryAddress: d.deliveryAddress,
    deliveryDate: d.deliveryDate,
    deliveryTimeSlot: d.deliveryTimeSlot,
    couponCode: d.couponCode,
    discountAmount: d.discountAmount ?? 0,
    baseAmount: d.baseAmount ?? 0,
    totalAmount: d.totalAmount ?? 0,
    paymentMethod: d.paymentMethod,
    paymentStatus: d.paymentStatus,
    razorpayOrderId: d.razorpayOrderId,
    razorpayPaymentId: d.razorpayPaymentId,
    paymentExpiresAt: d.paymentExpiresAt,
    status: d.status,
    rejectionReason: d.rejectionReason,
    rejectionReasonCode: d.rejectionReasonCode,
    isEmergency: Boolean(d.isEmergency),
    estimatedDeliveryTime: d.estimatedDeliveryTime,
    invoiceUrl: d.invoiceUrl,
    notes: d.notes,
    deliveryContact: d.deliveryContact,
    assignedStaffId: d.assignedStaffId,
    deliveryStatus: d.deliveryStatus || 'not_applicable',
    chatEnabled: Boolean(d.chatEnabled),
    createdAt: d.createdAt,
    updatedAt: d.updatedAt,
  };
}

function toBloodReview(doc) {
  if (!doc) return null;
  const d = doc.toObject ? doc.toObject() : doc;
  return {
    id: d.id,
    bloodBankId: d.bloodBankId,
    patientId: d.patientId,
    patientName: d.patientName,
    rating: d.rating,
    comment: d.comment,
    orderId: d.orderId,
    createdAt: d.createdAt,
  };
}

function toEmergencyBloodRequest(doc) {
  if (!doc) return null;
  const d = doc.toObject ? doc.toObject() : doc;
  return {
    id: d.id,
    patientId: d.patientId,
    bloodGroup: d.bloodGroup,
    componentType: d.componentType || 'whole_blood',
    units: d.units,
    patientName: d.patientName,
    hospitalName: d.hospitalName,
    hospitalAddress: d.hospitalAddress,
    contactNumber: d.contactNumber,
    requiredWithin: d.requiredWithin,
    additionalNotes: d.additionalNotes,
    latitude: d.latitude,
    longitude: d.longitude,
    city: d.city,
    status: d.status,
    notifiedBloodBankIds: d.notifiedBloodBankIds || [],
    assignedBloodBankId: d.assignedBloodBankId,
    confirmedUnits: d.confirmedUnits ?? 0,
    reservationId: d.reservationId,
    acceptedAt: d.acceptedAt,
    fulfilledAt: d.fulfilledAt,
    donorFallbackTriggered: Boolean(d.donorFallbackTriggered),
    responses: d.responses || [],
    createdAt: d.createdAt,
    updatedAt: d.updatedAt,
  };
}

function toBloodBankStaff(doc) {
  if (!doc) return null;
  const d = doc.toObject ? doc.toObject() : doc;
  return {
    id: d.id,
    bloodBankId: d.bloodBankId,
    name: d.name,
    role: d.role || 'staff',
    permissions: d.permissions || [],
    mobileNumber: d.mobileNumber,
    email: d.email,
    active: d.active !== false,
    createdAt: d.createdAt,
    updatedAt: d.updatedAt,
  };
}

module.exports = {
  toBloodInventory,
  toBloodOrder,
  toBloodReview,
  toEmergencyBloodRequest,
  toBloodBankStaff,
};
