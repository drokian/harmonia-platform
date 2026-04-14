param(
  [string]$RootPath = "",
  [string]$ManifestPath = "",
  [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step  { param([string]$Msg) Write-Host "[validate] $Msg" }
function Write-Ok    { param([string]$Msg) Write-Host "[validate] OK    $Msg" -ForegroundColor Green }
function Write-Fail  { param([string]$Msg) Write-Host "[validate] FAIL  $Msg" -ForegroundColor Red }
function Write-Warn  { param([string]$Msg) Write-Host "[validate] WARN  $Msg" -ForegroundColor Yellow }

# Kokü belirle
if ($RootPath -eq "") {
  $RootPath = Resolve-Path (Join-Path $PSScriptRoot "..")
}
if ($ManifestPath -eq "") {
  $ManifestPath = Join-Path $RootPath ".github/template-manifest.yml"
}

if (-not (Test-Path -LiteralPath $ManifestPath)) {
  throw "Manifest not found: $ManifestPath"
}

# -------------------------------------------------------------------
# YAML parser — sadece liste-alti-madde formatini destekler:
#   key:
#     - item1
#     - item2
# -------------------------------------------------------------------
function Get-ManifestList {
  param([string[]]$Lines, [string]$Section)

  $items = [System.Collections.Generic.List[string]]::new()
  $inSection = $false

  foreach ($line in $Lines) {
    if ($line -match "^\s*#") { continue }           # yorum satiri

    if ($line -match "^${Section}:\s*$") {
      $inSection = $true
      continue
    }

    if ($inSection) {
      if ($line -match '^\s+-\s+"?([^"]+)"?\s*$') {
        $items.Add($Matches[1].Trim())
      }
      elseif ($line -match '^[a-zA-Z_]') {
        $inSection = $false
      }
    }
  }

  return $items.ToArray()
}

$manifestLines = Get-Content -Path $ManifestPath
$requiredDirs  = Get-ManifestList -Lines $manifestLines -Section "required_dirs"
$requiredFiles = Get-ManifestList -Lines $manifestLines -Section "required_files"
$forbiddenGlobs = Get-ManifestList -Lines $manifestLines -Section "forbidden_globs"

Write-Step "Root  : $RootPath"
Write-Step "Manifest: $ManifestPath"
if ($DryRun) { Write-Step "(DryRun - sadece rapor)" }

$failCount = 0

# --- Required dirs ---
Write-Step "--- required_dirs kontrol ---"
foreach ($dir in $requiredDirs) {
  $full = Join-Path $RootPath $dir
  if (Test-Path -LiteralPath $full -PathType Container) {
    Write-Ok $dir
  }
  else {
    Write-Fail "Dizin eksik: $dir"
    $failCount++
  }
}

# --- Required files ---
Write-Step "--- required_files kontrol ---"
foreach ($file in $requiredFiles) {
  $full = Join-Path $RootPath $file
  if (Test-Path -LiteralPath $full -PathType Leaf) {
    Write-Ok $file
  }
  else {
    Write-Fail "Dosya eksik: $file"
    $failCount++
  }
}

# --- Forbidden globs ---
Write-Step "--- forbidden_globs kontrol ---"
$forbiddenCount = 0
foreach ($pattern in $forbiddenGlobs) {
  # ** iceren pattern'lari recursive ara, digerlerini direkt bul
  $found = Get-ChildItem -Path $RootPath -Recurse -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -like (Join-Path $RootPath $pattern.Replace("/", [IO.Path]::DirectorySeparatorChar)) }

  foreach ($f in $found) {
    Write-Fail "Yasak dosya bulundu ($pattern): $($f.FullName.Replace($RootPath, '').TrimStart([IO.Path]::DirectorySeparatorChar))"
    $forbiddenCount++
    $failCount++
  }
}
if ($forbiddenCount -eq 0) {
  Write-Ok "Yasak glob eslesmesi yok"
}

# --- Sonuc ---
Write-Step "---"
if ($failCount -eq 0) {
  Write-Ok "Tum kontroller gecti."
  exit 0
}
else {
  Write-Fail "$failCount kontrol basarisiz."
  exit 1
}
