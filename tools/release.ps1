<#
.SYNOPSIS
    Cuts a new Echo Padel release: bumps AppVersion.gd, exports the Windows
    build, zips it, commits, tags, and publishes a GitHub release with the
    zip attached - the same asset name (EchoPadel-Windows.zip) Updater.gd
    looks for, on the same repo (Arch1105/echo-padel) it checks against.

.PARAMETER Version
    The new version number, e.g. "1.1.0" (no "v" prefix - this script adds
    it for the git tag/release name; AppVersion.gd's CURRENT const stays
    un-prefixed since that's what it's compared against directly).

.EXAMPLE
    .\tools\release.ps1 -Version 1.1.0
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$Version
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

# Some shells start with a stale PATH that predates the GitHub CLI install -
# fall back to its default install location so `gh release create` below
# doesn't silently fail after the tag has already been pushed.
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    $ghDefault = "C:\Program Files\GitHub CLI"
    if (Test-Path (Join-Path $ghDefault "gh.exe")) {
        $env:Path = "$ghDefault;$env:Path"
    }
}

$godot = Join-Path $root "tools\godot\Godot_v4.7.1-stable_win64_console.exe"
$buildDir = Join-Path $root "build\windows"
$exePath = Join-Path $buildDir "EchoPadel.exe"
$zipPath = Join-Path $root "EchoPadel-Windows.zip"
$appVersionPath = Join-Path $root "scripts\AppVersion.gd"

if (-not (Test-Path $godot)) {
    throw "Godot editor binary not found at $godot"
}

Write-Host "==> Bumping AppVersion.gd to $Version"
$content = Get-Content $appVersionPath -Raw
if (-not ([regex]::IsMatch($content, 'const CURRENT := "[^"]*"'))) {
    throw "Could not find the CURRENT const in $appVersionPath - check its format hasn't changed."
}
$newContent = $content -replace 'const CURRENT := "[^"]*"', "const CURRENT := `"$Version`""
Set-Content -Path $appVersionPath -Value $newContent -NoNewline

Write-Host "==> Exporting Windows release build"
if (Test-Path $buildDir) { Remove-Item $buildDir -Recurse -Force }
New-Item -ItemType Directory -Path $buildDir | Out-Null
& $godot --headless --export-release "Windows Desktop" $exePath
if ($LASTEXITCODE -ne 0) { throw "Godot export failed (exit $LASTEXITCODE)" }
if (-not (Test-Path $exePath)) { throw "Export reported success but $exePath is missing" }

Write-Host "==> Copying bin/ (NVDA bridge) alongside the exe"
$destBin = Join-Path $buildDir "bin"
if (Test-Path $destBin) { Remove-Item $destBin -Recurse -Force }
Copy-Item (Join-Path $root "bin") $destBin -Recurse -Force
Remove-Item (Join-Path $destBin ".gdignore") -Force -ErrorAction SilentlyContinue

Write-Host "==> Zipping $zipPath"
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Compress-Archive -Path $exePath, $destBin -DestinationPath $zipPath

Write-Host "==> Committing version bump (if any)"
git add $appVersionPath
$staged = git diff --cached --name-only
if ($staged) {
    git commit -m "Release v$Version"
    if ($LASTEXITCODE -ne 0) { throw "git commit failed" }
} else {
    Write-Host "    (AppVersion.gd already at $Version, nothing to commit)"
}
git push origin main
if ($LASTEXITCODE -ne 0) { throw "git push origin main failed" }

Write-Host "==> Tagging v$Version"
git tag "v$Version"
if ($LASTEXITCODE -ne 0) { throw "git tag failed (does v$Version already exist?)" }
git push origin "v$Version"
if ($LASTEXITCODE -ne 0) { throw "git push of tag v$Version failed" }

Write-Host "==> Publishing GitHub release"
gh release create "v$Version" $zipPath --title "Echo Padel v$Version" --notes "Echo Padel v$Version"
if ($LASTEXITCODE -ne 0) { throw "gh release create failed" }

Write-Host "==> Done. v$Version is live - existing installs will offer this update next time they check."
