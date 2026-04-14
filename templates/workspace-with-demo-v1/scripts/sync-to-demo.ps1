param(
  # Workspace'den demo'ya kopyalanacak kaynak yol listesi (dosya veya dizin)
  [Parameter(Mandatory)]
  [string[]]$Sources,

  [string]$DemoPath = "",
  [string]$ManifestPath = "",
  [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step  { param([string]$Msg) Write-Host "[sync-to-demo] $Msg" }
function Write-Copy  { param([string]$Msg) Write-Host "[sync-to-demo] COPY  $Msg" -ForegroundColor Cyan }
function Write-Skip  { param([string]$Msg) Write-Host "[sync-to-demo] SKIP  $Msg" -ForegroundColor Yellow }
function Write-Ok    { param([string]$Msg) Write-Host "[sync-to-demo] OK    $Msg" -ForegroundColor Green }
function Write-Fail  { param([string]$Msg) Write-Host "[sync-to-demo] FAIL  $Msg" -ForegroundColor Red }

$templateRoot = Resolve-Path (Join-Path $PSScriptRoot "..")

if ($DemoPath -eq "") {
  $DemoPath = Join-Path $templateRoot "demo"
}
if ($ManifestPath -eq "") {
  $ManifestPath = Join-Path $templateRoot ".github/template-manifest.yml"
}

if (-not (Test-Path -LiteralPath $DemoPath -PathType Container)) {
  throw "demo/ dizini bulunamadi: $DemoPath"
}
if (-not (Test-Path -LiteralPath $ManifestPath)) {
  throw "Manifest bulunamadi: $ManifestPath"
}

Write-Step "Demo hedef : $DemoPath"
Write-Step "Manifest  : $ManifestPath"
if ($DryRun) { Write-Step "(DryRun - dosya kopyalanmaz)" }

# -------------------------------------------------------------------
# demo_sync_denylist'i manifest'ten oku
# -------------------------------------------------------------------
function Get-ManifestList {
  param([string[]]$Lines, [string]$Section)
  $items = [System.Collections.Generic.List[string]]::new()
  $inSection = $false
  foreach ($line in $Lines) {
    if ($line -match "^\s*#") { continue }
    if ($line -match "^${Section}:\s*$") { $inSection = $true; continue }
    if ($inSection) {
      if ($line -match '^\s+-\s+"?([^"]+)"?\s*$') { $items.Add($Matches[1].Trim()) }
      elseif ($line -match '^[a-zA-Z_]') { $inSection = $false }
    }
  }
  return $items.ToArray()
}

$manifestLines = Get-Content -Path $ManifestPath
$denylist = Get-ManifestList -Lines $manifestLines -Section "demo_sync_denylist"

# Secret pattern'lari (verify-no-secrets-in-demo.ps1 ile ayni set)
$secretPatterns = @(
  "AKIA[0-9A-Z]{16}",
  "ghp_[A-Za-z0-9]{36}",
  "github_pat_[A-Za-z0-9_]{82}",
  "glpat-[A-Za-z0-9\-]{20}",
  "sk-[A-Za-z0-9]{48}",
  "sk-ant-[A-Za-z0-9\-_]{95}",
  "(?i)(secret|password|passwd|api.?key|token)\s*[=:]\s*[^\s'`"]{8,}"
)

$skipExtensions = @(".png",".jpg",".jpeg",".gif",".ico",".svg",".woff",".woff2",
                    ".ttf",".eot",".zip",".gz",".tar",".pdf",".exe",".dll")

function Test-Denied {
  param([string]$RelPath)
  $normalizedRelPath = $RelPath.Replace('\', '/')
  foreach ($pattern in $denylist) {
    $normalizedPattern = $pattern.Replace('\', '/')
    $isDirectoryPattern = $normalizedPattern.EndsWith('/')
    $clean = $normalizedPattern.TrimEnd('/')
    if ($normalizedRelPath -like $clean) { return $true }
    if ($isDirectoryPattern -and ($normalizedRelPath -like "$clean/*")) { return $true }
  }
  return $false
}

function Test-HasSecret {
  param([string]$FilePath)
  $ext = [IO.Path]::GetExtension($FilePath).ToLower()
  if ($skipExtensions -contains $ext) { return $false }
  $content = Get-Content -Path $FilePath -Raw -ErrorAction SilentlyContinue
  if ($null -eq $content) { return $false }
  foreach ($rx in $secretPatterns) {
    if ($content -match $rx) { return $true }
  }
  return $false
}

$copyCount = 0
$skipCount = 0
$errorCount = 0

foreach ($source in $Sources) {
  $resolvedSource = Resolve-Path $source -ErrorAction SilentlyContinue
  if ($null -eq $resolvedSource) {
    Write-Fail "Kaynak bulunamadi: $source"
    $errorCount++
    continue
  }

  $files = if (Test-Path -LiteralPath $resolvedSource -PathType Container) {
    Get-ChildItem -Path $resolvedSource -Recurse -File -Force
  } else {
    Get-Item -LiteralPath $resolvedSource
  }

  foreach ($file in $files) {
    # Guvenlik: dosyanin template root altinda oldugundan emin ol
    $fullPath = $file.FullName
    $rootStr = $templateRoot.ToString().TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    if (-not $fullPath.StartsWith($rootStr)) {
      Write-Fail "Dosya template root disinda: $fullPath"
      $errorCount++
      continue
    }
    $relPath = $fullPath.Substring($rootStr.Length)

    # Denylist kontrolu
    if (Test-Denied -RelPath $relPath) {
      Write-Skip "$relPath (denylist)"
      $skipCount++
      continue
    }

    # Secret taramasi
    if (Test-HasSecret -FilePath $file.FullName) {
      Write-Fail "$relPath icinde potansiyel secret tespit edildi -- kopyalanmadi."
      $errorCount++
      continue
    }

    # Hedef yolu hesapla
    $destPath = Join-Path $DemoPath $relPath

    if (-not $DryRun) {
      $destDir = Split-Path $destPath -Parent
      if (-not (Test-Path -LiteralPath $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
      }
      Copy-Item -LiteralPath $file.FullName -Destination $destPath -Force
    }

    Write-Copy "$relPath"
    $copyCount++
  }
}

Write-Step "---"
Write-Step "Kopyalanan: $copyCount | Atlanan: $skipCount | Hata: $errorCount"

if ($errorCount -gt 0) {
  Write-Fail "Bazi dosyalar kopyalanamadi (secret veya eksik kaynak)."
  exit 1
}

Write-Ok "Sync tamamlandi."
exit 0
