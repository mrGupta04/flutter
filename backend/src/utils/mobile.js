const DEFAULT_COUNTRY_CODE = '91';

function normalizeCountryCode(countryCode) {
  const code = String(countryCode || DEFAULT_COUNTRY_CODE).replace(/\D/g, '');
  return code || DEFAULT_COUNTRY_CODE;
}

function parseMobileInput(mobile, countryCode = DEFAULT_COUNTRY_CODE) {
  const code = normalizeCountryCode(countryCode);
  let digits = String(mobile || '').replace(/\D/g, '');

  if (digits.startsWith(code) && digits.length > code.length + 5) {
    digits = digits.slice(code.length);
  }
  if (digits.startsWith('0')) {
    digits = digits.slice(1);
  }

  return { countryCode: code, nationalNumber: digits };
}

function normalizeMobile(mobile, countryCode = DEFAULT_COUNTRY_CODE) {
  return parseMobileInput(mobile, countryCode).nationalNumber;
}

function validateIndianNationalNumber(nationalNumber) {
  if (nationalNumber.length !== 10) {
    return { valid: false, error: 'Mobile number must be exactly 10 digits' };
  }
  if (!/^[6-9]\d{9}$/.test(nationalNumber)) {
    return { valid: false, error: 'Please enter a valid 10-digit mobile number' };
  }
  return { valid: true };
}

function validateMobile(mobile, { required = true, countryCode = DEFAULT_COUNTRY_CODE } = {}) {
  const raw = String(mobile || '').trim();
  if (!raw) {
    if (required) {
      return { valid: false, error: 'Mobile number is required' };
    }
    return { valid: true, mobile: '', countryCode: normalizeCountryCode(countryCode) };
  }

  const { countryCode: code, nationalNumber } = parseMobileInput(mobile, countryCode);

  if (code === '91') {
    const indianCheck = validateIndianNationalNumber(nationalNumber);
    if (!indianCheck.valid) {
      return indianCheck;
    }
    return { valid: true, mobile: nationalNumber, countryCode: code };
  }

  if (nationalNumber.length < 6 || nationalNumber.length > 15) {
    return {
      valid: false,
      error: 'Please enter a valid mobile number for the selected country',
    };
  }

  return { valid: true, mobile: nationalNumber, countryCode: code };
}

function formatMobileDisplay(mobile, countryCode = DEFAULT_COUNTRY_CODE) {
  const code = normalizeCountryCode(countryCode);
  const national = normalizeMobile(mobile, code);
  if (!national) return '';
  return `+${code} ${national}`;
}

module.exports = {
  DEFAULT_COUNTRY_CODE,
  normalizeCountryCode,
  normalizeMobile,
  parseMobileInput,
  validateMobile,
  formatMobileDisplay,
};
