#!/usr/bin/env pwsh
#Requires -Version 7.0
<#
.SYNOPSIS
    Hedef workspace'te klasor yapisini olusturur.
.DESCRIPTION
    Manifest'teki generated_validation.required_dirs listesini baz alarak
    belirtilen TargetPath altinda tum klasorleri olusturur.
    PR-3'te tam implementasyon yapilacaktir.
.PARAMETER TargetPath
    Olusturulacak workspace'in kok dizini.
.PARAMETER DryRun
    Gercekte olusturma; yalnizca neyin yaratilacagini listele.
.EXAMPLE
    pwsh scripts/New-DirectoryStructure.ps1 -TargetPath "D:\work\my-workspace"
    pwsh scripts/New-DirectoryStructure.ps1 -TargetPath "D:\work\my-workspace" -DryRun
#>
param(
    [Parameter(Mandatory)]
    [string]$TargetPath,

    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$templateDirectories = @(
    '.github',
    '.github/workflows',
    'docs',
    'docs/architecture',
    'docs/installation',
    'development',
    'development/backlogs',
    'development/sprints',
    'development/sprints/archive',
    'development/decisions',
    'development/conventions',
    'development/guides',
    'development/checklists',
    'development/glossary',
    'scripts',
    'backups',
    'demo'
)

$created = 0
$skipped = 0

Write-Host "New-DirectoryStructure" -ForegroundColor Cyan
Write-Host "TargetPath : $TargetPath"
Write-Host "DryRun     : $($DryRun.IsPresent)"

if (-not (Test-Path -LiteralPath $TargetPath -PathType Container)) {
    if ($DryRun) {
        Write-Host "[DRYRUN] Root klasor olusturulacak: $TargetPath"
    }
    else {
        New-Item -Path $TargetPath -ItemType Directory -Force | Out-Null
        Write-Host "[OK] Root klasor olusturuldu: $TargetPath"
    }
}

foreach ($relativePath in $templateDirectories) {
    $fullPath = Join-Path -Path $TargetPath -ChildPath $relativePath

    if (Test-Path -LiteralPath $fullPath -PathType Container) {
        $skipped++
        Write-Host "[SKIP] Zaten var: $relativePath"
        continue
    }

    if ($DryRun) {
        Write-Host "[DRYRUN] Klasor olusturulacak: $relativePath"
    }
    else {
        New-Item -Path $fullPath -ItemType Directory -Force | Out-Null
        Write-Host "[OK] Klasor olusturuldu: $relativePath"
    }
    $created++
}

Write-Host ""
Write-Host "Ozet" -ForegroundColor Cyan
Write-Host "Created : $created"
Write-Host "Skipped : $skipped"

exit 0
