const mongoose = require('mongoose');

const slotSchema = new mongoose.Schema(
  {
    dayOfWeek: { type: Number, required: true, min: 0, max: 6 },
    startHour: { type: Number, required: true, min: 8, max: 17 },
    available: { type: Boolean, default: false },
  },
  { _id: false },
);

const nurseAvailabilitySchema = new mongoose.Schema(
  {
    nurseId: { type: String, required: true, index: true },
    consultationType: {
      type: String,
      enum: ['book_home'],
      default: 'book_home',
    },
    weekStartDate: { type: Date, required: true, index: true },
    weekEndDate: { type: Date, required: true },
    slots: { type: [slotSchema], default: [] },
  },
  { timestamps: true },
);

nurseAvailabilitySchema.index(
  { nurseId: 1, weekStartDate: 1, consultationType: 1 },
  { unique: true },
);

module.exports = mongoose.model('NurseAvailability', nurseAvailabilitySchema);
