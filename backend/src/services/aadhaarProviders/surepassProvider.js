/**
 * Surepass KYC API — routes OTP to UIDAI via licensed Authentication User Agency.
 * OTP is delivered by UIDAI to the mobile number registered with the Aadhaar.
 *
 * Sign up: https://surepass.io/get-api-key/
 * Docs: https://docs.surepass.io (Aadhaar v2 generate-otp / submit-otp)
 */

async function surepassFetch(path, body) {
  const base =
    process.env.SUREPASS_API_BASE || 'https://sandbox.surepass.io/api/v1';
  const token = process.env.SUREPASS_API_TOKEN;
  const timeoutMs = Number(process.env.SUREPASS_TIMEOUT_MS || 15000);

  if (!token) {
    throw new Error(
      'SUREPASS_API_TOKEN is required for real UIDAI OTP. Get API keys at https://surepass.io/get-api-key/',
    );
  }

  const url = `${base.replace(/\/$/, '')}${path}`;
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);

  let res;
  try {
    res = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(body),
      signal: controller.signal,
    });
  } catch (err) {
    if (err?.name === 'AbortError') {
      throw new Error(
        `Surepass request timed out after ${timeoutMs}ms. Check internet/Surepass availability or use AADHAAR_PROVIDER=mock for development.`,
      );
    }
    throw err;
  } finally {
    clearTimeout(timeout);
  }

  let json = {};
  try {
    json = await res.json();
  } catch {
    json = {};
  }

  if (!res.ok) {
    const msg =
      json.message ||
      json.error ||
      json.data?.message ||
      (typeof json === 'string' ? json : null) ||
      `Surepass API error (${res.status})`;
    throw new Error(msg);
  }

  return json;
}

/** UIDAI OTP via Surepass — POST /aadhaar-v2/generate-otp */
async function sendOtp({ aadhaarNumber }) {
  const generatePath =
    process.env.SUREPASS_GENERATE_OTP_PATH || '/aadhaar-v2/generate-otp';

  const json = await surepassFetch(generatePath, {
    id_number: aadhaarNumber,
  });

  const data = json.data || json;
  const clientId = data.client_id || data.clientId;

  if (!clientId) {
    throw new Error(
      'Surepass did not return client_id. Check API path and credentials.',
    );
  }

  const otpSent =
    data.otp_sent === true ||
    data.otpSent === true ||
    data.status === 'success' ||
    json.success === true;

  if (!otpSent && data.otp_sent === false) {
    throw new Error(
      data.message || 'UIDAI could not send OTP. Check Aadhaar number.',
    );
  }

  return {
    provider: 'surepass',
    clientId,
    otpHash: null,
    expiresAt: new Date(Date.now() + 10 * 60 * 1000),
    message:
      data.message ||
      'OTP sent by UIDAI to the mobile number registered with this Aadhaar',
    uidaiOtp: true,
    maskedMobile: data.mobile_number || data.mobileNumber || null,
  };
}

/** Verify UIDAI OTP — POST /aadhaar-v2/submit-otp */
async function verifyOtp({ record, otp }) {
  if (!record.clientId) {
    throw new Error('Verification session expired. Request OTP again.');
  }

  const submitPath =
    process.env.SUREPASS_SUBMIT_OTP_PATH || '/aadhaar-v2/submit-otp';

  const json = await surepassFetch(submitPath, {
    client_id: record.clientId,
    otp: String(otp).trim(),
  });

  const data = json.data || json;
  const verified =
    data.aadhaar_number ||
    data.full_name ||
    data.gender ||
    json.success === true ||
    data.status === 'success';

  if (!verified && data.valid === false) {
    throw new Error(data.message || 'Invalid OTP');
  }

  return {
    valid: true,
    demographic: {
      fullName: data.full_name || data.fullName,
      gender: data.gender,
      dob: data.dob || data.date_of_birth,
      address: data.address || data.full_address,
    },
  };
}

module.exports = { sendOtp, verifyOtp, name: 'surepass' };
