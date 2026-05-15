# deploy-windows.ps1 — copy mod files directly into BeamNG's user folder for development.
# No zip needed; edit a file and reload in the Lua console.
#
# Usage (from repo root):
#   .\scripts\deploy-windows.ps1              # deploy all mods
#   .\scripts\deploy-windows.ps1 wacky_modes  # deploy one mod
#
# If PowerShell blocks the script, run once as admin:
#   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
# Or bypass per-run:
#   powershell -ExecutionPolicy Bypass -File scripts\deploy-windows.ps1

param(
    [string]$ModName = ''
)

# ── locate BeamNG user folder ──────────────────────────────────────────────────

$beamDir = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'BeamNG.drive'

if (-not (Test-Path $beamDir)) {
    Write-Host "ERROR: BeamNG user folder not found at:" -ForegroundColor Red
    Write-Host "  $beamDir" -ForegroundColor Red
    Write-Host ""
    Write-Host "Launch BeamNG.drive at least once so it creates this folder, then re-run." -ForegroundColor Yellow
    exit 1
}

# ── resolve mod(s) to deploy ──────────────────────────────────────────────────

$repoRoot = Split-Path -Parent $PSScriptRoot
$modsRoot = Join-Path $repoRoot 'mods'

if ($ModName) {
    $modPath = Join-Path $modsRoot $ModName
    if (-not (Test-Path $modPath -PathType Container)) {
        Write-Host "ERROR: Mod folder not found: $modPath" -ForegroundColor Red
        exit 1
    }
    $mods = @(Get-Item $modPath)
} else {
    $mods = Get-ChildItem $modsRoot -Directory
}

# ── deploy ────────────────────────────────────────────────────────────────────

$totalFiles = 0

foreach ($mod in $mods) {
    Write-Host "[$($mod.Name)]" -ForegroundColor Cyan

    $files = Get-ChildItem $mod.FullName -Recurse -File |
        Where-Object { $_.Name -notin @('info.json', '.gitkeep') }

    if (-not $files) {
        Write-Host "  (nothing to deploy)" -ForegroundColor DarkGray
        continue
    }

    foreach ($file in $files) {
        # Strip the mod folder prefix to get the BeamNG-relative path
        $relative = $file.FullName.Substring($mod.FullName.Length + 1)
        $dest     = Join-Path $beamDir $relative

        New-Item -ItemType Directory -Path (Split-Path $dest) -Force | Out-Null
        Copy-Item $file.FullName $dest -Force

        Write-Host "  -> $relative" -ForegroundColor Gray
        $totalFiles++
    }
}

# ── summary ───────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "$totalFiles file(s) deployed to:" -ForegroundColor Green
Write-Host "  $beamDir" -ForegroundColor White
Write-Host ""
Write-Host "In the BeamNG Lua console (F11):" -ForegroundColor Yellow
Write-Host "  Load:   extensions.load('gameplay/dropTheHammer')"
Write-Host "  Reload: extensions.reload('gameplay/dropTheHammer')"
Write-Host "  Test:   extensions.gameplay_dropTheHammer.drop()"
