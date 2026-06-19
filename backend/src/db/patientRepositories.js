const { v4: uuidv4 } = require('uuid');
const Patient = require('./models/Patient');
const { hashPassword, verifyPassword } = require('../utils/providerAuth');

const ALLOWED_GENDERS = ['Male', 'Female', 'Other'];

function normalizeEmail(email) {
  return String(email || '').trim().toLowerCase();
}

function normalizeMobile(mobile) {
  return String(mobile || '').replace(/\D/g, '').slice(-10);
}

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
    age: d.age,
    gender: d.gender,
    aadhaarLast4: d.aadhaarLast4,
    profilePicture: d.profilePicture,
    aadhaarCardUrl: d.aadhaarCardUrl,
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
  const mobile = normalizeMobile(data.mobileNumber);
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
  if (mobile.length !== 10) {
    const err = new Error('A valid 10-digit mobile number is required');
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
  await Patient.create({
    id,
    firstName: validated.firstName,
    lastName: validated.lastName,
    email: validated.email,
    mobileNumber: validated.mobile,
    passwordHash: hashPassword(validated.password),
    age: validated.age,
    gender: validated.gender,
    aadhaarNumber: validated.aadhaar,
    aadhaarLast4: validated.aadhaar.slice(-4),
    profilePicture: validated.profilePicture,
    aadhaarCardUrl: validated.aadhaarCardUrl,
  });

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
    const mobile = normalizeMobile(data.mobileNumber);
    if (mobile.length !== 10) {
      const err = new Error('A valid 10-digit mobile number is required');
      err.statusCode = 400;
      throw err;
    }
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

  if (Object.keys(updates).length === 0) {
    return findPatientById(patientId);
  }

  await Patient.updateOne({ id: patientId }, { $set: updates });
  return findPatientById(patientId);
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
};
