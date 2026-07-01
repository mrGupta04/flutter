const mongoose = require('mongoose');

const bloodComponentSchema = new mongoose.Schema(
  {
    componentId: { type: String, required: true },
    componentName: String,
    priceInr: Number,
    governmentPriceInr: Number,
    discountPriceInr: Number,
    availabilityStatus: { type: String, default: 'available' },
    enabled: { type: Boolean, default: true },
  },
  { _id: false },
);

const bloodOfferSchema = new mongoose.Schema(
  {
    id: { type: String, required: true },
    offerAvailable: { type: Boolean, default: false },
    discountType: String,
    discountValue: Number,
    offerTitle: String,
    offerDescription: String,
    validFrom: Date,
    validTill: Date,
    applicableBloodTypes: { type: [String], default: [] },
    minimumOrderAmount: Number,
    active: { type: Boolean, default: true },
  },
  { _id: false },
);

const bloodDocumentSchema = new mongoose.Schema(
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

const workingDaySchema = new mongoose.Schema(
  {
    day: String,
    open: { type: Boolean, default: true },
  },
  { _id: false },
);

const bloodBankSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    institutionName: String,
    ownerName: String,
    licenseNumber: String,
    governmentRegistrationNumber: String,
    gstNumber: String,
    contactPerson: String,
    email: { type: String, unique: true, sparse: true },
    mobileNumber: String,
    countryCode: { type: String, default: '91' },
    passwordHash: String,
    profilePicture: String,
    logoUrl: String,
    description: String,
    emergencyContact: String,
    whatsappNumber: String,
    landlineNumber: String,
    emailSupport: String,
    address: String,
    city: String,
    state: String,
    pincode: String,
    latitude: Number,
    longitude: Number,
    openingTime: String,
    closingTime: String,
    workingDays: { type: [workingDaySchema], default: [] },
    available24x7: { type: Boolean, default: false },
    emergencyBloodSupply: { type: Boolean, default: false },
    facilities: { type: [String], default: [] },
    bloodGroupsAvailable: [String],
    hasApheresis: { type: Boolean, default: false },
    hasComponentSeparation: { type: Boolean, default: false },
    homeDeliveryAvailable: { type: Boolean, default: false },
    hospitalDeliveryAvailable: { type: Boolean, default: false },
    cashPaymentEnabled: { type: Boolean, default: true },
    bloodComponents: { type: [bloodComponentSchema], default: [] },
    offers: { type: [bloodOfferSchema], default: [] },
    galleryImages: { type: [String], default: [] },
    documents: { type: [bloodDocumentSchema], default: [] },
    averageRating: { type: Number, default: 4.5 },
    reviewCount: { type: Number, default: 0 },
    verificationStatus: { type: String, default: 'pending', index: true },
    rejectionReason: String,
    documentRequestNote: String,
    isApproved: { type: Boolean, default: false },
    approvalNotes: String,
    isSuspended: { type: Boolean, default: false },
    suspensionReason: String,
  },
  { timestamps: true },
);

module.exports = mongoose.model('BloodBank', bloodBankSchema);
