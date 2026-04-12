param(
  [ValidateSet("major", "minor", "patch")]
  [string]$Bump = "patch",

  [string]$Version,

  [string]$Date = (Get-Date -Format "yyyy-MM-dd"),

  [switch]$SkipReadmeUpdate,

  [switch]$SkipChangelogEntry
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step {
  param([string]$Message)
  Write-Host "[version-bump] $Message"
}

function Parse-Version {
  param([string]$InputVersion)

  if ($InputVersion -notmatch '^v(\d+)\.(\d+)\.(\d+)$') {
    throw "Version format is invalid: $InputVersion. Expected format: vX.Y.Z"
  }

  return [PSCustomObject]@{
    Major = [int]$Matches[1]
    Minor = [int]$Matches[2]
    Patch = [int]$Matches[3]
  }
}

function To-VersionString {
  param([int]$Major, [int]$Minor, [int]$Patch)
  return "v$Major.$Minor.$Patch"
}

$templateRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$versionFile = Join-Path $templateRoot "TEMPLATE_VERSION"
$changelogFile = Join-Path $templateRoot "TEMPLATE_CHANGELOG.md"
$readmeFile = Join-Path $templateRoot "README.md"

if (-not (Test-Path -LiteralPath $versionFile)) {
  throw "Missing TEMPLATE_VERSION file: $versionFile"
}

$currentVersion = (Get-Content -Path $versionFile -Raw).Trim()
if ([string]::IsNullOrWhiteSpace($currentVersion)) {
  throw "TEMPLATE_VERSION is empty"
}

[void](Parse-Version -InputVersion $currentVersion)

if ($Version) {
  $newVersion = $Version.Trim()
  [void](Parse-Version -InputVersion $newVersion)
}
else {
  $parsed = Parse-Version -InputVersion $currentVersion
  switch ($Bump) {
    "major" {
      $parsed.Major += 1
      $parsed.Minor = 0
      $parsed.Patch = 0
    }
    "minor" {
      $parsed.Minor += 1
      $parsed.Patch = 0
    }
    "patch" {
      $parsed.Patch += 1
    }
  }
  $newVersion = To-VersionString -Major $parsed.Major -Minor $parsed.Minor -Patch $parsed.Patch
}

if ($newVersion -eq $currentVersion) {
  Write-Step "Version is unchanged: $newVersion"
  exit 0
}

Set-Content -Path $versionFile -Value $newVersion -Encoding utf8
Write-Step "Updated TEMPLATE_VERSION: $currentVersion -> $newVersion"

if (-not $SkipReadmeUpdate) {
  if (-not (Test-Path -LiteralPath $readmeFile)) {
    throw "Missing README.md: $readmeFile"
  }

  $readme = Get-Content -Path $readmeFile -Raw
  $updatedReadme = [Regex]::Replace(
    $readme,
    '- Current baseline: `v\d+\.\d+\.\d+`',
    "- Current baseline: ``$newVersion``"
  )

  if ($updatedReadme -eq $readme) {
    throw "Could not update baseline version line in README.md"
  }

  Set-Content -Path $readmeFile -Value $updatedReadme -Encoding utf8
  Write-Step "Updated README baseline line"
}

if (-not $SkipChangelogEntry) {
  if (-not (Test-Path -LiteralPath $changelogFile)) {
    throw "Missing TEMPLATE_CHANGELOG.md: $changelogFile"
  }

  $changelog = Get-Content -Path $changelogFile -Raw
  $entryHeader = "## $newVersion - $Date"

  if ($changelog -match [Regex]::Escape($entryHeader)) {
    Write-Step "Changelog entry already exists: $entryHeader"
  }
  else {
    $entryBlock = @(
      $entryHeader,
      "",
      "- TODO: summarize template changes.",
      ""
    ) -join "`r`n"

    $newContent = [Regex]::Replace(
      $changelog,
      '^# Template Changelog\r?\n\r?\n',
      "# Template Changelog`r`n`r`n$entryBlock",
      [System.Text.RegularExpressions.RegexOptions]::Multiline
    )

    if ($newContent -eq $changelog) {
      $newContent = "# Template Changelog`r`n`r`n$entryBlock$changelog"
    }

    Set-Content -Path $changelogFile -Value $newContent -Encoding utf8
    Write-Step "Inserted changelog entry: $entryHeader"
  }
}

Write-Step "Done"