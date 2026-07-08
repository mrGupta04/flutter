function hasText(value) {
  return Boolean(String(value || '').trim());
}

function getDoctorProfileMissingFields(doctor) {
  if (!doctor) return ['doctor'];
  const missing = [];

  if (!hasText(doctor.firstName)) missing.push('firstName');
  if (!hasText(doctor.lastName)) missing.push('lastName');
  if (!hasText(doctor.email)) missing.push('email');
  if (!hasText(doctor.mobileNumber)) missing.push('mobileNumber');
  if (!hasText(doctor.medicalRegistrationNumber)) {
    missing.push('medicalRegistrationNumber');
  }
  if (!hasText(doctor.medicalCouncilName)) missing.push('medicalCouncilName');
  if (!Array.isArray(doctor.specializations) || doctor.specializations.length === 0) {
    missing.push('specializations');
  }
  if (!hasText(doctor.qualification)) missing.push('qualification');
  if (doctor.yearsOfExperience == null || doctor.yearsOfExperience === '') {
    missing.push('yearsOfExperience');
  }
  if (!hasText(doctor.clinicName)) missing.push('clinicName');
  if (!hasText(doctor.address)) missing.push('address');
  if (!hasText(doctor.city)) missing.push('city');
  if (!hasText(doctor.state)) missing.push('state');
  if (!hasText(doctor.pincode)) missing.push('pincode');

  const hasConsultationOption =
    doctor.offersOnlineConsult || doctor.offersBookHome || doctor.offersVisitSite;
  if (!hasConsultationOption) missing.push('consultationOptions');

  return missing;
}

function isDoctorProfileCompleteForApproval(doctor) {
  return getDoctorProfileMissingFields(doctor).length === 0;
}

function isDoctorProfilePublicDisplayable(doctor) {
  if (!doctor) return false;
  return (
    hasText(doctor.firstName) &&
    Array.isArray(doctor.specializations) &&
    doctor.specializations.length > 0 &&
    hasText(doctor.qualification)
  );
}

module.exports = {
  getDoctorProfileMissingFields,
  isDoctorProfileCompleteForApproval,
  isDoctorProfilePublicDisplayable,
};
