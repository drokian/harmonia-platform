#!/usr/bin/env pwsh
#Requires -Version 7.0
<#
.SYNOPSIS
    Collects Copilot review artifacts for a pull request.
.DESCRIPTION
    PowerShell 7 equivalent of review-collector_v0.2.sh.
    Produces artifacts under ai-review/<owner.repo>/PR-<number>/:
    - copilot-comments.json
    - copilot-reviews.json
    - review-threads.json
    - copilot-review.md
.NOTES
    Version History:
    - v1.0.0 (2026-04-18): İlk sürüm.
    - v1.1.0 (2026-04-20): GraphQL sorguları için güvenli değişken yönetimi (-f/-F) eklendi.
    - v1.2.0 (2026-04-22): API istekleri Start-ThreadJob ile asenkron hale getirildi.
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

$ScriptVersion = "v1.2.0"
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
    $banner = @"
██╗  ██╗ █████╗ ██████╗ ███╗   ███╗ ██████╗ ███╗   ██╗██╗ █████╗
██║  ██║██╔══██╗██╔══██╗████╗ ████║██╔═══██╗████╗  ██║██║██╔══██╗
███████║███████║██████╔╝██╔████╔██║██║   ██║██╔██╗ ██║██║███████║
██╔══██║██╔══██║██╔══██╗██║╚██╔╝██║██║   ██║██║╚██╗██║██║██╔══██║
██║  ██║██║  ██║██║  ██║██║╚═══╝██║╚██████╔╝██║ ╚████║██║██║  ██║
╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝

                 H A R M O N I A   C L I
         Order - Balance - Structure - Discipline
                        $ScriptVersion
"@
    Write-Host $banner -ForegroundColor Magenta
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

    # stdout ve stderr'i ayır
    $stdout = New-Object System.Text.StringBuilder
    $stderr = New-Object System.Text.StringBuilder

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "gh"
    $psi.ArgumentList.AddRange($Arguments)
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi

    $null = $proc.Start()

    # stdout/stderr topla
    while (-not $proc.HasExited) {
        $stdout.Append($proc.StandardOutput.ReadToEnd()) | Out-Null
        $stderr.Append($proc.StandardError.ReadToEnd())  | Out-Null
        Start-Sleep -Milliseconds 10
    }

    # kalan buffer'ları da al
    $stdout.Append($proc.StandardOutput.ReadToEnd()) | Out-Null
    $stderr.Append($proc.StandardError.ReadToEnd())  | Out-Null

    $exit = $proc.ExitCode
    $outStr = $stdout.ToString().Trim()
    $errStr = $stderr.ToString().Trim()

    if ($exit -ne 0) {
        Log-Err "$Context başarısız (exit code: $exit)."
        if ($errStr) {
            $errStr.Split("`n") | ForEach-Object { Write-Host "[ERROR]   $_" }
        }
        exit 1
    }

    # JSON parse
    try {
        return $outStr | ConvertFrom-Json -Depth 100
    }
    catch {
        Log-Err "$Context JSON parse hatası: $($_.Exception.Message)"
        if ($errStr) {
            Write-Host "[ERROR]   gh stderr:"
            $errStr.Split("`n") | ForEach-Object { Write-Host "[ERROR]   $_" }
        }
        Write-Host "[ERROR]   gh stdout:"
        $outStr.Split("`n") | ForEach-Object { Write-Host "[ERROR]   $_" }
        exit 1
    }
}

function Load-GraphQLQuery {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path $Path)) {
        Log-Err "GraphQL dosyası bulunamadı: $Path"
        exit 1
    }

    try {
        return Get-Content -Raw -Path $Path
    }
    catch {
        Log-Err "GraphQL dosyası okunamadı: $Path"
        Log-Err $_.Exception.Message
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
        [Parameter(Mandatory)][string]$Context,
        [Hashtable]$Variables = @{}
    )

    $argsList = @('api', 'graphql', '-f', "query=$Query")
    
    foreach ($key in $Variables.Keys) {
        $value = $Variables[$key]
        # Integer (örn: pr) değerler için -F (raw), stringler için -f kullanılır
        if ($value -is [int]) {
            $argsList += '-F'
            $argsList += "$key=$value"
        } else {
            $argsList += '-f'
            $argsList += "$key=$value"
        }
    }

    $resp = Gh-ApiJson -Arguments $argsList -Context $Context

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

        $queryTemplate = Load-GraphQLQuery -Path "queries/threadComments.graphql"

        $vars = @{ threadId = $ThreadId }
        if (-not [string]::IsNullOrWhiteSpace($cursorLocal)) {
            $vars['after'] = $cursorLocal
        }

        $resp = Invoke-GraphQL -Query $queryTemplate -Context "thread yorumlari ($ThreadId)" -Variables $vars

        $nodes = $resp.data.node.comments.nodes
        if ($nodes) { $comments += $nodes }

        $hasNext = [bool]$resp.data.node.comments.pageInfo.hasNextPage
        $cursorLocal = [string]$resp.data.node.comments.pageInfo.endCursor
    }

    return $comments
}

function Fetch-ReviewThreads {
    param([string]$Owner, [string]$Repo, [int]$PrNumber)
    $threads = @()
    $hasNext = $true
    $cursor = ''

    while ($hasNext) {
        $afterClause = ''
        if (-not [string]::IsNullOrWhiteSpace($cursor)) {
            $afterClause = ", after: `"$cursor`""
        }

        $queryTemplate = Load-GraphQLQuery -Path "queries/reviewThreads.graphql"

        $vars = @{
            owner = $Owner
            repo  = $Repo
            pr    = [int]$PrNumber
        }
        if (-not [string]::IsNullOrWhiteSpace($cursor)) {
            $vars['after'] = $cursor
        }

        $resp = Invoke-GraphQL -Query $queryTemplate -Context 'review thread listesi' -Variables $vars

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

function Safe-CreateDirectory {
    param([Parameter(Mandatory)][string]$Path)

    try {
        if (-not (Test-Path $Path)) {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
        }
    }
    catch {
        Log-Err "Klasör oluşturulamadı: $Path"
        Log-Err $_.Exception.Message
        exit 1
    }
}

function Safe-WriteFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Content
    )

    try {
        $Content | Out-File -FilePath $Path -Encoding utf8
    }
    catch {
        Log-Err "Dosya yazılamadı: $Path"
        Log-Err $_.Exception.Message
        exit 1
    }
}

Show-Banner
# exit # Remove this line to enable script execution
Ensure-Tools

# Deterministik repo anahtarı
$repoKey = "$Owner.$Repo"

# Yeni Harmonia klasör yapısı
$outputDir = Join-Path -Path "ai-review/$repoKey" -ChildPath "pr-$PrNumber"

# Klasörü oluştur
Safe-CreateDirectory -Path $outputDir

$commentsJson = Join-Path $outputDir 'copilot-comments.json'
$reviewsJson  = Join-Path $outputDir 'copilot-reviews.json'
$threadsJson  = Join-Path $outputDir 'review-threads.json'
$mdFile       = Join-Path $outputDir 'copilot-review.md'

$copilotCommentsLogin = if ($env:COPILOT_COMMENTS_LOGIN) { $env:COPILOT_COMMENTS_LOGIN } else { 'Copilot' }
$copilotReviewsLogin = if ($env:COPILOT_REVIEWS_LOGIN) { $env:COPILOT_REVIEWS_LOGIN } else { 'copilot-pull-request-reviewer[bot]' }

Log-Info 'Veriler asenkron (paralel) olarak cekiliyor...'

# Thread'lerin ilgili fonksiyonları tanıyabilmesi için kopyalıyoruz
$initScript = [scriptblock]::Create("
    function Log-Err { ${function:Log-Err} }
    function Gh-ApiJson { ${function:Gh-ApiJson} }
    function Fetch-AllPages { ${function:Fetch-AllPages} }
    function Load-GraphQLQuery { ${function:Load-GraphQLQuery} }
    function Invoke-GraphQL { ${function:Invoke-GraphQL} }
    function Fetch-ThreadCommentsPages { ${function:Fetch-ThreadCommentsPages} }
    function Fetch-ReviewThreads { ${function:Fetch-ReviewThreads} }
")
# İşlemleri paralel başlat ($using: ile global değişkenleri thread'e aktarıyoruz)
$jobComments = Start-ThreadJob -InitializationScript $initScript -ScriptBlock { Fetch-AllPages -Endpoint "repos/$using:Owner/$using:Repo/pulls/$using:PrNumber/comments" }
$jobReviews  = Start-ThreadJob -InitializationScript $initScript -ScriptBlock { Fetch-AllPages -Endpoint "repos/$using:Owner/$using:Repo/pulls/$using:PrNumber/reviews" }
$jobThreads  = Start-ThreadJob -InitializationScript $initScript -ScriptBlock { Fetch-ReviewThreads -Owner $using:Owner -Repo $using:Repo -PrNumber $using:PrNumber }
# Tüm thread'lerin bitmesini bekle ve sonuçları al
$commentsResponse = Receive-Job -Job $jobComments -Wait -AutoRemoveJob
$reviewsResponse  = Receive-Job -Job $jobReviews -Wait -AutoRemoveJob
$threadsResponse  = Receive-Job -Job $jobThreads -Wait -AutoRemoveJob
Log-Ok 'Tüm veriler başarıyla çekildi.'
# ... reviews ve threads json kayıtları ...
$commentsJsonContent = $commentsResponse | ConvertTo-Json -Depth 100
Safe-WriteFile -Path $commentsJson -Content $commentsJsonContent
$reviewsJsonContent = $reviewsResponse | ConvertTo-Json -Depth 100
Safe-WriteFile -Path $reviewsJson -Content $reviewsJsonContent
Log-Ok 'REST API kaydedildi.'
$threadsJsonContent = $threadsResponse | ConvertTo-Json -Depth 100
Safe-WriteFile -Path $threadsJson -Content $threadsJsonContent
Log-Ok 'Thread verileri kaydedildi.'
Log-Info 'Markdown raporu üretiliyor...'
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
    $copilotReviews = @(
        $reviewsResponse |
        Where-Object {
            $_.user.login.ToLower().Contains($copilotReviewsLogin.ToLower())
        }
    )
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
        $first = $t.comments.nodes | Select-Object -First 1

        $path = $first.path
        $line = if ($first.originalLine) { $first.originalLine } elseif ($first.line) { $first.line } else { 0 }

        $body = $first.body
        if ($body.Length -gt 200) {
            $body = $body.Substring(0, 200) + '...'
        }

        $isCopilot = $false
        if ($first.user -and $first.user.login) {
            $login = $first.user.login.ToLower()
            if ($login.Contains($copilotCommentsLogin.ToLower())) {
                $isCopilot = $true
            }
        }

        $md += "### Thread: $($t.id) (Resolved: $($t.isResolved))"
        $md += "- File: ${path}:${line}"
        $md += "- Copilot: $isCopilot"
        $md += "- First Comment:"
        $md += "  $body"
        $md += ""
    }
}

if ($commentCount -gt 0) {
    $md += '## Copilot Comments'
    $md += ''
    $copilotComments = @(
        $commentsResponse |
        Where-Object {
            $_.user.login.ToLower().Contains($copilotCommentsLogin.ToLower())
        }
    )
    foreach ($c in $copilotComments) {
        $line = if ($c.original_line) { $c.original_line } elseif ($c.line) { $c.line } else { 0 }
        $md += "### $($c.path):$line"
        $md += ''
        $md += [string]$c.body
        $md += ''
    }
}

$mdContent = $md -join "`n"
Safe-WriteFile -Path $mdFile -Content $mdContent

Log-Ok "Markdown: $mdFile"
Log-Ok 'Tamamlandi!'
Write-Host ''
Write-Host "📁 Klasor: $outputDir"
Get-ChildItem -Path $outputDir -File | ForEach-Object {
    $size = [math]::Round($_.Length / 1KB, 1)
    Write-Host "   $($_.Name) (${size}K)"
}
