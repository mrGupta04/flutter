const ConsultationBooking = require('../db/models/ConsultationBooking');
const Patient = require('../db/models/Patient');
const Doctor = require('../db/models/Doctor');
const Nurse = require('../db/models/Nurse');
const { sendSms } = require('./smsService');
const { sendWhatsApp } = require('./whatsappService');
const { createAndPushNotification } = require('../db/notificationRepositories');
const { formatSlotLabel } = require('../utils/slotDateTime');

const POLL_MS = Number(process.env.REMINDER_POLL_MS || 60_000);
const WINDOW_MIN = Number(process.env.REMINDER_WINDOW_MINUTES || 60);
const WINDOW_SLACK_MIN = Number(process.env.REMINDER_SLACK_MINUTES || 5);

let timer = null;

async function processDueReminders() {
  const now = Date.now();
  const windowStart = new Date(now + (WINDOW_MIN - WINDOW_SLACK_MIN) * 60 * 1000);
  const windowEnd = new Date(now + (WINDOW_MIN + WINDOW_SLACK_MIN) * 60 * 1000);

  const bookings = await ConsultationBooking.find({
    status: 'confirmed',
    reminderSentAt: null,
    slotStart: { $gte: windowStart, $lte: windowEnd },
  }).limit(50);

  for (const booking of bookings) {
    try {
      const slotLabel = formatSlotLabel(booking.slotStart, booking.slotEnd);
      const patient = booking.patientId
        ? await Patient.findOne({ id: booking.patientId }).lean()
        : null;

      let providerName = 'your provider';
      if (booking.doctorId) {
        const d = await Doctor.findOne({ id: booking.doctorId }).lean();
        providerName = `${d?.firstName || ''} ${d?.lastName || ''}`.trim() || 'your doctor';
      } else if (booking.nurseId) {
        const n = await Nurse.findOne({ id: booking.nurseId }).lean();
        providerName = `${n?.firstName || ''} ${n?.lastName || ''}`.trim() || 'your nurse';
      }

      const message = `Reminder: your visit with ${providerName} is in about 1 hour (${slotLabel}).`;

      const mobile = booking.patientMobile || patient?.mobileNumber;
      if (mobile) {
        await sendSms(mobile, message);
        await sendWhatsApp(mobile, message);
      }

      if (booking.patientId) {
        await createAndPushNotification({
          userId: booking.patientId,
          userType: 'patient',
          title: 'Visit reminder',
          body: message,
          type: 'visit_reminder',
          data: { bookingId: booking.id },
        });
      }

      // Remind provider too
      if (booking.doctorId) {
        await createAndPushNotification({
          userId: booking.doctorId,
          userType: 'doctor',
          title: 'Upcoming visit',
          body: `${booking.patientName} in about 1 hour (${slotLabel}).`,
          type: 'visit_reminder',
          data: { bookingId: booking.id },
        });
      } else if (booking.nurseId) {
        await createAndPushNotification({
          userId: booking.nurseId,
          userType: 'nurse',
          title: 'Upcoming visit',
          body: `${booking.patientName} in about 1 hour (${slotLabel}).`,
          type: 'visit_reminder',
          data: { bookingId: booking.id },
        });
      }

      booking.reminderSentAt = new Date();
      await booking.save();
    } catch (err) {
      console.error('[Reminder] failed for', booking.id, err.message);
    }
  }
}

function startVisitReminderScheduler() {
  if (timer) return;
  console.log(
    `[Reminder] scheduler started (window ~${WINDOW_MIN} min, poll ${POLL_MS}ms)`,
  );
  timer = setInterval(() => {
    void processDueReminders();
  }, POLL_MS);
  void processDueReminders();
}

module.exports = {
  startVisitReminderScheduler,
  processDueReminders,
};
