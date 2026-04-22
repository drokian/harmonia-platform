#!/usr/bin/env pwsh
#Requires -Version 7.0
<#
.SYNOPSIS
    Collects Copilot review artifacts for a pull request.
.DESCRIPTION
    PowerShell 7 equivalent of review-collector_v0.2.sh.
    Produces artifacts under ai-review/<repo>/PR<number>/:
    - copilot-comments.json
    - copilot-reviews.json
    - review-threads.json
    - copilot-review.md
.PARAMETER Owner
    Repository owner (org/user).
.PARAMETER Repo
    Repository name.
.PARAMETER PrNumber
    Pull request number.
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
    [string]$PrNumber
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Cyan = "`e[36m"
$Green = "`e[32m"
$Red = "`e[31m"
$Magenta = "`e[35m"
$Reset = "`e[0m"

function Log-Info([string]$Message) {
    Write-Host "${Cyan}[INFO]${Reset}    $Message"
}

function Log-Ok([string]$Message) {
    Write-Host "${Green}[OK]${Reset}      $Message"
}

function Log-Err([string]$Message) {
    Write-Host "${Red}[ERROR]${Reset}   $Message"
}

function Show-Banner {
    Write-Host $Magenta
    Write-Host "██╗  ██╗ █████╗ ██████╗ ███╗   ███╗ ██████╗ ███╗   ██╗██╗ █████╗"
    Write-Host "██║  ██║██╔══██╗██╔══██╗████╗ ████║██╔═══██╗████╗  ██║██║██╔══██╗"
    Write-Host "███████║███████║██████╔╝██╔████╔██║██║   ██║██╔██╗ ██║██║███████║"
    Write-Host "██╔══██║██╔══██║██╔══██╗██║╚██╔╝██║██║   ██║██║╚██╗██║██║██╔══██║"
    Write-Host "██║  ██║██║  ██║██║  ██║██║╚═══╝██║╚██████╔╝██║ ╚████║██║██║  ██║"
    Write-Host "╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝"
    Write-Host ""
    Write-Host "                 H A R M O N I A   C L I"
    Write-Host "         Order - Balance - Structure - Discipline"
    Write-Host $Reset
}

function Ensure-Tools {
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        Log-Err "gh gerekli."
        exit 1
    }

    & gh auth status *> $null
    if ($LASTEXITCODE -ne 0) {
        Log-Err "gh auth login gerekli."
        exit 1
    }
}

function Gh-ApiJson {
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments,
        [Parameter(Mandatory)]
        [string]$Context
    )

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

function Fetch-AllPages {
    param([Parameter(Mandatory)][string]$Endpoint)

    $all = @()
    $page = 1

    while ($true) {
        $path = "${Endpoint}?per_page=100&page=$page"
        $resp = Gh-ApiJson -Arguments @('api', $path) -Context "REST API cagrisi ($path)"

        if ($resp -is [System.Array]) {
            $all += $resp
            if ($resp.Count -lt 100) { break }
        }
        else {
            Log-Err "REST API beklenmeyen format dondurdu: $path"
            exit 1
        }

        $page++
    }

    return $all
}

function Invoke-GraphQL {
    param(
        [Parameter(Mandatory)][string]$Query,
        [Parameter(Mandatory)][string]$Context
    )

    $resp = Gh-ApiJson -Arguments @('api', 'graphql', '-f', "query=$Query") -Context $Context

    $hasErrorsProp = $resp.PSObject.Properties.Name -contains 'errors'
    if ($hasErrorsProp -and $null -ne $resp.errors -and $resp.errors.Count -gt 0) {
        Log-Err "GraphQL hata dondu: $Context"
        $resp.errors | ForEach-Object { Write-Host "[ERROR]   $($_.message)" }
        exit 1
    }

    return $resp
}

function Fetch-ThreadCommentsPages {
    param(
        [Parameter(Mandatory)][string]$ThreadId,
        [Parameter(Mandatory)][string]$Cursor
    )

    $comments = @()
    $hasNext = $true
    $cursorLocal = $Cursor

    while ($hasNext) {
        $afterClause = ''
        if (-not [string]::IsNullOrWhiteSpace($cursorLocal)) {
            $afterClause = ", after: `"$cursorLocal`""
        }

        $query = @"
query {
  node(id: "$ThreadId") {
    ... on PullRequestReviewThread {
      comments(first: 100$afterClause) {
        nodes {
          id
          body
          path
          originalLine
          line
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

        $resp = Invoke-GraphQL -Query $query -Context "thread yorumlari ($ThreadId)"
        $nodes = $resp.data.node.comments.nodes
        if ($nodes) { $comments += $nodes }

        $hasNext = [bool]$resp.data.node.comments.pageInfo.hasNextPage
        $cursorLocal = [string]$resp.data.node.comments.pageInfo.endCursor
    }

    return $comments
}

function Fetch-ReviewThreads {
    $threads = @()
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
          comments(first: 100) {
            nodes {
              id
              body
              path
              originalLine
              line
            }
            pageInfo {
              hasNextPage
              endCursor
            }
          }
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

        $resp = Invoke-GraphQL -Query $query -Context 'review thread listesi'

        $hasData = $resp.PSObject.Properties.Name -contains 'data'
        $hasRepo = $hasData -and ($resp.data.PSObject.Properties.Name -contains 'repository')
        $hasPr = $hasRepo -and ($resp.data.repository.PSObject.Properties.Name -contains 'pullRequest')
        if (-not $hasPr -or $null -eq $resp.data.repository.pullRequest) {
            Log-Err "Pull Request bulunamadi veya erisilemiyor (owner/repo/pr_number kontrol edin)."
            exit 1
        }

        $pageThreads = @($resp.data.repository.pullRequest.reviewThreads.nodes)

        foreach ($thread in $pageThreads) {
            $threadComments = @($thread.comments.nodes)
            $commentsHasNext = [bool]$thread.comments.pageInfo.hasNextPage
            $commentsCursor = [string]$thread.comments.pageInfo.endCursor

            if ($commentsHasNext) {
                $more = Fetch-ThreadCommentsPages -ThreadId ([string]$thread.id) -Cursor $commentsCursor
                if ($more) { $threadComments += $more }
            }

            $threads += [PSCustomObject]@{
                id = [string]$thread.id
                isResolved = [bool]$thread.isResolved
                comments = [PSCustomObject]@{ nodes = $threadComments }
            }
        }

        $hasNext = [bool]$resp.data.repository.pullRequest.reviewThreads.pageInfo.hasNextPage
        $cursor = [string]$resp.data.repository.pullRequest.reviewThreads.pageInfo.endCursor
    }

    return $threads
}

Show-Banner
Ensure-Tools

$outputDir = Join-Path -Path "ai-review/$Repo" -ChildPath "PR$PrNumber"
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$commentsJson = Join-Path $outputDir 'copilot-comments.json'
$reviewsJson  = Join-Path $outputDir 'copilot-reviews.json'
$threadsJson  = Join-Path $outputDir 'review-threads.json'
$mdFile       = Join-Path $outputDir 'copilot-review.md'

$copilotCommentsLogin = if ($env:COPILOT_COMMENTS_LOGIN) { $env:COPILOT_COMMENTS_LOGIN } else { 'Copilot' }
$copilotReviewsLogin = if ($env:COPILOT_REVIEWS_LOGIN) { $env:COPILOT_REVIEWS_LOGIN } else { 'copilot-pull-request-reviewer[bot]' }

Log-Info 'REST API: comments + reviews aliniyor...'
$commentsResponse = Fetch-AllPages -Endpoint "repos/$Owner/$Repo/pulls/$PrNumber/comments"
$reviewsResponse = Fetch-AllPages -Endpoint "repos/$Owner/$Repo/pulls/$PrNumber/reviews"

$commentsResponse | ConvertTo-Json -Depth 100 | Out-File -FilePath $commentsJson -Encoding utf8
$reviewsResponse | ConvertTo-Json -Depth 100 | Out-File -FilePath $reviewsJson -Encoding utf8
Log-Ok 'REST API kaydedildi.'

Log-Info "GraphQL: review thread'leri aliniyor..."
$threadsResponse = Fetch-ReviewThreads
$threadsResponse | ConvertTo-Json -Depth 100 | Out-File -FilePath $threadsJson -Encoding utf8
Log-Ok 'Thread verileri kaydedildi.'

Log-Info 'Markdown raporu uretiliyor...'
$commentCount = @($commentsResponse).Count
$reviewCount = @($reviewsResponse).Count
$threadCount = @($threadsResponse).Count

$md = @()
$md += "# Copilot Review Summary for PR #$PrNumber"
$md += ""
$md += "Generated: $(Get-Date -AsUTC -Format 'yyyy-MM-ddTHH:mm:ssZ')"
$md += ""
$md += "**Summary:** Threads: $threadCount | Comments: $commentCount | Reviews: $reviewCount"
$md += ""

if ($reviewCount -gt 0) {
    $md += '## Copilot Reviews'
    $md += ''
    $copilotReviews = @($reviewsResponse | Where-Object { $_.user.login -eq $copilotReviewsLogin })
    if ($copilotReviews.Count -eq 0) {
        $md += '- None'
    }
    else {
        foreach ($r in $copilotReviews) {
            $md += "- $($r.state) at $($r.submitted_at)"
        }
    }
    $md += ''
}

if ($threadCount -gt 0) {
    $md += '## Review Threads'
    $md += ''
    foreach ($t in $threadsResponse) {
        $md += "- $($t.id) (Resolved: $($t.isResolved))"
    }
    $md += ''
}

if ($commentCount -gt 0) {
    $md += '## Copilot Comments'
    $md += ''
    $copilotComments = @($commentsResponse | Where-Object { $_.user.login -eq $copilotCommentsLogin })
    foreach ($c in $copilotComments) {
        $line = if ($c.original_line) { $c.original_line } elseif ($c.line) { $c.line } else { 0 }
        $md += "### $($c.path):$line"
        $md += ''
        $md += [string]$c.body
        $md += ''
    }
}

$md -join "`n" | Out-File -FilePath $mdFile -Encoding utf8

Log-Ok "Markdown: $mdFile"
Log-Ok 'Tamamlandi!'
Write-Host ''
Write-Host "📁 Klasor: $outputDir"
Get-ChildItem -Path $outputDir -File | ForEach-Object {
    $size = [math]::Round($_.Length / 1KB, 1)
    Write-Host "   $($_.Name) (${size}K)"
}
