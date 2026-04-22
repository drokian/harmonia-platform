#!/usr/bin/env pwsh
#Requires -Version 7.0
<#
.SYNOPSIS
    Belirli bir repository + PR icin uretilen review artefact klasorunu temizler.
.DESCRIPTION
    Bu script, ai-review/<repo>/PR<numara> yolunu dogrular ve hedef klasor mevcutsa siler.
    Hedef yoksa bilgilendirip atlar.
.PARAMETER Repo
    Repository adi (dosya yolu guvenli karakter seti).
.PARAMETER PrNumber
    PR numarasi (sayisal).
.EXAMPLE
    pwsh scripts/Invoke-Cleanup.ps1 -Repo harmonia-platform -PrNumber 12
#>
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z0-9._-]+$')]
    [ValidateScript({ $_ -notin '.', '..' -and -not $_.Contains('/') -and -not $_.Contains('\\') -and -not $_.Contains('..') })]
    [string]$Repo,

    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9]+$')]
    [string]$PrNumber
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RED = "`e[31m"
$GREEN = "`e[32m"
$CYAN = "`e[36m"
$RESET = "`e[0m"

function Log-Info([string]$Message) {
    Write-Host "${CYAN}[INFO]${RESET}  $Message"
}

function Log-Ok([string]$Message) {
    Write-Host "${GREEN}[OK]${RESET}    $Message"
}

function Log-ErrorMsg([string]$Message) {
    Write-Host "${RED}[ERR]${RESET}   $Message"
}

$baseDir = Join-Path -Path "ai-review/$Repo" -ChildPath "PR$PrNumber"
$normalizedBaseDir = $baseDir -replace '\\', '/'
$expectedPrefix = "ai-review/$Repo/PR"

if (-not $normalizedBaseDir.StartsWith($expectedPrefix, [System.StringComparison]::Ordinal)) {
    Log-ErrorMsg "Gecersiz hedef dizin: $baseDir"
    exit 1
}

if (Test-Path -LiteralPath $baseDir -PathType Container) {
    Remove-Item -LiteralPath $baseDir -Recurse -Force
    Log-Ok "Temizlendi: $baseDir"
}
else {
    Log-Info "Dizin yok, atlaniyor: $baseDir"
}
