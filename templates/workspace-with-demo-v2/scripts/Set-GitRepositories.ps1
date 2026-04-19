#!/usr/bin/env pwsh
#Requires -Version 7.0
<#
.SYNOPSIS
    Workspace ve demo icin git depolarini yapilandirir.
.DESCRIPTION
    Workspace'te git init yapar, remote baglar ve demo'yu submodule
    olarak ekler. PR-3'te tam implementasyon yapilacaktir.
.PARAMETER WorkspacePath
    Workspace'in kok dizini.
.PARAMETER DemoRepoUrl
    Demo'nun git remote URL'i (submodule olarak eklenecek).
.PARAMETER WorkspaceRepoUrl
    Workspace'in git remote URL'i. Belirtilmezse remote eklenmez.
.PARAMETER SkipRemote
    Remote baglama adimini atla.
.EXAMPLE
    pwsh scripts/Set-GitRepositories.ps1 -WorkspacePath "D:\work\my-workspace" -DemoRepoUrl "https://github.com/org/demo"
    pwsh scripts/Set-GitRepositories.ps1 -WorkspacePath "D:\work\my-workspace" -DemoRepoUrl "https://github.com/org/demo" -WorkspaceRepoUrl "git@github.com:org/my-workspace.git"
#>
param(
    [Parameter(Mandatory)]
    [string]$WorkspacePath,

    [Parameter(Mandatory)]
    [string]$DemoRepoUrl,

    [string]$WorkspaceRepoUrl = '',

    [switch]$SkipRemote
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# NOT IMPLEMENTED — PR-3'te gerceklestirilecek
Write-Host "Set-GitRepositories" -ForegroundColor Cyan
Write-Host "WorkspacePath    : $WorkspacePath"
Write-Host "DemoRepoUrl      : $DemoRepoUrl"
Write-Host "WorkspaceRepoUrl : $(if ($WorkspaceRepoUrl) { $WorkspaceRepoUrl } else { '(not set)' })"
Write-Host "SkipRemote       : $($SkipRemote.IsPresent)"
Write-Warning "Not implemented. PR-3'te implementasyon tamamlanacak."
exit 0
