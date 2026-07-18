const { v4: uuidv4 } = require('uuid');
const Patient = require('./models/Patient');
const { hashPassword, verifyPassword } = require('../utils/providerAuth');

const ALLOWED_GENDERS = ['Male', 'Female', 'Other'];

function normalizeEmail(email) {
  return String(email || '').trim().toLowerCase();
}

const { normalizeMobile, validateMobile } = require('../utils/mobile');

function normalizeAadhaar(value) {
  return String(value || '').replace(/\D/g, '').slice(0, 12);
}

function toPatient(doc) {
  if (!doc) return null;
  const d = doc.toObject ? doc.toObject() : doc;
  return {
    id: d.id,
    firstName: d.firstName,
    lastName: d.lastName,
    email: d.email,
    mobileNumber: d.mobileNumber,
    countryCode: d.countryCode || '91',
    age: d.age,
    gender: d.gender,
    aadhaarLast4: d.aadhaarLast4,
    profilePicture: d.profilePicture,
    aadhaarCardUrl: d.aadhaarCardUrl,
    referralCode: d.referralCode || null,
    rewardPoints: d.rewardPoints || 0,
    referredByCode: d.referredByCode || null,
    familyMembers: Array.isArray(d.familyMembers) ? d.familyMembers : [],
    savedAddresses: Array.isArray(d.savedAddresses) ? d.savedAddresses : [],
    medicalProfile: d.medicalProfile || {
      bloodGroup: null,
      allergies: [],
      chronicDiseases: [],
      currentMedications: [],
      notes: null,
    },
    createdAt: d.createdAt,
    updatedAt: d.updatedAt,
  };
}

async function findPatientByEmail(email, excludeId = '') {
  const query = { email: normalizeEmail(email) };
  if (excludeId) query.id = { $ne: excludeId };
  const doc = await Patient.findOne(query);
  return toPatient(doc);
}

async function findPatientById(id) {
  const doc = await Patient.findOne({ id });
  return toPatient(doc);
}

function validateRegistrationInput(data) {
  const firstName = String(data.firstName || '').trim();
  const email = normalizeEmail(data.email);
  const mobileCheck = validateMobile(data.mobileNumber, {
    countryCode: data.countryCode,
  });
  if (!mobileCheck.valid) {
    const err = new Error(mobileCheck.error);
    err.statusCode = 400;
    throw err;
  }
  const mobile = mobileCheck.mobile;
  const mobileCountryCode = mobileCheck.countryCode;
  const password = String(data.password || '');
  const gender = String(data.gender || '').trim();
  const aadhaar = normalizeAadhaar(data.aadhaarNumber);
  const age = parseInt(data.age, 10);
  const profilePicture = String(data.profilePicture || '').trim();
  const aadhaarCardUrl = String(data.aadhaarCardUrl || '').trim();

  if (!firstName || firstName.length < 2) {
    const err = new Error('Name is required (at least 2 characters)');
    err.statusCode = 400;
    throw err;
  }
  if (!email) {
    const err = new Error('Email is required');
    err.statusCode = 400;
    throw err;
  }
  if (password.length < 8) {
    const err = new Error('Password must be at least 8 characters');
    err.statusCode = 400;
    throw err;
  }
  if (!Number.isFinite(age) || age < 1 || age > 120) {
    const err = new Error('A valid age between 1 and 120 is required');
    err.statusCode = 400;
    throw err;
  }
  if (!ALLOWED_GENDERS.includes(gender)) {
    const err = new Error('Gender is required (Male, Female, or Other)');
    err.statusCode = 400;
    throw err;
  }
  if (aadhaar.length !== 12) {
    const err = new Error('A valid 12-digit Aadhaar number is required');
    err.statusCode = 400;
    throw err;
  }
  if (/^(\d)\1{11}$/.test(aadhaar)) {
    const err = new Error('Enter a valid Aadhaar number');
    err.statusCode = 400;
    throw err;
  }
  if (!profilePicture) {
    const err = new Error('Profile picture is required');
    err.statusCode = 400;
    throw err;
  }
  if (!aadhaarCardUrl) {
    const err = new Error('Aadhaar card image is required');
    err.statusCode = 400;
    throw err;
  }

  return {
    firstName,
    lastName: data.lastName ? String(data.lastName).trim() : '',
    email,
    mobile,
    countryCode: mobileCountryCode,
    password,
    gender,
    aadhaar,
    age,
    profilePicture,
    aadhaarCardUrl,
  };
}

async function registerPatient(data) {
  const validated = validateRegistrationInput(data);

  const existingEmail = await findPatientByEmail(validated.email);
  if (existingEmail) {
    const err = new Error('Email is already registered');
    err.statusCode = 409;
    throw err;
  }

  const existingMobile = await Patient.findOne({
    mobileNumber: validated.mobile,
    countryCode: validated.countryCode,
  });
  if (existingMobile) {
    const err = new Error('Mobile number is already registered');
    err.statusCode = 409;
    throw err;
  }

  const existingAadhaar = await Patient.findOne({
    aadhaarNumber: validated.aadhaar,
  });
  if (existingAadhaar) {
    const err = new Error('Aadhaar number is already registered');
    err.statusCode = 409;
    throw err;
  }

  const id = uuidv4();
  const {
    buildReferralCodeFromId,
    applyReferralOnRegister,
  } = require('./rewardRepositories');
  const referralCode = buildReferralCodeFromId(id);

  await Patient.create({
    id,
    firstName: validated.firstName,
    lastName: validated.lastName,
    email: validated.email,
    mobileNumber: validated.mobile,
    countryCode: validated.countryCode,
    passwordHash: hashPassword(validated.password),
    age: validated.age,
    gender: validated.gender,
    aadhaarNumber: validated.aadhaar,
    aadhaarLast4: validated.aadhaar.slice(-4),
    profilePicture: validated.profilePicture,
    aadhaarCardUrl: validated.aadhaarCardUrl,
    referralCode,
    rewardPoints: 0,
  });

  const incomingReferral = data.referralCode
    ? String(data.referralCode).trim()
    : '';
  if (incomingReferral) {
    try {
      await applyReferralOnRegister(id, incomingReferral);
    } catch (err) {
      if (err.statusCode === 400) {
        throw err;
      }
      console.error('[patient] referral apply failed:', err.message);
    }
  }

  return findPatientById(id);
}

async function updatePatient(patientId, data) {
  const doc = await Patient.findOne({ id: patientId });
  if (!doc) {
    const err = new Error('Patient not found');
    err.statusCode = 404;
    throw err;
  }

  const updates = {};

  if (data.firstName != null) {
    const firstName = String(data.firstName).trim();
    if (firstName.length < 2) {
      const err = new Error('Name must be at least 2 characters');
      err.statusCode = 400;
      throw err;
    }
    updates.firstName = firstName;
  }

  if (data.lastName != null) {
    updates.lastName = String(data.lastName).trim();
  }

  if (data.email != null) {
    const email = normalizeEmail(data.email);
    if (!email) {
      const err = new Error('Email is required');
      err.statusCode = 400;
      throw err;
    }
    const existingEmail = await findPatientByEmail(email, patientId);
    if (existingEmail) {
      const err = new Error('Email is already registered');
      err.statusCode = 409;
      throw err;
    }
    updates.email = email;
  }

  if (data.mobileNumber != null) {
    const mobileCheck = validateMobile(data.mobileNumber, {
      countryCode: data.countryCode,
    });
    if (!mobileCheck.valid) {
      const err = new Error(mobileCheck.error);
      err.statusCode = 400;
      throw err;
    }
    const mobile = mobileCheck.mobile;
    const existingMobile = await Patient.findOne({
      mobileNumber: mobile,
      id: { $ne: patientId },
    });
    if (existingMobile) {
      const err = new Error('Mobile number is already registered');
      err.statusCode = 409;
      throw err;
    }
    updates.mobileNumber = mobile;
    updates.countryCode = mobileCheck.countryCode;
  }

  if (data.age != null) {
    const age = parseInt(data.age, 10);
    if (!Number.isFinite(age) || age < 1 || age > 120) {
      const err = new Error('A valid age between 1 and 120 is required');
      err.statusCode = 400;
      throw err;
    }
    updates.age = age;
  }

  if (data.gender != null) {
    const gender = String(data.gender).trim();
    if (!ALLOWED_GENDERS.includes(gender)) {
      const err = new Error('Gender must be Male, Female, or Other');
      err.statusCode = 400;
      throw err;
    }
    updates.gender = gender;
  }

  if (data.aadhaarNumber != null) {
    const aadhaar = normalizeAadhaar(data.aadhaarNumber);
    if (aadhaar.length !== 12) {
      const err = new Error('A valid 12-digit Aadhaar number is required');
      err.statusCode = 400;
      throw err;
    }
    const existingAadhaar = await Patient.findOne({
      aadhaarNumber: aadhaar,
      id: { $ne: patientId },
    });
    if (existingAadhaar) {
      const err = new Error('Aadhaar number is already registered');
      err.statusCode = 409;
      throw err;
    }
    updates.aadhaarNumber = aadhaar;
    updates.aadhaarLast4 = aadhaar.slice(-4);
  }

  if (data.profilePicture) {
    updates.profilePicture = String(data.profilePicture).trim();
  }

  if (data.aadhaarCardUrl) {
    updates.aadhaarCardUrl = String(data.aadhaarCardUrl).trim();
  }

  if (data.password) {
    const password = String(data.password);
    if (password.length < 8) {
      const err = new Error('Password must be at least 8 characters');
      err.statusCode = 400;
      throw err;
    }
    updates.passwordHash = hashPassword(password);
  }

  if (data.medicalProfile != null && typeof data.medicalProfile === 'object') {
    const mp = data.medicalProfile;
    updates.medicalProfile = {
      bloodGroup: mp.bloodGroup != null ? String(mp.bloodGroup).trim() : doc.medicalProfile?.bloodGroup,
      allergies: Array.isArray(mp.allergies)
        ? mp.allergies.map((a) => String(a).trim()).filter(Boolean)
        : doc.medicalProfile?.allergies || [],
      chronicDiseases: Array.isArray(mp.chronicDiseases)
        ? mp.chronicDiseases.map((a) => String(a).trim()).filter(Boolean)
        : doc.medicalProfile?.chronicDiseases || [],
      currentMedications: Array.isArray(mp.currentMedications)
        ? mp.currentMedications.map((a) => String(a).trim()).filter(Boolean)
        : doc.medicalProfile?.currentMedications || [],
      notes: mp.notes != null ? String(mp.notes).trim() : doc.medicalProfile?.notes,
      insuranceProvider:
        mp.insuranceProvider != null
          ? String(mp.insuranceProvider).trim()
          : doc.medicalProfile?.insuranceProvider,
      insurancePolicyNumber:
        mp.insurancePolicyNumber != null
          ? String(mp.insurancePolicyNumber).trim()
          : doc.medicalProfile?.insurancePolicyNumber,
      insuranceMemberId:
        mp.insuranceMemberId != null
          ? String(mp.insuranceMemberId).trim()
          : doc.medicalProfile?.insuranceMemberId,
      insuranceValidUntil:
        mp.insuranceValidUntil != null
          ? String(mp.insuranceValidUntil).trim()
          : doc.medicalProfile?.insuranceValidUntil,
    };
  }

  if (Object.keys(updates).length === 0) {
    return findPatientById(patientId);
  }

  await Patient.updateOne({ id: patientId }, { $set: updates });
  return findPatientById(patientId);
}

async function upsertFamilyMember(patientId, member) {
  const doc = await Patient.findOne({ id: patientId });
  if (!doc) {
    const err = new Error('Patient not found');
    err.statusCode = 404;
    throw err;
  }
  const name = String(member.name || '').trim();
  if (name.length < 2) {
    const err = new Error('Family member name is required');
    err.statusCode = 400;
    throw err;
  }
  const members = Array.isArray(doc.familyMembers) ? [...doc.familyMembers] : [];
  const id = member.id || uuidv4();
  const payload = {
    id,
    name,
    relationship: member.relationship || 'other',
    age: member.age != null ? Number(member.age) : undefined,
    gender: member.gender ? String(member.gender).trim() : undefined,
    mobileNumber: member.mobileNumber
      ? String(member.mobileNumber).trim()
      : undefined,
    bloodGroup: member.bloodGroup ? String(member.bloodGroup).trim() : undefined,
  };
  const idx = members.findIndex((m) => m.id === id);
  if (idx >= 0) members[idx] = payload;
  else members.push(payload);
  doc.familyMembers = members;
  await doc.save();
  return toPatient(doc);
}

async function deleteFamilyMember(patientId, memberId) {
  const doc = await Patient.findOne({ id: patientId });
  if (!doc) {
    const err = new Error('Patient not found');
    err.statusCode = 404;
    throw err;
  }
  doc.familyMembers = (doc.familyMembers || []).filter((m) => m.id !== memberId);
  await doc.save();
  return toPatient(doc);
}

async function upsertSavedAddress(patientId, address) {
  const doc = await Patient.findOne({ id: patientId });
  if (!doc) {
    const err = new Error('Patient not found');
    err.statusCode = 404;
    throw err;
  }
  const addressLine = String(address.addressLine || '').trim();
  if (addressLine.length < 5) {
    const err = new Error('Address is required');
    err.statusCode = 400;
    throw err;
  }
  let addresses = Array.isArray(doc.savedAddresses) ? [...doc.savedAddresses] : [];
  const id = address.id || uuidv4();
  const isDefault = Boolean(address.isDefault);
  if (isDefault) {
    addresses = addresses.map((a) => ({
      ...((a.toObject && a.toObject()) || a),
      isDefault: false,
    }));
  }
  const payload = {
    id,
    label: String(address.label || 'Home').trim(),
    addressLine,
    city: address.city ? String(address.city).trim() : undefined,
    state: address.state ? String(address.state).trim() : undefined,
    pincode: address.pincode ? String(address.pincode).trim() : undefined,
    latitude: address.latitude != null ? Number(address.latitude) : undefined,
    longitude: address.longitude != null ? Number(address.longitude) : undefined,
    isDefault: isDefault || addresses.length === 0,
  };
  const idx = addresses.findIndex((a) => a.id === id);
  if (idx >= 0) addresses[idx] = payload;
  else addresses.push(payload);
  doc.savedAddresses = addresses;
  await doc.save();
  return toPatient(doc);
}

async function deleteSavedAddress(patientId, addressId) {
  const doc = await Patient.findOne({ id: patientId });
  if (!doc) {
    const err = new Error('Patient not found');
    err.statusCode = 404;
    throw err;
  }
  doc.savedAddresses = (doc.savedAddresses || []).filter((a) => a.id !== addressId);
  if (doc.savedAddresses.length && !doc.savedAddresses.some((a) => a.isDefault)) {
    doc.savedAddresses[0].isDefault = true;
  }
  await doc.save();
  return toPatient(doc);
}

async function listPatientsForAdmin({ page = 1, pageSize = 20, search = '' } = {}) {
  const filter = {};
  if (search) {
    const q = String(search).trim();
    filter.$or = [
      { firstName: new RegExp(q, 'i') },
      { lastName: new RegExp(q, 'i') },
      { email: new RegExp(q, 'i') },
      { mobileNumber: new RegExp(q.replace(/\D/g, ''), 'i') },
    ];
  }
  const totalCount = await Patient.countDocuments(filter);
  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));
  const docs = await Patient.find(filter)
    .sort({ createdAt: -1 })
    .skip((page - 1) * pageSize)
    .limit(pageSize);
  return {
    patients: docs.map(toPatient),
    pagination: {
      currentPage: page,
      totalPages,
      pageSize,
      totalCount,
      hasNextPage: page < totalPages,
    },
  };
}

async function loginPatient(email, password) {
  const normalized = normalizeEmail(email);
  if (!normalized || !password) {
    const err = new Error('Email and password are required');
    err.statusCode = 400;
    throw err;
  }

  const doc = await Patient.findOne({ email: normalized });
  if (!doc || !verifyPassword(password, doc.passwordHash)) {
    const err = new Error('Invalid email or password');
    err.statusCode = 401;
    throw err;
  }

  return toPatient(doc);
}

module.exports = {
  registerPatient,
  loginPatient,
  updatePatient,
  findPatientById,
  findPatientByEmail,
  toPatient,
  upsertFamilyMember,
  deleteFamilyMember,
  upsertSavedAddress,
  deleteSavedAddress,
  listPatientsForAdmin,
};
