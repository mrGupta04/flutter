# Start the 1mg Doctors API (frees port 3000 if already in use)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

function Stop-PortListener {
    param([int]$Port = 3000)
    $pids = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty OwningProcess -Unique
    foreach ($processId in $pids) {
        if (-not $processId) { continue }
        Write-Host "Stopping process on port ${Port} (PID $processId)..."
        Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
    }
    if ($pids) {
        Start-Sleep -Seconds 1
    }
}

if (-not (Test-Path 'node_modules')) {
    Write-Host 'Installing dependencies...'
    npm install
}

if (-not (Test-Path '.env')) {
    Write-Host 'Creating .env from .env.example...'
    Copy-Item '.env.example' '.env'
}

Stop-PortListener -Port 3000

Write-Host 'Starting API at http://localhost:3000'
npm start
