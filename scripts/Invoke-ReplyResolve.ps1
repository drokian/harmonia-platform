#!/usr/bin/env pwsh
#Requires -Version 7.0
<#
.SYNOPSIS
    Copilot review yorumlarina yanit verir ve ilgili thread'leri resolve eder.
.DESCRIPTION
    PowerShell 7 equivalent of reply-resolve_v0.2.sh.
    Collector tarafindan uretilen `copilot-comments.json` ve `review-threads.json`
    dosyalarini kullanir. Modlar:
    - all
    - filter-text
    - filter-regex
    - map
.NOTES
    Version History:
    - v1.0.0 (2026-04-18): İlk sürüm.
    - v1.1.0 (2026-04-30): [Console]::OutputEncoding UTF-8 zorlandı; gh CLI çağrıları System.Diagnostics.Process tabanlı Invoke-GhProcess sarmalayıcısına taşındı; IBM857 mojibake sorunu giderildi.
.PARAMETER Owner
    GitHub owner (org/user).
.PARAMETER Repo
    Repository adi.
.PARAMETER PrNumber
    PR numarasi.
.PARAMETER Mode
    all | filter-text | filter-regex | map
.PARAMETER ReplyFile
    all/filter-* modlari icin reply metni dosyasi.
.PARAMETER FilterText
    filter-text modu icin metin.
.PARAMETER Regex
    filter-regex modu icin regex.
.PARAMETER MapFile
    map modu icin pattern -> reply JSON dosyasi.
#>
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z0-9-]+$')]
    [string]$Owner,

    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z0-9._-]+$')]
    [ValidateScript({ $_ -notin '.', '..' -and -not $_.Contains('/') -and -not $_.Contains('\\') -and -not $_.Contains('..') })]
    [string]$Repo,

    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9]+$')]
    [string]$PrNumber,

    [Parameter(Mandatory)]
    [ValidateSet('all', 'filter-text', 'filter-regex', 'map')]
    [string]$Mode,

    [string]$ReplyFile = '',
    [string]$FilterText = '',
    [string]$Regex = '',
    [string]$MapFile = ''
)

$ScriptVersion = "v1.1.0"
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# gh CLI UTF-8 çıktısını doğru okumak için konsol encoding'i zorla
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8

$Red
$Green = "`e[32m"
$Yellow = "`e[33m"
$Cyan = "`e[36m"
$Magenta = "`e[35m"
$Reset = "`e[0m"

$baseDir = Join-Path -Path "ai-review/$Repo" -ChildPath "PR$PrNumber"
New-Item -ItemType Directory -Force -Path $baseDir | Out-Null
$logFile = Join-Path $baseDir ("harmonia-reply-resolve-{0}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))

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
    Write-Host "          H A R M O N I A   C O P I L O T   E N G I N E"
    Write-Host "            Order - Balance - Structure - Discipline"
    Write-Host $Reset
}

function Ensure-ModeArguments {
    switch ($Mode) {
        'all' {
            if (-not $ReplyFile) { throw '-ReplyFile all modu icin zorunlu.' }
        }
        'filter-text' {
            if (-not $FilterText) { throw '-FilterText filter-text modu icin zorunlu.' }
            if (-not $ReplyFile) { throw '-ReplyFile filter-text modu icin zorunlu.' }
        }
        'filter-regex' {
            if (-not $Regex) { throw '-Regex filter-regex modu icin zorunlu.' }
            if (-not $ReplyFile) { throw '-ReplyFile filter-regex modu icin zorunlu.' }
        }
        'map' {
            if (-not $MapFile) { throw '-MapFile map modu icin zorunlu.' }
        }
    }
}

function Ensure-Tools {
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        throw 'gh CLI gerekli.'
    }

    & gh auth status *> $null
    if ($LASTEXITCODE -ne 0) {
        throw 'gh auth login gerekli.'
    }
}

function Read-JsonFile([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Collector ciktisi bulunamadi: $Path"
    }

    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -Depth 100
}

function Invoke-GhProcess {
    param([Parameter(Mandatory)][string[]]$Arguments)
    $ghPath = (Get-Command gh -ErrorAction Stop).Source
    $psi = [System.Diagnostics.ProcessStartInfo]::new($ghPath)
    foreach ($arg in $Arguments) { $psi.ArgumentList.Add($arg) }
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.UseShellExecute        = $false
    $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $psi.StandardErrorEncoding  = [System.Text.Encoding]::UTF8
    $proc = [System.Diagnostics.Process]::Start($psi)
    $stdoutTask = $proc.StandardOutput.ReadToEndAsync()
    $stderrTask = $proc.StandardError.ReadToEndAsync()
    $proc.WaitForExit()
    $stdout = $stdoutTask.GetAwaiter().GetResult()
    $stderr = $stderrTask.GetAwaiter().GetResult()
    return [PSCustomObject]@{ ExitCode = $proc.ExitCode; Stdout = $stdout; Stderr = $stderr }
}

function Invoke-Gh {
    param([string[]]$Arguments, [string]$Context)
    $proc = Invoke-GhProcess -Arguments $Arguments
    if ($proc.ExitCode -ne 0) {
        Log-Err "$Context basarisiz."
        $proc.Stderr.Split("`n") | ForEach-Object { Write-Host "[ERROR]   $_" }
        exit 1
    }
    return $proc.Stdout
}

function Get-ReplyForComment([string]$CommentBody, [string]$FallbackReplyText, [object[]]$ReplyMap) {
    if ($Mode -ne 'map') {
        return $FallbackReplyText
    }

    $matches = @($ReplyMap | Where-Object {
        $pattern = [string]$_.pattern
        [regex]::IsMatch($CommentBody, $pattern)
    })

    if ($matches.Count -gt 1) {
        Log-Err 'Map modunda birden fazla pattern eslesti!'
        Log-Err "Comment body: $CommentBody"
        Log-Err "Eslesen reply sayisi: $($matches.Count)"
        exit 1
    }

    if ($matches.Count -eq 1) {
        return [string]$matches[0].reply
    }

    return ''
}

Show-Banner
Ensure-ModeArguments
Ensure-Tools

$commentsJson = Join-Path $baseDir 'copilot-comments.json'
$threadsJson = Join-Path $baseDir 'review-threads.json'
$comments = @((Read-JsonFile -Path $commentsJson))
$threads = @((Read-JsonFile -Path $threadsJson))
$copilotLogin = if ($env:COPILOT_COMMENTS_LOGIN) { $env:COPILOT_COMMENTS_LOGIN } else { 'Copilot' }

$replyText = ''
if ($ReplyFile) {
    if (-not (Test-Path -LiteralPath $ReplyFile -PathType Leaf)) {
        throw "Reply file bulunamadi: $ReplyFile"
    }
    $replyText = Get-Content -LiteralPath $ReplyFile -Raw
}

$replyMap = @()
if ($MapFile) {
    if (-not (Test-Path -LiteralPath $MapFile -PathType Leaf)) {
        throw "Map file bulunamadi: $MapFile"
    }
    $replyMap = @((Get-Content -LiteralPath $MapFile -Raw | ConvertFrom-Json -Depth 50))
}

Log-Info 'Comment node_id -> Thread ID eslestirme hazirlaniyor...'
$commentToThread = @{}
foreach ($thread in $threads) {
    foreach ($commentNode in @($thread.comments.nodes)) {
        $commentToThread[[string]$commentNode.id] = [string]$thread.id
    }
}
Log-Ok 'Eslestirme tamamlandi.'

Log-Info 'Copilot comment listesi hazirlaniyor...'
$commentPairs = @(
switch ($Mode) {
    'all' {
        @($comments | Where-Object { $_.user.login -eq $copilotLogin })
    }
    'filter-text' {
        @($comments | Where-Object { $_.user.login -eq $copilotLogin -and ([string]$_.body).Contains($FilterText) })
    }
    'filter-regex' {
        @($comments | Where-Object { $_.user.login -eq $copilotLogin -and ([regex]::IsMatch([string]$_.body, $Regex)) })
    }
    'map' {
        @($comments | Where-Object { $_.user.login -eq $copilotLogin })
    }
}
)

Log-Info "Hedef Copilot comment sayisi: $($commentPairs.Count)"
if ($commentPairs.Count -eq 0) {
    Log-Warn 'Islenecek comment bulunamadi.'
    exit 0
}

foreach ($comment in $commentPairs) {
    $commentId = [string]$comment.id
    $commentNodeId = [string]$comment.node_id
    $threadId = $commentToThread[$commentNodeId]

    if (-not $threadId) {
        Log-Warn "Thread bulunamadi -> comment_id=$commentId node_id=$commentNodeId"
        continue
    }

    $reply = Get-ReplyForComment -CommentBody ([string]$comment.body) -FallbackReplyText $replyText -ReplyMap $replyMap
    if (-not $reply) {
        Log-Warn "Reply bulunamadi (mode=$Mode) -> comment_id=$commentId"
        continue
    }

    Log-Info "Reply ekleniyor -> comment_id=$commentId thread_id=$threadId"
    Invoke-Gh -Arguments @('api', '-X', 'POST', "repos/$Owner/$Repo/pulls/$PrNumber/comments/$commentId/replies", '-f', "body=$reply") -Context "Reply create ($commentId)" | Out-Null
    Log-Ok "Reply eklendi -> $commentId"

    $threadResolved = @($threads | Where-Object { $_.id -eq $threadId } | Select-Object -ExpandProperty isResolved -First 1)
    if ($threadResolved -eq $true) {
        Log-Info "Thread zaten resolved, resolve adimi atlandi -> $threadId"
        continue
    }

    $mutation = @"
mutation {
  resolveReviewThread(input:{threadId:"$threadId"}) {
    thread { id isResolved }
  }
}
"@
    Invoke-Gh -Arguments @('api', 'graphql', '-f', "query=$mutation") -Context "Resolve thread ($threadId)" | Out-Null
    Log-Ok "Thread resolve edildi -> $threadId"
}

Log-Ok 'Islem tamamlandi.'
