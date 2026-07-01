function toBloodInventory(doc) {
  if (!doc) return null;
  const d = doc.toObject ? doc.toObject() : doc;
  return {
    id: d.id,
    bloodBankId: d.bloodBankId,
    bloodGroup: d.bloodGroup,
    availableUnits: d.availableUnits ?? 0,
    reservedUnits: d.reservedUnits ?? 0,
    totalUnits: d.totalUnits ?? 0,
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
    isEmergency: Boolean(d.isEmergency),
    estimatedDeliveryTime: d.estimatedDeliveryTime,
    invoiceUrl: d.invoiceUrl,
    notes: d.notes,
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
    units: d.units,
    patientName: d.patientName,
    hospitalName: d.hospitalName,
    contactNumber: d.contactNumber,
    requiredWithin: d.requiredWithin,
    additionalNotes: d.additionalNotes,
    latitude: d.latitude,
    longitude: d.longitude,
    city: d.city,
    status: d.status,
    assignedBloodBankId: d.assignedBloodBankId,
    acceptedAt: d.acceptedAt,
    fulfilledAt: d.fulfilledAt,
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
    role: d.role,
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
