require('dotenv').config({ path: require('path').join(__dirname, '../../.env') });

const bcrypt = require('bcryptjs');

const { connectDB } = require('./connect');

const Doctor = require('./models/Doctor');

const Document = require('./models/Document');

const DoctorAvailability = require('./models/DoctorAvailability');

const { getActiveWeekBounds, buildAllSlots } = require('../utils/availabilityWeek');



const statuses = ['pending', 'under_review', 'verified', 'rejected'];



async function seed() {

  const count = await Doctor.countDocuments();

  if (count > 0) {

    console.log(`Database already has ${count} doctors. Skipping seed.`);

    return;

  }



  const passwordHash = bcrypt.hashSync('Doctor@123', 10);



  for (let i = 0; i < 4; i++) {

    const id = `doc_seed_${i}`;

    await Doctor.create({

      id,

      firstName: 'Dr. Alex',

      lastName: `Verma ${i}`,

      email: `doctor${i}@example.com`,

      mobileNumber: `98765432${String(i).padStart(2, '0')}`,

      passwordHash,

      profilePicture:

        'https://images.unsplash.com/photo-1612349317228-cc624a92fc4d?w=400&h=400&fit=crop',

      medicalRegistrationNumber: `MR/2024/00${i}`,

      medicalCouncilName: 'Medical Council of India',

      specializations: ['Cardiology'],

      yearsOfExperience: 3 + i,

      clinicName: `Health Clinic ${i}`,

      address: `${12 + i} Medical Lane, Connaught Place`,

      city: 'Delhi',

      state: 'Delhi',

      pincode: `11000${i + 1}`,

      consultationFee: 300 + i * 100,
      onlineConsultFee: 250 + i * 80,
      homeVisitFee: 400 + i * 100,
      visitSiteFee: 300 + i * 100,

      offersOnlineConsult: i % 3 !== 1,

      offersBookHome: i % 3 !== 2,

      offersVisitSite: i % 3 !== 0,

      qualification: 'MBBS',

      verificationStatus: statuses[i],

      isApproved: statuses[i] === 'verified',

    });



    const docTypes = ['medical_license', 'government_id', 'degree_certificate'];

    for (let idx = 0; idx < docTypes.length; idx++) {

      const type = docTypes[idx];

      await Document.create({

        id: `seed_doc_${i}_${idx}`,

        doctorId: id,

        documentType: type,

        fileUrl: `https://example.com/${id}/${type}.pdf`,

        fileName: `${type}.pdf`,

        fileSize: 512000,

        mimeType: 'application/pdf',

        status: idx === 0 ? 'verified' : 'pending',

      });

    }

    if (statuses[i] === 'verified') {
      const { weekStart, weekEnd } = getActiveWeekBounds();
      const slots = buildAllSlots(false).map((slot) => ({
        ...slot,
        available:
          slot.dayOfWeek >= 1 &&
          slot.dayOfWeek <= 5 &&
          slot.startHour >= 9 &&
          slot.startHour <= 16,
      }));

      const onlineSlots = slots.map((slot) => ({
        ...slot,
        available:
          slot.dayOfWeek >= 1 &&
          slot.dayOfWeek <= 5 &&
          slot.startHour >= 9 &&
          slot.startHour <= 15,
      }));
      const clinicSlots = slots.map((slot) => ({
        ...slot,
        available:
          (slot.dayOfWeek === 0 || slot.dayOfWeek === 6) &&
          slot.startHour >= 9 &&
          slot.startHour <= 16,
      }));

      await DoctorAvailability.create({
        doctorId: id,
        consultationType: 'online_consult',
        weekStartDate: weekStart,
        weekEndDate: weekEnd,
        slots: onlineSlots,
      });
      await DoctorAvailability.create({
        doctorId: id,
        consultationType: 'visit_site',
        weekStartDate: weekStart,
        weekEndDate: weekEnd,
        slots: clinicSlots,
      });
    }

  }



  console.log('Seeded 4 sample doctors with documents and weekly availability.');

}



async function run() {

  await connectDB();

  await seed();

  process.exit(0);

}



if (require.main === module) {

  run().catch((err) => {

    console.error(err);

    process.exit(1);

  });

}



module.exports = { seed };

