/// Matches backend [LIVE_THRESHOLD_MS] default (5 minutes).
const Duration kDoctorLiveThreshold = Duration(minutes: 5);

bool isDoctorLiveNow({bool? isLiveNow, DateTime? lastActiveAt}) {
  if (isLiveNow == true) return true;
  if (lastActiveAt == null) return false;
  return DateTime.now().difference(lastActiveAt) <= kDoctorLiveThreshold;
}
