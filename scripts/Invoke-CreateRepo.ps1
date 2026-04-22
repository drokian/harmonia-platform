#!/usr/bin/env pwsh
#Requires -Version 7.0
<#
.SYNOPSIS
    Local workspace'i GitHub repo akisina bootstrap eder.
.DESCRIPTION
    PowerShell 7 equivalent of create-repo_v0.3.sh. (Refactored)
.NOTES
    Version History:
    - v1.0.0 (2026-04-18): İlk sürüm.
    - v1.1.0 (2026-04-21): Refactor: Komut çalıştırma ve logging mekanizmaları yeniden yapılandırıldı. Hata yönetimi geliştirildi. Dry-run modu eklendi.
    - v1.1.1 (2026-04-22): Küçük hata düzeltmeleri ve kod temizliği.
.PARAMETER Owner
    GitHub owner/org.
.PARAMETER RepoName
    Repository name.
.PARAMETER Visibility
    public | private
.PARAMETER DryRun
    Yazma işlemlerini atlar, sadece planlanan adımları loglar.
#>
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z0-9-]+$')]
    [string]$Owner,

    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z0-9._-]+$')]
    [string]$RepoName,

    [Parameter(Mandatory)]
    [ValidateSet('public', 'private')]
    [string]$Visibility,

    [switch]$DryRun
)

$ScriptVersion = "v1.1.1"
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Red = "`e[31m"
$Green = "`e[32m"
$Yellow = "`e[33m"
$Cyan = "`e[36m"
$Magenta = "`e[35m"
$Reset = "`e[0m"

$logFile = "create-repo-{0}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss')

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
    $banner = @"
██╗  ██╗ █████╗ ██████╗ ███╗   ███╗ ██████╗ ███╗   ██╗██╗ █████╗
██║  ██║██╔══██╗██╔══██╗████╗ ████║██╔═══██╗████╗  ██║██║██╔══██╗
███████║███████║██████╔╝██╔████╔██║██║   ██║██╔██╗ ██║██║███████║
██╔══██║██╔══██║██╔══██╗██║╚██╔╝██║██║   ██║██║╚██╗██║██║██╔══██║
██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║╚██████╔╝██║ ╚████║██║██║  ██║
╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝

                 H A R M O N I A   C L I
         Order - Balance - Structure - Discipline
                        $ScriptVersion
"@
    Write-Host $banner -ForegroundColor Magenta
}

function Invoke-Cli {
    param(
        [Parameter(Mandatory)][string]$Command,
        [Parameter(Mandatory)][string[]]$Arguments,
        [Parameter(Mandatory)][string]$Context,
        [switch]$ReadOnly,
        [switch]$IgnoreError
    )

    if ($DryRun -and -not $ReadOnly) {
        Log-Info "[DRY-RUN] Atlandi: $Context"
        return $null
    }

    $stdout = New-Object System.Text.StringBuilder
    $stderr = New-Object System.Text.StringBuilder

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $Command
    foreach ($arg in $Arguments) { [void]$psi.ArgumentList.Add($arg) }
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi
    
    try {
        $null = $proc.Start()
        while (-not $proc.HasExited) {
            $stdout.Append($proc.StandardOutput.ReadToEnd()) | Out-Null
            $stderr.Append($proc.StandardError.ReadToEnd())  | Out-Null
            Start-Sleep -Milliseconds 10
        }
        $stdout.Append($proc.StandardOutput.ReadToEnd()) | Out-Null
        $stderr.Append($proc.StandardError.ReadToEnd())  | Out-Null
    }
    catch {
        if (-not $IgnoreError) {
            Log-Err "$Context baslatilamadi: $($_.Exception.Message)"
            exit 1
        }
        return @{ ExitCode = 1; StdOut = ""; StdErr = $_.Exception.Message }
    }

    $exit = $proc.ExitCode
    $outStr = $stdout.ToString().Trim()
    $errStr = $stderr.ToString().Trim()

    if ($exit -ne 0 -and -not $IgnoreError) {
        Log-Err "$Context basarisiz (Exit code: $exit)"
        if ($errStr) { $errStr.Split("`n") | ForEach-Object { Write-Host "[ERROR]   $_" } }
        exit 1
    }

    return @{ ExitCode = $exit; StdOut = $outStr; StdErr = $errStr }
}

function Ensure-Tools {
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        Log-Err 'GitHub CLI (gh) bulunamadi.'
        exit 1
    }
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Log-Err 'git bulunamadi.'
        exit 1
    }

    $res = Invoke-Cli -Command 'gh' -Arguments @('auth', 'status') -Context 'gh auth status' -ReadOnly -IgnoreError
    if ($res.ExitCode -ne 0) {
        Log-Err 'GitHub CLI oturumu acik degil. Once gh auth login calistirin.'
        exit 1
    }
    Log-Ok 'GitHub CLI oturumu dogrulandi'
}

function Ensure-MainBranch {
    $res = Invoke-Cli -Command 'git' -Arguments @('symbolic-ref', '--quiet', '--short', 'HEAD') -Context 'git symbolic-ref' -ReadOnly -IgnoreError
    $currentBranch = $res.StdOut

    if ([string]::IsNullOrWhiteSpace($currentBranch)) {
        Log-Err 'Aktif branch belirlenemedi. Detached HEAD durumunda islem yapilamaz.'
        exit 1
    }

    if ($currentBranch -ne 'main') {
        Log-Info "Aktif branch 'main' olarak ayarlaniyor"
        $null = Invoke-Cli -Command 'git' -Arguments @('branch', '-M', 'main') -Context 'git branch -M main'
        Log-Ok "Aktif branch 'main' oldu"
    }
}

function Confirm-InitialCommit {
    if ($DryRun) {
        Log-Info '[DRY-RUN] Kullanici onayi atlandi (dry-run modunda commit yapilmaz)'
        return
    }

    Write-Host ''
    Write-Host "${Yellow}Bu islem ilk commit'i olusturacak ve calisma dizinindeki dosyalari stage edecektir.${Reset}"
    $answer = Read-Host 'Devam etmek istiyor musunuz? [y/N]'
    if ($answer -notmatch '^[Yy]$') {
        Log-Err 'Ilk commit kullanici tarafindan iptal edildi.'
        exit 1
    }
}

function Guard-SensitivePaths {
    $sensitive = '(^|/)(\.env(\.|$)|secrets\.|credentials\.)|(\.pem|\.key)$'

    $untracked = (Invoke-Cli -Command 'git' -Arguments @('ls-files', '--others', '--exclude-standard') -Context 'untracked files' -ReadOnly).StdOut -split "`n"
    $staged = (Invoke-Cli -Command 'git' -Arguments @('diff', '--cached', '--name-only') -Context 'staged files' -ReadOnly).StdOut -split "`n"

    $blocked = @($untracked + $staged | Where-Object { $_ -and ($_ -match $sensitive) } | Sort-Object -Unique)
    if ($blocked.Count -gt 0) {
        Log-Err 'Hassas dosya adlari tespit edildi. Ilk commit durduruldu.'
        $blocked | ForEach-Object { 
            Add-Content -Path $logFile -Value "  - $_"
            Write-Host "  - $_" 
        }
        Log-Err 'Bu dosyalari guvenli hale getirmeden devam etmeyin.'
        exit 1
    }
}

function Apply-BranchProtection([string]$Branch) {
    Log-Info "$Branch branch protection ayarlaniyor"
    $payload = @{
        required_status_checks = $null
        enforce_admins = $true
        required_pull_request_reviews = @{ required_approving_review_count = 0 }
        restrictions = $null
        allow_force_pushes = $false
        allow_deletions = $false
        block_creations = $false
        required_conversation_resolution = $false
        lock_branch = $false
        allow_fork_syncing = $false
    } | ConvertTo-Json -Depth 10 -Compress

    $tmp = [System.IO.Path]::GetTempFileName()
    Set-Content -Path $tmp -Value $payload -Encoding utf8
    
    try {
        $null = Invoke-Cli -Command 'gh' -Arguments @('api', '-X', 'PUT', "repos/$Owner/$RepoName/branches/$Branch/protection", '--input', $tmp) -Context "branch protection ($Branch)"
        Log-Ok "$Branch branch korumasi uygulandi"
    }
    finally {
        Remove-Item $tmp -ErrorAction SilentlyContinue
    }
}

# --- Main Flow ---
Show-Banner
if ($DryRun) {
    Write-Host "${Yellow}[DRY-RUN] Mod aktif - yazma islemleri atlanacak, yalnizca loglanacak.${Reset}"
}

Ensure-Tools

$hasGit = (Invoke-Cli -Command 'git' -Arguments @('rev-parse', '--git-dir') -Context 'git check' -ReadOnly -IgnoreError).ExitCode -eq 0
$skipLocalGitChecks = $false

if (-not $hasGit) {
    Log-Info 'Git reposu bulunamadi. Baslatiliyor...'
    $null = Invoke-Cli -Command 'git' -Arguments @('init', '-b', 'main') -Context 'git init'
    Log-Ok 'git init tamamlandi'

    if ($DryRun) {
        $skipLocalGitChecks = $true
        Log-Info '[DRY-RUN] Yerel git metadata kontrolleri atlanacak (repo henuz fiziksel olarak olusmadi).'
    }
}

if (-not $skipLocalGitChecks) {
    Ensure-MainBranch

    $hasCommit = (Invoke-Cli -Command 'git' -Arguments @('log', '--oneline', '-1') -Context 'commit check' -ReadOnly -IgnoreError).ExitCode -eq 0

    if (-not $hasCommit) {
        Confirm-InitialCommit
        Guard-SensitivePaths
        Log-Info 'Staging ve initial commit yapiliyor...'
        $null = Invoke-Cli -Command 'git' -Arguments @('add', '.') -Context 'git add'
        $null = Invoke-Cli -Command 'git' -Arguments @('commit', '-m', 'chore: initial commit') -Context 'git commit'
        Log-Ok 'Initial commit atildi'
    }
    else {
        Log-Info 'Mevcut commit gecmisi korunuyor'
    }

    $remoteCheck = Invoke-Cli -Command 'git' -Arguments @('remote', 'get-url', 'origin') -Context 'remote origin check' -ReadOnly -IgnoreError
    if ($remoteCheck.ExitCode -eq 0) {
        Log-Err "'origin' remote zaten tanimli. Once 'git remote remove origin' calistirin."
        exit 1
    }
}

Log-Info "Repo olusturuluyor: $Owner/$RepoName ($Visibility)"
$null = Invoke-Cli -Command 'gh' -Arguments @('repo', 'create', "$Owner/$RepoName", "--$Visibility", '--source=.', '--push') -Context 'gh repo create'
Log-Ok 'Repo olusturuldu ve main push edildi'

$developExists = $false
if (-not $skipLocalGitChecks) {
    $developExists = (Invoke-Cli -Command 'git' -Arguments @('show-ref', '--verify', '--quiet', 'refs/heads/develop') -Context 'develop check' -ReadOnly -IgnoreError).ExitCode -eq 0
}

if ($developExists) {
    Log-Warn 'develop branch zaten var, push ediliyor'
    $null = Invoke-Cli -Command 'git' -Arguments @('checkout', 'develop') -Context 'checkout develop'
}
else {
    Log-Info 'develop branch olusturuluyor'
    $null = Invoke-Cli -Command 'git' -Arguments @('checkout', '-b', 'develop') -Context 'checkout -b develop'
}

$null = Invoke-Cli -Command 'git' -Arguments @('push', '-u', 'origin', 'develop') -Context 'push develop'
Log-Ok 'develop branch push edildi'

$null = Invoke-Cli -Command 'git' -Arguments @('checkout', 'main') -Context 'checkout main'
Log-Info "main branch'e geri donuldu"

Log-Info 'develop default branch olarak ayarlaniyor'
$null = Invoke-Cli -Command 'gh' -Arguments @('api', '-X', 'PATCH', "repos/$Owner/$RepoName", '-f', 'default_branch=develop') -Context 'set default branch'
Log-Ok 'develop default branch oldu'

Apply-BranchProtection -Branch 'main'
Apply-BranchProtection -Branch 'develop'

Log-Info 'Merge yontemi squash-only olarak ayarlaniyor'
$null = Invoke-Cli -Command 'gh' -Arguments @('api', '-X', 'PATCH', "repos/$Owner/$RepoName", '-f', 'allow_squash_merge=true', '-f', 'allow_merge_commit=false', '-f', 'allow_rebase_merge=false') -Context 'set squash-only'
Log-Ok 'Merge yontemi squash-only'

Log-Info 'Copilot Auto Review aktif ediliyor'
if ($DryRun) {
    Log-Info "[DRY-RUN] Atlandi: Copilot Auto Review"
}
else {
    $copilotRes = Invoke-Cli -Command 'gh' -Arguments @('api', '-X', 'PUT', "repos/$Owner/$RepoName/code-review-assistants/copilot", '-f', 'enabled=true') -Context 'copilot setup' -IgnoreError
    if ($copilotRes.ExitCode -ne 0) {
        if ($copilotRes.StdErr -match '404' -or $copilotRes.StdOut -match '404') {
            Log-Warn 'Copilot Auto Review bu organizasyonda veya repo planinda desteklenmiyor (404)'
        }
        else {
            Log-Err 'Copilot Auto Review aktif edilemedi.'
            Write-Host "[ERROR] $($copilotRes.StdErr)"
            exit 1
        }
    }
    else {
        Log-Ok 'Copilot Auto Review aktif'
    }
}

Log-Ok 'Tum islemler basariyla tamamlandi!'
if ($DryRun) {
    Log-Warn "DRY-RUN modu: Gercek islem yapilmadi. Log dosyasi: $logFile"
}
else {
    Log-Ok "Repo hazir: https://github.com/$Owner/$RepoName"
}