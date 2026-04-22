#!/usr/bin/env pwsh
#Requires -Version 7.0
<#
.SYNOPSIS
    Hedef workspace'te dosya setini olusturur.
.DESCRIPTION
    Kucuk dosyalari here-string ile, yapisal dosyalari file-templates/
    klasorunden okuyup placeholder doldurarak uretir.
    PR-3'te tam implementasyon yapilacaktir.
.PARAMETER TargetPath
    Olusturulacak workspace'in kok dizini.
.PARAMETER WorkspaceName
    Workspace adi; README ve TEMPLATE_IDENTITY.yml icinde kullanilir.
.PARAMETER DemoRepoUrl
    Demo'nun git remote URL'i; Set-GitRepositories'e de iletilir.
.PARAMETER CreatedDate
    Scaffold tarihi (YYYY-MM-DD). Belirtilmezse bugunun tarihi kullanilir.
.PARAMETER ScaffoldMode
    Scaffold modu: guided | auto. TEMPLATE_IDENTITY.yml'e yazilir.
.PARAMETER DryRun
    Gercekte olusturma; yalnizca neyin olusturulacagini listele.
.EXAMPLE
    pwsh scripts/New-FileSet.ps1 -TargetPath "D:\work\my-workspace" -WorkspaceName "my-product" -DemoRepoUrl "https://github.com/org/my-product-demo"
    pwsh scripts/New-FileSet.ps1 -TargetPath "D:\work\my-workspace" -WorkspaceName "my-product" -DemoRepoUrl "https://github.com/org/my-product-demo" -DryRun
#>
param(
    [Parameter(Mandatory)]
    [string]$TargetPath,

    [Parameter(Mandatory)]
    [string]$WorkspaceName,

    [Parameter(Mandatory)]
    [string]$DemoRepoUrl,

    [string]$CreatedDate = (Get-Date -Format 'yyyy-MM-dd'),

    [ValidateSet('guided', 'auto')]
    [string]$ScaffoldMode = 'auto',

    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-GeneratedFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Content
    )

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Write-Host "[SKIP] Dosya zaten var: $Path"
        return
    }

    if ($DryRun) {
        Write-Host "[DRYRUN] Dosya olusturulacak: $Path"
        return
    }

    $parentDir = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parentDir -PathType Container)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }
    if ($Content.Length -eq 0) {
        [System.IO.File]::WriteAllBytes($Path, [byte[]]@())
    }
    else {
        $Content | Out-File -FilePath $Path -Encoding utf8
    }
    Write-Host "[OK] Dosya olusturuldu: $Path"
}

function Get-RelativePathFromRoot {
    param(
        [Parameter(Mandatory)][string]$BasePath,
        [Parameter(Mandatory)][string]$FullPath
    )

    $base = [System.IO.Path]::GetFullPath($BasePath)
    $full = [System.IO.Path]::GetFullPath($FullPath)

    $normalizedBase = $base.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    if (-not $full.StartsWith($normalizedBase, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Path root mismatch. Base: $base | Full: $full"
    }

    return [System.IO.Path]::GetRelativePath($base, $full)
}

Write-Host "New-FileSet" -ForegroundColor Cyan
Write-Host "TargetPath    : $TargetPath"
Write-Host "WorkspaceName : $WorkspaceName"
Write-Host "DemoRepoUrl   : $DemoRepoUrl"
Write-Host "CreatedDate   : $CreatedDate"
Write-Host "ScaffoldMode  : $ScaffoldMode"
Write-Host "DryRun        : $($DryRun.IsPresent)"

$templateRoot = Split-Path -Parent $PSScriptRoot
$fileTemplatesRoot = Join-Path $templateRoot 'file-templates'
$templateManifestPath = Join-Path $templateRoot '.github/template-manifest.yml'
$templateVersionPath = Join-Path $templateRoot 'TEMPLATE_VERSION'
$templateVersion = if (Test-Path -LiteralPath $templateVersionPath -PathType Leaf) {
    (Get-Content -LiteralPath $templateVersionPath -Raw).Trim()
} else { 'v2.0.0' }

if (-not (Test-Path -LiteralPath $fileTemplatesRoot -PathType Container)) {
    throw "file-templates klasoru bulunamadi: $fileTemplatesRoot"
}

$createdBy = ''
try {
    $createdBy = ([string](& git config user.name 2>$null)).Trim()
}
catch {
    $createdBy = ''
}
if ([string]::IsNullOrWhiteSpace($createdBy)) {
    $createdBy = 'unknown'
}

$tokenMap = @{
    '{{WORKSPACE_NAME}}' = $WorkspaceName
    '{{DEMO_REPO_URL}}' = $DemoRepoUrl
    '{{CREATED_DATE}}' = $CreatedDate
    '{{CREATED_BY}}' = $createdBy
    '{{SCAFFOLD_MODE}}' = $ScaffoldMode
}

# Small here-string files
$gitignore = @"
.env
.env.*
!.env.example
secrets.*
*.pem
*.key
credentials.*
backups/**
!backups/README.md
!backups/.gitkeep
!backups/latest.json
"@

$editorconfig = @"
root = true

[\*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
indent_style = space
indent_size = 2
trim_trailing_whitespace = true
"@

$changeLog = @"
# Template Changelog

## $templateVersion - $CreatedDate

- Initial scaffold output.
"@

$secretscanIgnore = @"
# One pattern per line. Known false positives can be listed here.
# Example:
# demo/assets/example-config.js
"@

Write-GeneratedFile -Path (Join-Path $TargetPath '.gitignore') -Content $gitignore
Write-GeneratedFile -Path (Join-Path $TargetPath '.editorconfig') -Content $editorconfig
Write-GeneratedFile -Path (Join-Path $TargetPath 'TEMPLATE_VERSION') -Content $templateVersion
Write-GeneratedFile -Path (Join-Path $TargetPath 'TEMPLATE_CHANGELOG.md') -Content $changeLog
Write-GeneratedFile -Path (Join-Path $TargetPath '.secretscanignore') -Content $secretscanIgnore
Write-GeneratedFile -Path (Join-Path $TargetPath 'backups/.gitkeep') -Content ''
Write-GeneratedFile -Path (Join-Path $TargetPath 'development/sprints/archive/.gitkeep') -Content ''

# Copy template manifest into workspace output
if (Test-Path -LiteralPath $templateManifestPath -PathType Leaf) {
    $manifestContent = Get-Content -LiteralPath $templateManifestPath -Raw
    Write-GeneratedFile -Path (Join-Path $TargetPath '.github/template-manifest.yml') -Content $manifestContent
}

# Copy workflow templates to .github/workflows
$workflowsRoot = Join-Path $fileTemplatesRoot 'workflows'
if (Test-Path -LiteralPath $workflowsRoot -PathType Container) {
    $workflowFiles = Get-ChildItem -LiteralPath $workflowsRoot -File -Filter '*.yml'
    foreach ($wf in $workflowFiles) {
        $wfContent = Get-Content -LiteralPath $wf.FullName -Raw
        Write-GeneratedFile -Path (Join-Path $TargetPath (Join-Path '.github/workflows' $wf.Name)) -Content $wfContent
    }
}

# Copy operational scripts into output scripts/
$operationalScripts = @(
    'Test-TemplateStructure.ps1',
    'Sync-ToDemo.ps1',
    'Update-TemplateVersion.ps1',
    'Test-SecretsInDemo.ps1'
)
foreach ($scriptName in $operationalScripts) {
    $scriptPath = Join-Path $PSScriptRoot $scriptName
    if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
        continue
    }
    $scriptContent = Get-Content -LiteralPath $scriptPath -Raw
    Write-GeneratedFile -Path (Join-Path $TargetPath (Join-Path 'scripts' $scriptName)) -Content $scriptContent
}

# Copy all non-workflow files from file-templates with token replacement
$templateFiles = Get-ChildItem -LiteralPath $fileTemplatesRoot -Recurse -File |
    Where-Object { $_.FullName -notlike "*$([System.IO.Path]::DirectorySeparatorChar)workflows$([System.IO.Path]::DirectorySeparatorChar)*" }

foreach ($templateFile in $templateFiles) {
    $relativePath = Get-RelativePathFromRoot -BasePath $fileTemplatesRoot -FullPath $templateFile.FullName
    $targetFilePath = Join-Path $TargetPath $relativePath

    $content = Get-Content -LiteralPath $templateFile.FullName -Raw
    foreach ($token in $tokenMap.Keys) {
        $content = $content.Replace($token, $tokenMap[$token])
    }

    Write-GeneratedFile -Path $targetFilePath -Content $content
}

Write-Host "[OK] New-FileSet tamamlandi"
exit 0
