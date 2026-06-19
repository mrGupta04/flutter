const mockProvider = require('./mockProvider');
const surepassProvider = require('./surepassProvider');

function resolveProviderName() {
  const configured = (process.env.AADHAAR_PROVIDER || '').toLowerCase().trim();
  if (configured === 'mock') return 'mock';
  if (configured === 'surepass') return 'surepass';
  if (process.env.SUREPASS_API_TOKEN) return 'surepass';
  return 'mock';
}

function getProvider() {
  const name = resolveProviderName();

  if (name === 'surepass') {
    return surepassProvider;
  }

  if (
    process.env.NODE_ENV === 'production' &&
    process.env.AADHAAR_ALLOW_MOCK !== 'true'
  ) {
    throw new Error(
      'Real UIDAI OTP required in production. Set SUREPASS_API_TOKEN and AADHAAR_PROVIDER=surepass in .env',
    );
  }

  return mockProvider;
}

function getProviderInfo() {
  const name = resolveProviderName();
  return {
    provider: name,
    uidaiOtp: name === 'surepass',
    description:
      name === 'surepass'
        ? 'OTP is sent by UIDAI to the Aadhaar-linked mobile via Surepass (licensed KYC partner)'
        : 'Development mock OTP (not from UIDAI). Set SUREPASS_API_TOKEN for real verification.',
  };
}

module.exports = { getProvider, getProviderInfo, resolveProviderName };
