#!/usr/bin/env pwsh
#Requires -Version 7.0
<#
.SYNOPSIS
    TEMPLATE_VERSION, README ve TEMPLATE_CHANGELOG.md'yi tutarli sekilde gunceller.
.DESCRIPTION
    Versiyon bump yapar veya belirtilen versiyona gecis yapar.
    PR-4'te tam implementasyon yapilacaktir.
.PARAMETER Bump
    Versiyon artis tipi: major | minor | patch
.PARAMETER Version
    Hedef versiyon (vX.Y.Z formatinda). Belirtilirse -Bump degeri kullanilmaz.
.PARAMETER Date
    Changelog girdisi icin tarih (YYYY-MM-DD). Belirtilmezse bugunun tarihi.
.PARAMETER SkipReadme
    README.md baseline satirini guncelleme.
.PARAMETER SkipChangelog
    TEMPLATE_CHANGELOG.md'yi guncelleme.
.EXAMPLE
    pwsh scripts/Update-TemplateVersion.ps1 -Bump patch
    pwsh scripts/Update-TemplateVersion.ps1 -Version v2.1.0
    pwsh scripts/Update-TemplateVersion.ps1 -Bump minor -Date 2026-05-01
#>
param(
    [string]$Bump = $null,

    [string]$Version = '',

    [string]$Date = (Get-Date -Format 'yyyy-MM-dd'),

    [switch]$SkipReadme,

    [switch]$SkipChangelog
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $Bump -and -not $Version) {
    Write-Error "-Bump veya -Version parametrelerinden biri zorunludur."
    exit 1
}

# NOT IMPLEMENTED — PR-4'te gerceklestirilecek
Write-Host "Update-TemplateVersion" -ForegroundColor Cyan
Write-Host "Bump          : $(if ($Bump) { $Bump } else { '(belirtilmedi)' })"
Write-Host "Version       : $(if ($Version) { $Version } else { '(belirtilmedi)' })"
Write-Host "Date          : $Date"
Write-Host "SkipReadme    : $($SkipReadme.IsPresent)"
Write-Host "SkipChangelog : $($SkipChangelog.IsPresent)"
Write-Warning "Not implemented. PR-4'te implementasyon tamamlanacak."
exit 0
