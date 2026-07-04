const mongoose = require('mongoose');

const offeredTestSchema = new mongoose.Schema(
  {
    testId: { type: String, required: true },
    testName: String,
    categoryId: String,
    subcategoryId: String,
    priceInr: Number,
    discountedPriceInr: Number,
    reportDeliveryTime: String,
    homeCollectionAvailable: { type: Boolean, default: true },
    onsiteCollectionAvailable: { type: Boolean, default: true },
    preparationInstructions: String,
    description: String,
    sampleType: String,
    fastingRequired: { type: Boolean, default: false },
    healthRisks: { type: [String], default: [] },
    healthConditions: { type: [String], default: [] },
    bodyOrgans: { type: [String], default: [] },
    includedParameters: { type: [String], default: [] },
    imageUrl: String,
    enabled: { type: Boolean, default: true },
  },
  { _id: false },
);

const healthPackageSchema = new mongoose.Schema(
  {
    id: { type: String, required: true },
    name: String,
    bannerUrl: String,
    description: String,
    testIds: { type: [String], default: [] },
    originalPriceInr: Number,
    discountedPriceInr: Number,
    reportDeliveryTime: String,
    homeCollectionAvailable: { type: Boolean, default: true },
    isPopular: { type: Boolean, default: false },
    isRecommended: { type: Boolean, default: false },
    enabled: { type: Boolean, default: true },
  },
  { _id: false },
);

const offeredScanSchema = new mongoose.Schema(
  {
    id: { type: String, required: true },
    scanName: String,
    description: String,
    bodyPart: String,
    priceInr: Number,
    discountedPriceInr: Number,
    preparationInstructions: String,
    reportDeliveryTime: String,
    appointmentDurationMinutes: Number,
    machineDetails: String,
    enabled: { type: Boolean, default: true },
  },
  { _id: false },
);

const staffMemberSchema = new mongoose.Schema(
  {
    id: { type: String, required: true },
    role: String,
    name: String,
    mobile: String,
    email: String,
    qualification: String,
    experienceYears: Number,
    profilePicture: String,
    workingShift: String,
  },
  { _id: false },
);

const bankDetailsSchema = new mongoose.Schema(
  {
    accountHolderName: String,
    bankName: String,
    accountNumber: String,
    ifscCode: String,
    upiId: String,
    cancelledChequeUrl: String,
  },
  { _id: false },
);

const workingDaySchema = new mongoose.Schema(
  {
    day: String,
    isOpen: { type: Boolean, default: true },
    openingTime: String,
    closingTime: String,
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
    coverImage: String,
    labType: String,
    yearEstablished: Number,
    registrationNumber: String,
    nablAccreditationNumber: String,
    otherCertifications: String,
    address: String,
    buildingName: String,
    street: String,
    area: String,
    landmark: String,
    city: String,
    state: String,
    pincode: String,
    latitude: Number,
    longitude: Number,
    gstNumber: String,
    licenseNumber: String,
    accreditation: String,
    openingTime: String,
    closingTime: String,
    workingDays: { type: [workingDaySchema], default: [] },
    operatingHours: String,
    emergencyServiceAvailable: { type: Boolean, default: false },
    homeCollectionAvailable: { type: Boolean, default: false },
    available24x7: { type: Boolean, default: false },
    facilities: { type: [String], default: [] },
    supportedCategories: { type: [String], default: [] },
    offeredTests: { type: [offeredTestSchema], default: [] },
    healthPackages: { type: [healthPackageSchema], default: [] },
    offeredScans: { type: [offeredScanSchema], default: [] },
    staffMembers: { type: [staffMemberSchema], default: [] },
    bankDetails: bankDetailsSchema,
    serviceCities: { type: [String], default: [] },
    serviceAreas: { type: [String], default: [] },
    homeCollectionRadiusKm: Number,
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
