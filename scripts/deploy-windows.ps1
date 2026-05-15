# deploy-windows.ps1 — deploy mod files to BeamNG for development.
#
# Vehicles require the zip path, so this script:
#   1. Packs each mod into a .zip → Documents\BeamNG.drive\mods\
#   2. Also copies .lua files directly → Documents\BeamNG.drive\lua\...
#      so you can hot-reload Lua changes without restarting the game.
#
# Usage (from repo root):
#   .\scripts\deploy-windows.ps1              # deploy all mods
#   .\scripts\deploy-windows.ps1 wacky_modes  # deploy one mod
#
# If PowerShell blocks the script, run once as yourself (not admin):
#   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
# Or bypass per-run:
#   powershell -ExecutionPolicy Bypass -File scripts\deploy-windows.ps1

param(
    [string]$ModName = ''
)

# ── locate BeamNG folders ─────────────────────────────────────────────────────

$beamDir     = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'BeamNG.drive'
$beamModsDir = Join-Path $beamDir 'mods'

if (-not (Test-Path $beamDir)) {
    Write-Host "ERROR: BeamNG user folder not found at:" -ForegroundColor Red
    Write-Host "  $beamDir" -ForegroundColor Red
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

Add-Type -Assembly 'System.IO.Compression.FileSystem'
New-Item -ItemType Directory -Path $beamModsDir -Force | Out-Null

foreach ($mod in $mods) {
    Write-Host "[$($mod.Name)]" -ForegroundColor Cyan

    # Step 1: pack a fresh zip into BeamNG's mods folder.
    # ZipFile.CreateFromDirectory with includeBaseDirectory=false gives paths
    # like vehicles/..., lua/... at the zip root — exactly what BeamNG expects.
    $zipPath = Join-Path $beamModsDir "$($mod.Name).zip"
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
    [System.IO.Compression.ZipFile]::CreateFromDirectory(
        $mod.FullName,
        $zipPath,
        [System.IO.Compression.CompressionLevel]::Optimal,
        $false
    )
    Write-Host "  -> mods\$($mod.Name).zip" -ForegroundColor Gray

    # Step 2: also copy .lua files directly into the user folder so that
    # extensions.reload() picks up edits without a game restart.
    $luaFiles = Get-ChildItem $mod.FullName -Recurse -File -Filter '*.lua'
    foreach ($file in $luaFiles) {
        $relative = $file.FullName.Substring($mod.FullName.Length + 1)
        $dest     = Join-Path $beamDir $relative
        New-Item -ItemType Directory -Path (Split-Path $dest) -Force | Out-Null
        Copy-Item $file.FullName $dest -Force
        Write-Host "  -> $relative  [hot-reload]" -ForegroundColor DarkGray
    }
}

# ── summary ───────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "$($mods.Count) mod(s) deployed." -ForegroundColor Green
Write-Host ""
Write-Host "ACTION REQUIRED: fully restart BeamNG to register the zip mod." -ForegroundColor Yellow
Write-Host "(Vehicles are only scanned from zips, and only at startup.)" -ForegroundColor DarkGray
Write-Host ""
Write-Host "After that first restart, Lua changes don't need a restart:" -ForegroundColor White
Write-Host "  1. Edit the .lua file in the repo"
Write-Host "  2. Re-run this script"
Write-Host "  3. In-game Lua console (F11): extensions.reload('gameplay/dropTheHammer')"
