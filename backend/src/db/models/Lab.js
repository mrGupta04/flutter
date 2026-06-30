const mongoose = require('mongoose');

const offeredTestSchema = new mongoose.Schema(
  {
    testId: { type: String, required: true },
    testName: String,
    categoryId: String,
    priceInr: Number,
    discountedPriceInr: Number,
    reportDeliveryTime: String,
    homeCollectionAvailable: { type: Boolean, default: true },
    onsiteCollectionAvailable: { type: Boolean, default: true },
    preparationInstructions: String,
    description: String,
    enabled: { type: Boolean, default: true },
  },
  { _id: false },
);

const branchSchema = new mongoose.Schema(
  {
    id: { type: String, required: true },
    name: String,
    address: String,
    city: String,
    state: String,
    pincode: String,
    latitude: Number,
    longitude: Number,
  },
  { _id: false },
);

const homeVisitSlotSchema = new mongoose.Schema(
  {
    day: String,
    startTime: String,
    endTime: String,
  },
  { _id: false },
);

const labDocumentSchema = new mongoose.Schema(
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

const labSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    labName: String,
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
    accreditation: String,
    operatingHours: String,
    homeCollectionAvailable: { type: Boolean, default: false },
    available24x7: { type: Boolean, default: false },
    offeredTests: { type: [offeredTestSchema], default: [] },
    branches: { type: [branchSchema], default: [] },
    serviceablePincodes: { type: [String], default: [] },
    homeVisitSlots: { type: [homeVisitSlotSchema], default: [] },
    labImages: { type: [String], default: [] },
    documents: { type: [labDocumentSchema], default: [] },
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

module.exports = mongoose.model('Lab', labSchema);
