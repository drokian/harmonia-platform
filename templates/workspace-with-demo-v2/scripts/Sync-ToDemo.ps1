#!/usr/bin/env pwsh
#Requires -Version 7.0
<#
.SYNOPSIS
    Workspace icerigini demo submodule'une kopyalar.
.DESCRIPTION
    Dosya kopyalama modunda forbidden pattern filtrelemesi ve secret taramasi
    yaparak workspace dosyalarini demo'ya kopyalar.
    -BuildMode ile build cikti dizinini demo'ya kopyalar.
    PR-4'te tam implementasyon yapilacaktir.
.PARAMETER SourcePath
    Kaynak workspace dizini.
.PARAMETER TargetPath
    Hedef demo dizini (submodule).
.PARAMETER DryRun
    Gercekte kopyalama yapma; yalnizca neyin kopyalanacagini listele.
.PARAMETER BuildMode
    Build ciktisini kopyala (dosya kopyalama yerine).
.PARAMETER BuildCommand
    Build komutu. Belirtilmezse package.json mevcutsa otomatik tespit edilir.
.PARAMETER BuildOutputDir
    Build cikti dizini. Belirtilmezse sirayla: dist/, build/, out/, .next/out/, public/, _site/ denenir.
.EXAMPLE
    pwsh scripts/Sync-ToDemo.ps1 -SourcePath "D:\work\my-workspace" -TargetPath "D:\work\my-workspace\demo"
    pwsh scripts/Sync-ToDemo.ps1 -SourcePath "D:\work\my-workspace" -TargetPath "D:\work\my-workspace\demo" -DryRun
    pwsh scripts/Sync-ToDemo.ps1 -SourcePath "D:\work\my-workspace" -TargetPath "D:\work\my-workspace\demo" -BuildMode
    pwsh scripts/Sync-ToDemo.ps1 -SourcePath "D:\work\my-workspace" -TargetPath "D:\work\my-workspace\demo" -BuildMode -BuildOutputDir "dist"
#>
param(
    [Parameter(Mandatory)]
    [string]$SourcePath,

    [Parameter(Mandatory)]
    [string]$TargetPath,

    [switch]$DryRun,

    [switch]$BuildMode,

    [string]$BuildCommand = '',

    [string]$BuildOutputDir = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# NOT IMPLEMENTED — PR-4'te gerceklestirilecek
Write-Host "Sync-ToDemo" -ForegroundColor Cyan
Write-Host "SourcePath     : $SourcePath"
Write-Host "TargetPath     : $TargetPath"
Write-Host "DryRun         : $($DryRun.IsPresent)"
Write-Host "BuildMode      : $($BuildMode.IsPresent)"
Write-Host "BuildCommand   : $(if ($BuildCommand) { $BuildCommand } else { '(otomatik tespit)' })"
Write-Host "BuildOutputDir : $(if ($BuildOutputDir) { $BuildOutputDir } else { '(otomatik tespit)' })"
Write-Warning "Not implemented. PR-4'te implementasyon tamamlanacak."
exit 0
