const mongoose = require('mongoose');

const familyMemberSchema = new mongoose.Schema(
  {
    id: { type: String, required: true },
    name: { type: String, required: true },
    relationship: {
      type: String,
      enum: [
        'self',
        'spouse',
        'child',
        'parent',
        'sibling',
        'grandparent',
        'other',
      ],
      default: 'other',
    },
    age: Number,
    gender: String,
    mobileNumber: String,
    bloodGroup: String,
  },
  { _id: false },
);

const savedAddressSchema = new mongoose.Schema(
  {
    id: { type: String, required: true },
    label: { type: String, default: 'Home' },
    addressLine: { type: String, required: true },
    city: String,
    state: String,
    pincode: String,
    latitude: Number,
    longitude: Number,
    isDefault: { type: Boolean, default: false },
  },
  { _id: false },
);

const medicalProfileSchema = new mongoose.Schema(
  {
    bloodGroup: String,
    allergies: { type: [String], default: [] },
    chronicDiseases: { type: [String], default: [] },
    currentMedications: { type: [String], default: [] },
    notes: String,
    insuranceProvider: String,
    insurancePolicyNumber: String,
    insuranceMemberId: String,
    insuranceValidUntil: String,
  },
  { _id: false },
);

const patientSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    firstName: { type: String, required: true },
    lastName: String,
    email: { type: String, required: true, unique: true, index: true },
    mobileNumber: { type: String, required: true, index: true },
    countryCode: { type: String, default: '91' },
    passwordHash: { type: String, required: true },
    age: { type: Number, required: true, min: 1, max: 120 },
    gender: { type: String, required: true },
    aadhaarNumber: { type: String, required: true, unique: true, index: true },
    aadhaarLast4: { type: String, required: true },
    profilePicture: { type: String, required: true },
    aadhaarCardUrl: { type: String, required: true },
    fcmTokens: { type: [String], default: [] },
    referralCode: { type: String, unique: true, sparse: true, index: true },
    rewardPoints: { type: Number, default: 0, min: 0 },
    referredByCode: String,
    familyMembers: { type: [familyMemberSchema], default: [] },
    savedAddresses: { type: [savedAddressSchema], default: [] },
    medicalProfile: {
      type: medicalProfileSchema,
      default: () => ({
        allergies: [],
        chronicDiseases: [],
        currentMedications: [],
      }),
    },
  },
  { timestamps: true },
);

module.exports = mongoose.model('Patient', patientSchema);
