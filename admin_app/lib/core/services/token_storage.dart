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
  static const String _adminCanReassignKey = 'admin_can_reassign';
  static const String _adminPermissionsKey = 'admin_permissions';
  static const String _adminRefreshTokenKey = 'admin_refresh_token';
  static const String _adminSessionIdKey = 'admin_session_id';
  static const String _doctorIdKey = 'doctor_id';
  static const String _nurseIdKey = 'nurse_id';
  static const String _ambulanceIdKey = 'ambulance_id';
  static const String _bloodBankIdKey = 'blood_bank_id';
  static const String _labIdKey = 'lab_id';
  static const String _scanCenterIdKey = 'scan_center_id';
  static const String _providerTypeKey = 'provider_type';
  static const String _mobileKey = 'mobile_number';
  static const String _providerOnlineKey = 'provider_available_online';

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

  Future<bool> getAdminCanReassign() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_adminCanReassignKey) ?? false;
  }

  Future<void> saveAdminCanReassign(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_adminCanReassignKey, value);
  }

  Future<List<String>> getAdminPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_adminPermissionsKey) ?? const [];
  }

  Future<void> saveAdminPermissions(List<String> permissions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_adminPermissionsKey, permissions);
  }

  Future<String?> getAdminRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_adminRefreshTokenKey);
  }

  Future<String?> getAdminSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_adminSessionIdKey);
  }

  Future<void> saveAdminRefreshSession({
    required String refreshToken,
    required String sessionId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adminRefreshTokenKey, refreshToken);
    await prefs.setString(_adminSessionIdKey, sessionId);
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

  Future<String?> getAmbulanceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ambulanceIdKey);
  }

  Future<void> saveAmbulanceId(String ambulanceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ambulanceIdKey, ambulanceId);
  }

  Future<String?> getBloodBankId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_bloodBankIdKey);
  }

  Future<void> saveBloodBankId(String bloodBankId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bloodBankIdKey, bloodBankId);
  }

  Future<String?> getLabId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_labIdKey);
  }

  Future<void> saveLabId(String labId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_labIdKey, labId);
  }

  Future<String?> getScanCenterId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_scanCenterIdKey);
  }

  Future<void> saveScanCenterId(String scanCenterId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scanCenterIdKey, scanCenterId);
  }

  Future<String?> getProviderType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_providerTypeKey);
  }

  Future<void> saveProviderType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_providerTypeKey, type);
  }

  Future<void> saveProviderSession({
    required String providerType,
    required String token,
    String? entityId,
  }) async {
    await saveToken(token);
    await saveProviderType(providerType);
    switch (providerType) {
      case 'doctor':
        if (entityId != null) await saveDoctorId(entityId);
      case 'nurse':
        if (entityId != null) await saveNurseId(entityId);
      case 'ambulance':
        if (entityId != null) await saveAmbulanceId(entityId);
      case 'blood-bank':
      case 'bloodbank':
        if (entityId != null) await saveBloodBankId(entityId);
      case 'lab':
        if (entityId != null) await saveLabId(entityId);
      case 'scan-center':
      case 'scan_center':
        if (entityId != null) await saveScanCenterId(entityId);
    }
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
    await prefs.remove(_providerTypeKey);
  }

  Future<void> clearNurseSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_nurseIdKey);
    await prefs.remove(_mobileKey);
    await prefs.remove(_providerTypeKey);
  }

  Future<bool> getProviderOnlineEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_providerOnlineKey) ?? false;
  }

  Future<void> setProviderOnlineEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_providerOnlineKey, enabled);
  }

  Future<void> clearProviderSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_doctorIdKey);
    await prefs.remove(_nurseIdKey);
    await prefs.remove(_ambulanceIdKey);
    await prefs.remove(_bloodBankIdKey);
    await prefs.remove(_labIdKey);
    await prefs.remove(_scanCenterIdKey);
    await prefs.remove(_providerTypeKey);
    await prefs.remove(_mobileKey);
    await prefs.remove(_providerOnlineKey);
  }

  Future<void> clearAdminSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_adminTokenKey);
    await prefs.remove(_adminEmailKey);
    await prefs.remove(_adminRoleKey);
    await prefs.remove(_adminNameKey);
    await prefs.remove(_adminCanReassignKey);
    await prefs.remove(_adminPermissionsKey);
    await prefs.remove(_adminRefreshTokenKey);
    await prefs.remove(_adminSessionIdKey);
  }

  Future<void> clearSession() async {
    await clearDoctorSession();
    await clearNurseSession();
    await clearAdminSession();
  }

  Future<void> clearToken() async {
    await clearSession();
  }
}
