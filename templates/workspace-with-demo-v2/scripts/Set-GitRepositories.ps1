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

function Invoke-Git {
    param(
        [Parameter(Mandatory)][string[]]$Args,
        [string]$ErrorContext = 'git command failed'
    )

    $output = & git @Args 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "$ErrorContext`n$($output -join "`n")"
    }
    return $output
}

function Test-Git {
    param([Parameter(Mandatory)][string[]]$Args)
    & git @Args *> $null
    return ($LASTEXITCODE -eq 0)
}

if (-not (Test-Path -LiteralPath $WorkspacePath -PathType Container)) {
    throw "WorkspacePath bulunamadi: $WorkspacePath"
}

Push-Location $WorkspacePath
try {
    Write-Host "Set-GitRepositories" -ForegroundColor Cyan
    Write-Host "WorkspacePath    : $WorkspacePath"
    Write-Host "DemoRepoUrl      : $DemoRepoUrl"
    Write-Host "WorkspaceRepoUrl : $(if ($WorkspaceRepoUrl) { $WorkspaceRepoUrl } else { '(not set)' })"
    Write-Host "SkipRemote       : $($SkipRemote.IsPresent)"

    # 1) git init (idempotent)
    if (Test-Path -LiteralPath (Join-Path $WorkspacePath '.git')) {
        Write-Host "[SKIP] Git repo zaten mevcut"
    }
    else {
        Invoke-Git -Args @('init') -ErrorContext 'git init basarisiz'
        Write-Host "[OK] git init tamamlandi"
    }

    # 2) origin remote
    if (-not $SkipRemote -and -not [string]::IsNullOrWhiteSpace($WorkspaceRepoUrl)) {
        if (Test-Git -Args @('remote', 'get-url', 'origin')) {
            $currentOrigin = (& git remote get-url origin)
            if ($currentOrigin -ne $WorkspaceRepoUrl) {
                Invoke-Git -Args @('remote', 'set-url', 'origin', $WorkspaceRepoUrl) -ErrorContext 'origin set-url basarisiz'
                Write-Host "[OK] origin guncellendi"
            }
            else {
                Write-Host "[SKIP] origin zaten dogru URL'e sahip"
            }
        }
        else {
            Invoke-Git -Args @('remote', 'add', 'origin', $WorkspaceRepoUrl) -ErrorContext 'origin add basarisiz'
            Write-Host "[OK] origin remote eklendi"
        }
    }
    elseif (-not $SkipRemote) {
        Write-Host "[INFO] WorkspaceRepoUrl verilmedi, remote adimi atlandi"
    }
    else {
        Write-Host "[INFO] SkipRemote aktif, remote adimi atlandi"
    }

    # 3) demo submodule add (idempotent)
    $demoPath = Join-Path $WorkspacePath 'demo'
    $isSubmodule = $false
    if (Test-Path -LiteralPath (Join-Path $WorkspacePath '.gitmodules') -PathType Leaf) {
        $gitModulesContent = Get-Content -LiteralPath (Join-Path $WorkspacePath '.gitmodules') -Raw
        if ($gitModulesContent -match '(?m)^\s*path\s*=\s*demo\s*$') {
            $isSubmodule = $true
        }
    }

    if ($isSubmodule) {
        Write-Host "[SKIP] demo submodule zaten tanimli"
    }
    else {
        if ((Test-Path -LiteralPath $demoPath -PathType Container) -and (Get-ChildItem -LiteralPath $demoPath -Force | Measure-Object).Count -gt 0) {
            Write-Host "[WARN] demo klasoru dolu; submodule add atlandi"
            Write-Host "[WARN] Demo repo'yu olusturup asagidaki komutu manuel calistirin:"
            Write-Host "       git submodule add $DemoRepoUrl demo"
        }
        else {
            try {
                if (Test-Path -LiteralPath $demoPath -PathType Container) {
                    Remove-Item -LiteralPath $demoPath -Recurse -Force
                }
                Invoke-Git -Args @('submodule', 'add', $DemoRepoUrl, 'demo') -ErrorContext 'git submodule add basarisiz'
                Write-Host "[OK] demo submodule eklendi"
            }
            catch {
                Write-Host "[WARN] demo submodule eklenemedi"
                Write-Host "[WARN] $_"
                Write-Host "[WARN] Demo repo'yu olusturup asagidaki komutu manuel calistirin:"
                Write-Host "       git submodule add $DemoRepoUrl demo"
            }
        }
    }
}
finally {
    Pop-Location
}

exit 0
