const mongoose = require('mongoose');

const offeredScanSchema = new mongoose.Schema(
  {
    scanId: { type: String, required: true },
    scanName: String,
    categoryId: String,
    description: String,
    preparationInstructions: String,
    fastingRequired: { type: Boolean, default: false },
    homeVisitAvailable: { type: Boolean, default: false },
    onsiteOnly: { type: Boolean, default: true },
    priceInr: Number,
    discountedPriceInr: Number,
    reportDeliveryTime: String,
    reportFormat: { type: String, default: 'digital' },
    availabilityStatus: { type: String, default: 'available' },
    prescriptionRequired: { type: Boolean, default: true },
    images: { type: [String], default: [] },
    enabled: { type: Boolean, default: true },
  },
  { _id: false },
);

const scanOfferSchema = new mongoose.Schema(
  {
    id: { type: String, required: true },
    offerAvailable: { type: Boolean, default: false },
    discountType: String,
    discountValue: Number,
    offerTitle: String,
    offerDescription: String,
    validFrom: Date,
    validTill: Date,
    minimumBookingAmount: Number,
    active: { type: Boolean, default: true },
  },
  { _id: false },
);

const appointmentSlotSchema = new mongoose.Schema(
  {
    day: String,
    startTime: String,
    endTime: String,
  },
  { _id: false },
);

const scanDocumentSchema = new mongoose.Schema(
  {
    id: { type: String, required: true },
    type: String,
    label: String,
    url: String,
    verificationStatus: { type: String, default: 'pending' },
    rejectionReason: String,
  },
  { _id: false },
);

const scanCenterSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    centerName: String,
    ownerName: String,
    email: { type: String, unique: true, sparse: true },
    mobileNumber: String,
    countryCode: { type: String, default: '91' },
    passwordHash: String,
    profilePicture: String,
    address: String,
    city: String,
    state: String,
    pincode: String,
    latitude: Number,
    longitude: Number,
    gstNumber: String,
    licenseNumber: String,
    operatingHours: String,
    homeVisitAvailable: { type: Boolean, default: false },
    available24x7: { type: Boolean, default: false },
    cashPaymentEnabled: { type: Boolean, default: true },
    offeredScans: { type: [offeredScanSchema], default: [] },
    offers: { type: [scanOfferSchema], default: [] },
    appointmentSlots: { type: [appointmentSlotSchema], default: [] },
    centerImages: { type: [String], default: [] },
    documents: { type: [scanDocumentSchema], default: [] },
    averageRating: { type: Number, default: 4.5 },
    reviewCount: { type: Number, default: 0 },
    verificationStatus: { type: String, default: 'pending', index: true },
    rejectionReason: String,
    documentRequestNote: String,
    isApproved: { type: Boolean, default: false },
    approvalNotes: String,
  },
  { timestamps: true },
);

module.exports = mongoose.model('ScanCenter', scanCenterSchema);
