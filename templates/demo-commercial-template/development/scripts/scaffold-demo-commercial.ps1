param(
  [Parameter(Mandatory = $true)]
  [string]$TargetPath,

  [ValidateSet("node-service", "python-service", "nextjs-app")]
  [string]$Stack = "node-service",

  [switch]$InitGitRepos,

  [switch]$KeepDevelopmentLocal = $true,

  [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step {
  param([string]$Message)
  Write-Host "[scaffold] $Message"
}

function Ensure-Directory {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Path $Path | Out-Null
  }
}

function Copy-Tree {
  param(
    [string]$Source,
    [string]$Destination,
    [switch]$AllowOverwrite
  )

  Ensure-Directory -Path $Destination
  $copyArgs = @{
    Path = (Join-Path $Source "*")
    Destination = $Destination
    Recurse = $true
    Force = [bool]$AllowOverwrite
  }
  Copy-Item @copyArgs
}

function Ensure-GitIgnoreRule {
  param(
    [string]$GitIgnorePath,
    [string]$Rule
  )

  if (-not (Test-Path -LiteralPath $GitIgnorePath)) {
    "" | Set-Content -Path $GitIgnorePath -Encoding utf8
  }

  $content = Get-Content -Path $GitIgnorePath -Raw
  $escapedRule = [Regex]::Escape($Rule)
  if ($content -notmatch "(?m)^$escapedRule$") {
    if ($content.Length -gt 0 -and -not $content.EndsWith("`n")) {
      Add-Content -Path $GitIgnorePath -Value ""
    }
    Add-Content -Path $GitIgnorePath -Value $Rule
  }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$templateRoot = Resolve-Path (Join-Path $scriptDir "..\..")

$targetResolved = [System.IO.Path]::GetFullPath($TargetPath)
if ((Test-Path -LiteralPath $targetResolved) -and -not $Force) {
  $existing = Get-ChildItem -LiteralPath $targetResolved -Force -ErrorAction SilentlyContinue
  if ($existing.Count -gt 0) {
    throw "TargetPath dolu. Uzerine yazmak icin -Force kullanin: $targetResolved"
  }
}

Ensure-Directory -Path $targetResolved
Write-Step "Workspace dizini hazirlaniyor: $targetResolved"

$baseDirs = @(".claude", ".docs", ".github", "development", "demo", "commercial")
foreach ($dir in $baseDirs) {
  Copy-Tree -Source (Join-Path $templateRoot $dir) -Destination (Join-Path $targetResolved $dir) -AllowOverwrite:$Force
}

$baseFiles = @("README.md", ".editorconfig", ".gitignore")
foreach ($file in $baseFiles) {
  Copy-Item -Path (Join-Path $templateRoot $file) -Destination (Join-Path $targetResolved $file) -Force:$Force
}

$overlayRoot = Join-Path $templateRoot (Join-Path "stacks" $Stack)
if (-not (Test-Path -LiteralPath $overlayRoot)) {
  throw "Stack bulunamadi: $Stack"
}

Write-Step "Stack overlay uygulaniyor: $Stack"
Copy-Tree -Source (Join-Path $overlayRoot "demo") -Destination (Join-Path $targetResolved "demo") -AllowOverwrite
Copy-Tree -Source (Join-Path $overlayRoot "commercial") -Destination (Join-Path $targetResolved "commercial") -AllowOverwrite

if ($KeepDevelopmentLocal) {
  Write-Step "development/ kurali hedef .gitignore dosyasina ekleniyor"
  Ensure-GitIgnoreRule -GitIgnorePath (Join-Path $targetResolved ".gitignore") -Rule "development/"
}

if ($InitGitRepos) {
  $gitCmd = Get-Command git -ErrorAction SilentlyContinue
  if (-not $gitCmd) {
    throw "Git bulunamadi. -InitGitRepos icin git kurulu olmali."
  }

  Write-Step "demo/ ve commercial/ icinde git init calistiriliyor"
  Push-Location (Join-Path $targetResolved "demo")
  git init | Out-Null
  Pop-Location

  Push-Location (Join-Path $targetResolved "commercial")
  git init | Out-Null
  Pop-Location
}

Write-Step "Scaffold tamamlandi. Sonraki adim: dependency kurulumu ve README ozellestirmesi"