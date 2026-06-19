# Run user app on a physical Android device with your PC's LAN IP.
$ErrorActionPreference = 'Stop'

$ip = (
  Get-NetIPAddress -AddressFamily IPv4 |
  Where-Object {
    $_.IPAddress -notlike '127.*' -and
    $_.IPAddress -notlike '169.254.*' -and
    $_.PrefixOrigin -ne 'WellKnown'
  } |
  Select-Object -First 1 -ExpandProperty IPAddress
)

if (-not $ip) {
  Write-Error 'Could not detect LAN IP. Set API_BASE_URL manually.'
}

$devHostFile = Join-Path $PSScriptRoot 'lib\core\config\dev_api_host.dart'
@"
/// PC LAN IPv4 for testing on a physical Android device (`ipconfig` on Windows).
/// Set to empty string when using the Android emulator (uses 10.0.2.2).
const String physicalDeviceApiHost = '$ip';

/// When true, Android uses [physicalDeviceApiHost] unless API_HOST / API_BASE_URL is set.
const bool usePhysicalDeviceApiHost = true;
"@ | Set-Content $devHostFile -Encoding UTF8

$apiUrl = "http://${ip}:3000/api/v1"
Write-Host "Using API: $apiUrl"
Write-Host "Updated dev_api_host.dart with IP: $ip"
Write-Host 'Ensure backend is running: cd backend; npm start'
Write-Host ''

flutter run -d ZD222L7DC7 --dart-define=API_BASE_URL=$apiUrl @args
