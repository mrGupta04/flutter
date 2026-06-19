/**
 * Normalize stored upload URLs to PUBLIC_BASE_URL so clients load files from
 * the deployed server instead of old LAN hosts (e.g. http://10.x.x.x:3000).
 */
function normalizeUploadUrl(url) {
  if (!url || typeof url !== 'string') return url;
  const trimmed = url.trim();
  if (!trimmed) return url;

  const uploadsPath = trimmed.match(/\/uploads\/[^?#]+/);
  if (!uploadsPath) return url;

  const base = String(process.env.PUBLIC_BASE_URL || '').trim().replace(/\/$/, '');
  if (!base) return url;

  return `${base}${uploadsPath[0]}`;
}

function normalizeUploadFields(obj, fields) {
  if (!obj || typeof obj !== 'object') return obj;
  const out = { ...obj };
  for (const field of fields) {
    if (out[field]) {
      out[field] = normalizeUploadUrl(out[field]);
    }
  }
  return out;
}

const DOCTOR_UPLOAD_FIELDS = [
  'profilePicture',
  'medicalLicenseUrl',
  'governmentIdUrl',
  'degreeCertificateUrl',
  'clinicProofUrl',
  'hospitalPhoto1Url',
  'hospitalPhoto2Url',
  'hospitalPhoto3Url',
  'hospitalPhoto4Url',
  'hospitalPhoto5Url',
  'cancelledChequeUrl',
  'aadhaarCardUrl',
];

module.exports = {
  normalizeUploadUrl,
  normalizeUploadFields,
  DOCTOR_UPLOAD_FIELDS,
};
