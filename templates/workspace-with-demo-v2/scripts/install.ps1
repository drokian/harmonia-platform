#!/usr/bin/env pwsh
#Requires -Version 7.0
<#
.SYNOPSIS
    workspace-with-demo-v2 kurulum TUI'su.
.DESCRIPTION
    Guided veya auto mod ile workspace iskeletini olusturur.
    PR-2'de tam implementasyon yapilacaktir.
.PARAMETER Mode
    Kurulum modu: guided | auto
.EXAMPLE
    pwsh scripts/install.ps1 -Mode guided
    pwsh scripts/install.ps1 -Mode auto
#>
param(
    [ValidateSet('guided', 'auto')]
    [string]$Mode
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# NOT IMPLEMENTED — PR-2'de gerceklestirilecek
Write-Host "workspace-with-demo-v2 installer" -ForegroundColor Cyan
Write-Host "Mode: $(if ($Mode) { $Mode } else { '(not set)' })"
Write-Host ""
Write-Warning "Not implemented. PR-2'de TUI implementasyonu tamamlanacak."
exit 0
