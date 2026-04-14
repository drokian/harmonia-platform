param(
  [string]$DemoPath = "",
  [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step { param([string]$Msg) Write-Host "[secret-scan] $Msg" }
function Write-Hit  { param([string]$Msg) Write-Host "[secret-scan] HIT  $Msg" -ForegroundColor Red }
function Write-Ok   { param([string]$Msg) Write-Host "[secret-scan] OK   $Msg" -ForegroundColor Green }

if ($DemoPath -eq "") {
  $DemoPath = Resolve-Path (Join-Path $PSScriptRoot "../demo")
}

if (-not (Test-Path -LiteralPath $DemoPath -PathType Container)) {
  throw "demo/ dizini bulunamadi: $DemoPath"
}

Write-Step "Tarama dizini: $DemoPath"
if ($DryRun) { Write-Step "(DryRun - sadece rapor)" }

# Secret pattern tanimlari
$patterns = @(
  @{ Name = "AWS Access Key";          Regex = "AKIA[0-9A-Z]{16}" },
  @{ Name = "GitHub PAT (ghp_)";       Regex = "ghp_[A-Za-z0-9]{36}" },
  @{ Name = "GitHub PAT (github_pat)"; Regex = "github_pat_[A-Za-z0-9_]{82}" },
  @{ Name = "GitLab PAT";              Regex = "glpat-[A-Za-z0-9\-]{20}" },
  @{ Name = "OpenAI API Key";          Regex = "sk-[A-Za-z0-9]{48}" },
  @{ Name = "Anthropic API Key";       Regex = "sk-ant-[A-Za-z0-9\-_]{95}" },
  @{ Name = "Generic secret= assign"; Regex = "(?i)(secret|password|passwd|api.?key|token)\s*[=:]\s*[^\s'\""]{8,}" },
  @{ Name = ".env value pattern";      Regex = "^[A-Z_]+=[^\s]" }
)

# Taranmayacak uzantilar (binary)
$skipExtensions = @(".png", ".jpg", ".jpeg", ".gif", ".ico", ".svg", ".woff", ".woff2",
                    ".ttf", ".eot", ".zip", ".gz", ".tar", ".pdf", ".exe", ".dll")

$hitCount = 0
$scannedCount = 0

$files = Get-ChildItem -Path $DemoPath -Recurse -File -Force -ErrorAction SilentlyContinue

foreach ($file in $files) {
  $ext = $file.Extension.ToLower()
  if ($skipExtensions -contains $ext) { continue }

  $scannedCount++
  $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
  if ($null -eq $content) { continue }

  $relPath = $file.FullName.Replace($DemoPath, "").TrimStart([IO.Path]::DirectorySeparatorChar)
  $isEnvFile = $file.Name -like ".env*"

  foreach ($p in $patterns) {
    # .env value pattern yalnizca .env* adli dosyalara uygulanir
    if ($p.Name -eq ".env value pattern" -and -not $isEnvFile) { continue }
    if ($content -match $p.Regex) {
      Write-Hit "$relPath — $($p.Name)"
      $hitCount++
      break
    }
  }
}

Write-Step "Taranan dosya: $scannedCount"

if ($hitCount -eq 0) {
  Write-Ok "Secret bulunamadi."
  exit 0
}
else {
  Write-Hit "$hitCount dosyada potansiyel secret tespit edildi. demo/ dizinini gozden gecirin."
  exit 1
}
