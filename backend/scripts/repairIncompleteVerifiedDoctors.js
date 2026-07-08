/**
 * Moves verified doctors with incomplete profiles back to under_review.
 * Run from backend/: node scripts/repairIncompleteVerifiedDoctors.js
 */
require('dotenv').config();
const { connectDB } = require('../src/db/connect');
const Doctor = require('../src/db/models/Doctor');
const { toDoctor } = require('../src/db/mappers');
const {
  getDoctorProfileMissingFields,
  isDoctorProfilePublicDisplayable,
} = require('../src/utils/doctorProfileCompleteness');

async function main() {
  await connectDB();

  const docs = await Doctor.find({ verificationStatus: 'verified' });
  let repaired = 0;

  for (const doc of docs) {
    const doctor = toDoctor(doc);
    if (isDoctorProfilePublicDisplayable(doctor)) continue;

    const missing = getDoctorProfileMissingFields(doctor);
    await Doctor.updateOne(
      { id: doctor.id },
      {
        $set: {
          verificationStatus: 'under_review',
          isApproved: false,
          approvalNotes: null,
          rejectionReason:
            'Profile incomplete. Doctor must complete registration before publishing.',
        },
      },
    );

    repaired += 1;
    console.log(`Moved ${doctor.id} back to under_review. Missing: ${missing.join(', ')}`);
  }

  console.log(`Done. Repaired ${repaired} doctor(s).`);
  process.exit(0);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
