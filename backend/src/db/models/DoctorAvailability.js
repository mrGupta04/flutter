const mongoose = require('mongoose');

const slotSchema = new mongoose.Schema(
  {
    dayOfWeek: { type: Number, required: true, min: 0, max: 6 },
    startHour: { type: Number, required: true, min: 8, max: 17 },
    available: { type: Boolean, default: false },
  },
  { _id: false },
);

const doctorAvailabilitySchema = new mongoose.Schema(
  {
    doctorId: { type: String, required: true, index: true },
    consultationType: {
      type: String,
      enum: ['online_consult', 'visit_site'],
      default: 'online_consult',
    },
    weekStartDate: { type: Date, required: true, index: true },
    weekEndDate: { type: Date, required: true },
    slots: { type: [slotSchema], default: [] },
  },
  { timestamps: true },
);

doctorAvailabilitySchema.index(
  { doctorId: 1, weekStartDate: 1, consultationType: 1 },
  { unique: true },
);

module.exports = mongoose.model('DoctorAvailability', doctorAvailabilitySchema);
