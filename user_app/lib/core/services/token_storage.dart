import 'package:shared_preferences/shared_preferences.dart';

/// Token and session storage.
class TokenStorage {
  TokenStorage._internal();

  static final TokenStorage instance = TokenStorage._internal();

  static const String _tokenKey = 'auth_token';
  static const String _adminTokenKey = 'admin_token';
  static const String _adminEmailKey = 'admin_email';
  static const String _adminRoleKey = 'admin_role';
  static const String _adminNameKey = 'admin_name';
  static const String _doctorIdKey = 'doctor_id';
  static const String _nurseIdKey = 'nurse_id';
  static const String _mobileKey = 'mobile_number';
  static const String _patientTokenKey = 'patient_auth_token';
  static const String _patientIdKey = 'patient_id';
  static const String _patientEmailKey = 'patient_email';
  static const String _patientNameKey = 'patient_name';
  static const String _patientMobileKey = 'patient_mobile';
  static const String _patientProfilePictureKey = 'patient_profile_picture';
  static const String _patientGenderKey = 'patient_gender';
  static const String _patientAgeKey = 'patient_age';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getAdminToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_adminTokenKey);
  }

  Future<void> saveAdminToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adminTokenKey, token);
  }

  Future<String?> getAdminEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_adminEmailKey);
  }

  Future<void> saveAdminEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adminEmailKey, email);
  }

  Future<String?> getAdminRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_adminRoleKey);
  }

  Future<void> saveAdminRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adminRoleKey, role);
  }

  Future<String?> getAdminName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_adminNameKey);
  }

  Future<void> saveAdminName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adminNameKey, name);
  }

  Future<String?> getDoctorId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_doctorIdKey);
  }

  Future<void> saveDoctorId(String doctorId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_doctorIdKey, doctorId);
  }

  Future<String?> getNurseId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nurseIdKey);
  }

  Future<void> saveNurseId(String nurseId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nurseIdKey, nurseId);
  }

  Future<void> saveNurseToken(String token) async {
    await saveToken(token);
  }

  Future<String?> getMobileNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_mobileKey);
  }

  Future<void> saveMobileNumber(String mobile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mobileKey, mobile);
  }

  Future<void> clearDoctorSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_doctorIdKey);
    await prefs.remove(_mobileKey);
  }

  Future<void> clearNurseSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_nurseIdKey);
    await prefs.remove(_mobileKey);
  }

  Future<void> clearAdminSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_adminTokenKey);
    await prefs.remove(_adminEmailKey);
    await prefs.remove(_adminRoleKey);
    await prefs.remove(_adminNameKey);
  }

  Future<String?> getPatientToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_patientTokenKey);
  }

  Future<String?> getPatientId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_patientIdKey);
  }

  Future<String?> getPatientEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_patientEmailKey);
  }

  Future<String?> getPatientName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_patientNameKey);
  }

  Future<bool> isPatientLoggedIn() async {
    final token = await getPatientToken();
    final id = await getPatientId();
    return token != null &&
        token.isNotEmpty &&
        id != null &&
        id.isNotEmpty;
  }

  Future<void> savePatientSession({
    required String token,
    required String patientId,
    String? email,
    String? displayName,
    String? mobileNumber,
    String? profilePicture,
    String? gender,
    int? age,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_patientTokenKey, token);
    await prefs.setString(_patientIdKey, patientId);
    if (email != null) {
      await prefs.setString(_patientEmailKey, email);
    }
    if (displayName != null) {
      await prefs.setString(_patientNameKey, displayName);
    }
    if (mobileNumber != null) {
      await prefs.setString(_patientMobileKey, mobileNumber);
    }
    if (profilePicture != null) {
      await prefs.setString(_patientProfilePictureKey, profilePicture);
    }
    if (gender != null) {
      await prefs.setString(_patientGenderKey, gender);
    }
    if (age != null) {
      await prefs.setInt(_patientAgeKey, age);
    }
  }

  Future<String?> getPatientProfilePicture() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_patientProfilePictureKey);
  }

  Future<String?> getPatientGender() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_patientGenderKey);
  }

  Future<int?> getPatientAge() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_patientAgeKey);
  }

  Future<String?> getPatientMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_patientMobileKey);
  }

  Future<void> clearPatientSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_patientTokenKey);
    await prefs.remove(_patientIdKey);
    await prefs.remove(_patientEmailKey);
    await prefs.remove(_patientNameKey);
    await prefs.remove(_patientMobileKey);
    await prefs.remove(_patientProfilePictureKey);
    await prefs.remove(_patientGenderKey);
    await prefs.remove(_patientAgeKey);
  }

  Future<void> clearSession() async {
    await clearDoctorSession();
    await clearNurseSession();
    await clearAdminSession();
    await clearPatientSession();
  }

  Future<void> clearToken() async {
    await clearSession();
  }
}
