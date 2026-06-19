/// PC LAN IPv4 for testing on a physical Android device (`ipconfig` on Windows).
/// Set to empty string when using the Android emulator (uses 10.0.2.2).
const String physicalDeviceApiHost = '10.12.67.190';

/// When true, Android uses [physicalDeviceApiHost] unless API_HOST / API_BASE_URL is set.
const bool usePhysicalDeviceApiHost = true;
