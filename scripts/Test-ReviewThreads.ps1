#!/usr/bin/env pwsh
#Requires -Version 7.0
<#
.SYNOPSIS
    Belirli bir PR icin review thread durumlarini dogrular.
.DESCRIPTION
    PowerShell 7 equivalent of verify-review-threads_v0.2.sh.
    GraphQL ile tum review thread'leri cursor pagination kullanarak toplar.
    Ciktilar:
    - ai-review/<repo>/PR<number>/review-thread-verification.json
    - ai-review/<repo>/PR<number>/review-thread-verification.md

    Exit code:
    0 -> Tum thread'ler resolved
    2 -> Acik thread var
    1 -> Parametre/ortam/API hatasi
.PARAMETER Owner
    Repo sahibi (org veya user).
.PARAMETER Repo
    Repo adi.
.PARAMETER PrNumber
    Pull Request numarasi.
.PARAMETER ShowResolved
    Resolve edilmis thread ID'lerini de markdown ozete ekler.
#>
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z0-9-]+$')]
    [string]$Owner,

    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z0-9._-]+$')]
    [string]$Repo,

    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9]+$')]
    [string]$PrNumber,

    [switch]$ShowResolved
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Red = "`e[31m"
$Green = "`e[32m"
$Yellow = "`e[33m"
$Cyan = "`e[36m"
$Magenta = "`e[35m"
$Reset = "`e[0m"

$outputDir = Join-Path -Path "ai-review/$Repo" -ChildPath "PR$PrNumber"
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
$logFile = Join-Path $outputDir ("verify-review-threads-{0}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
$summaryJson = Join-Path $outputDir 'review-thread-verification.json'
$summaryMd = Join-Path $outputDir 'review-thread-verification.md'

function Log-Info([string]$Message) {
    $line = "${Cyan}[INFO]${Reset}    $Message"
    Write-Host $line
    Add-Content -Path $logFile -Value $line
}

function Log-Ok([string]$Message) {
    $line = "${Green}[OK]${Reset}      $Message"
    Write-Host $line
    Add-Content -Path $logFile -Value $line
}

function Log-Warn([string]$Message) {
    $line = "${Yellow}[WARN]${Reset}    $Message"
    Write-Host $line
    Add-Content -Path $logFile -Value $line
}

function Log-Err([string]$Message) {
    $line = "${Red}[ERROR]${Reset}   $Message"
    Write-Host $line
    Add-Content -Path $logFile -Value $line
}

function Show-Banner {
    Write-Host $Magenta
    Write-Host "██╗  ██╗ █████╗ ██████╗ ███╗   ███╗ ██████╗ ███╗   ██╗██╗ █████╗"
    Write-Host "██║  ██║██╔══██╗██╔══██╗████╗ ████║██╔═══██╗████╗  ██║██║██╔══██╗"
    Write-Host "███████║███████║██████╔╝██╔████╔██║██║   ██║██╔██╗ ██║██║███████║"
    Write-Host "██╔══██║██╔══██║██╔══██╗██║╚██╔╝██║██║   ██║██║╚██╗██║██║██╔══██║"
    Write-Host "██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║╚██████╔╝██║ ╚████║██║██║  ██║"
    Write-Host "╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝"
    Write-Host ""
    Write-Host "    H A R M O N I A   V E R I F I C A T I O N   E N G I N E"
    Write-Host "           Order - Balance - Structure - Discipline"
    Write-Host $Reset
}

function Ensure-Tools {
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        throw 'gh CLI bulunamadi.'
    }

    & gh auth status *> $null
    if ($LASTEXITCODE -ne 0) {
        throw "GitHub oturumu aktif degil. Once 'gh auth login' calistirin."
    }
}

function Invoke-GhApiJson {
    param([string[]]$Arguments, [string]$Context)
    $result = & gh @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        Log-Err "$Context basarisiz."
        $result | ForEach-Object { Write-Host "[ERROR]   $_" }
        exit 1
    }

    try {
        return ($result -join "`n") | ConvertFrom-Json -Depth 100
    }
    catch {
        Log-Err "$Context JSON parse basarisiz: $($_.Exception.Message)"
        exit 1
    }
}

function Fetch-AllReviewThreads {
    $allThreads = @()
    $hasNext = $true
    $cursor = ''

    while ($hasNext) {
        $afterClause = ''
        if (-not [string]::IsNullOrWhiteSpace($cursor)) {
            $afterClause = ", after: `"$cursor`""
        }

        $query = @"
query {
  repository(owner: "$Owner", name: "$Repo") {
    pullRequest(number: $PrNumber) {
      reviewThreads(first: 100$afterClause) {
        nodes {
          id
          isResolved
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  }
}
"@

        $response = Invoke-GhApiJson -Arguments @('api', 'graphql', '-f', "query=$query") -Context 'GraphQL reviewThreads'

        $hasErrorsProp = $response.PSObject.Properties.Name -contains 'errors'
        if ($hasErrorsProp -and $null -ne $response.errors -and $response.errors.Count -gt 0) {
            Log-Err 'GraphQL hata dondurdu.'
            $response.errors | ForEach-Object { Write-Host "[ERROR]   $($_.message)" }
            exit 1
        }

        $hasData = $response.PSObject.Properties.Name -contains 'data'
        $hasRepo = $hasData -and ($response.data.PSObject.Properties.Name -contains 'repository')
        $hasPr = $hasRepo -and ($response.data.repository.PSObject.Properties.Name -contains 'pullRequest')
        if (-not $hasPr -or $null -eq $response.data.repository.pullRequest) {
            Log-Err 'Pull Request bulunamadi veya erisilemiyor (owner/repo/pr_number kontrol edin).'
            exit 1
        }

        $pageThreads = @($response.data.repository.pullRequest.reviewThreads.nodes)
        if ($pageThreads) { $allThreads += $pageThreads }

        $hasNext = [bool]$response.data.repository.pullRequest.reviewThreads.pageInfo.hasNextPage
        $cursor = [string]$response.data.repository.pullRequest.reviewThreads.pageInfo.endCursor
    }

    return $allThreads
}

Show-Banner
try {
    Ensure-Tools
}
catch {
    Log-Err $_.Exception.Message
    exit 1
}

Log-Ok 'Ortam dogrulamasi tamamlandi'
Log-Info "PR #$PrNumber icin review thread verileri cekiliyor..."
$threads = @(Fetch-AllReviewThreads)

$totalCount = $threads.Count
$resolvedThreads = @($threads | Where-Object { $_.isResolved -eq $true })
$unresolvedThreads = @($threads | Where-Object { $_.isResolved -eq $false })
$resolvedCount = $resolvedThreads.Count
$unresolvedCount = $unresolvedThreads.Count

[pscustomobject]@{
    generatedAt = (Get-Date -AsUTC -Format 'yyyy-MM-ddTHH:mm:ssZ')
    owner = $Owner
    repo = $Repo
    prNumber = [int]$PrNumber
    summary = [pscustomobject]@{
        totalThreads = $totalCount
        resolvedThreads = $resolvedCount
        unresolvedThreads = $unresolvedCount
    }
    threads = $threads
} | ConvertTo-Json -Depth 100 | Out-File -FilePath $summaryJson -Encoding utf8

$md = @()
$md += "# Review Thread Verification - PR #$PrNumber"
$md += ''
$md += "Generated: $(Get-Date -AsUTC -Format 'yyyy-MM-ddTHH:mm:ssZ')"
$md += ''
$md += '## Summary'
$md += ''
$md += "- Total: $totalCount"
$md += "- Resolved: $resolvedCount"
$md += "- Unresolved: $unresolvedCount"
$md += ''
$md += '## Unresolved Thread IDs'
$md += ''
if ($unresolvedCount -eq 0) {
    $md += '- None'
}
else {
    foreach ($thread in $unresolvedThreads) {
        $md += "- $($thread.id)"
    }
}

if ($ShowResolved) {
    $md += ''
    $md += '## Resolved Thread IDs'
    $md += ''
    if ($resolvedCount -eq 0) {
        $md += '- None'
    }
    else {
        foreach ($thread in $resolvedThreads) {
            $md += "- $($thread.id)"
        }
    }
}

$md -join "`n" | Out-File -FilePath $summaryMd -Encoding utf8

Log-Ok "JSON ozet olusturuldu: $summaryJson"
Log-Ok "Markdown ozet olusturuldu: $summaryMd"
Log-Info "Toplam thread: $totalCount"
Log-Info "Resolved: $resolvedCount"
Log-Info "Unresolved: $unresolvedCount"

if ($unresolvedCount -gt 0) {
    Log-Warn 'Acik thread bulundu. ID listesi rapora yazildi.'
    exit 2
}

Log-Ok "Tum review thread'leri resolve edilmis durumda."
exit 0
