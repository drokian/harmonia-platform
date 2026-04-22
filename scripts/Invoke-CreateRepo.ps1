#!/usr/bin/env pwsh
#Requires -Version 7.0
<#
.SYNOPSIS
    Local workspace'i GitHub repo akisina bootstrap eder.
.DESCRIPTION
    PowerShell 7 equivalent of create-repo_v0.3.sh.
    Akis:
      - Git init/main branch
      - Initial commit (onay + hassas dosya guard)
      - gh repo create --push
      - develop branch + default branch
      - branch protection (main/develop)
      - squash-only merge
      - copilot auto review (404 -> warn)
.PARAMETER Owner
    GitHub owner/org.
.PARAMETER RepoName
    Repository name.
.PARAMETER Visibility
    public | private
.PARAMETER DryRun
    Yazma islemlerini atlar, sadece planlanan adimlari loglar.
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
    Write-Host $Magenta
    Write-Host "██╗  ██╗ █████╗ ██████╗ ███╗   ███╗ ██████╗ ███╗   ██╗██╗ █████╗"
    Write-Host "██║  ██║██╔══██╗██╔══██╗████╗ ████║██╔═══██╗████╗  ██║██║██╔══██╗"
    Write-Host "███████║███████║██████╔╝██╔████╔██║██║   ██║██╔██╗ ██║██║███████║"
    Write-Host "██╔══██║██╔══██║██╔══██╗██║╚██╔╝██║██║   ██║██║╚██╗██║██║██╔══██║"
    Write-Host "██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║╚██████╔╝██║ ╚████║██║██║  ██║"
    Write-Host "╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝"
    Write-Host ""
    Write-Host "                 H A R M O N I A   C L I"
    Write-Host "         Order - Balance - Structure - Discipline"
    Write-Host $Reset
}

function Invoke-Cmd {
    param(
        [Parameter(Mandatory)][string]$Display,
        [Parameter(Mandatory)][scriptblock]$Action,
        [switch]$ReadOnly
    )

    if ($DryRun -and -not $ReadOnly) {
        Log-Info "[DRY-RUN] Atlandi: $Display"
        return $null
    }

    try {
        return & $Action
    }
    catch {
        Log-Err "Komut basarisiz: $Display"
        throw
    }
}

function Ensure-Tools {
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        throw 'GitHub CLI (gh) bulunamadi.'
    }
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw 'git bulunamadi.'
    }

    Invoke-Cmd -Display 'gh auth status' -ReadOnly -Action {
        & gh auth status *> $null
        if ($LASTEXITCODE -ne 0) {
            throw 'GitHub CLI oturumu acik degil. Once gh auth login calistirin.'
        }
    } | Out-Null
    Log-Ok 'GitHub CLI oturumu dogrulandi'
}

function Ensure-MainBranch {
    $currentBranch = Invoke-Cmd -Display 'git symbolic-ref --short HEAD' -ReadOnly -Action {
        (& git symbolic-ref --quiet --short HEAD 2>$null)
    }

    if ([string]::IsNullOrWhiteSpace(($currentBranch -join ''))) {
        throw 'Aktif branch belirlenemedi. Detached HEAD durumunda islem yapilamaz.'
    }

    $name = ($currentBranch -join '').Trim()
    if ($name -ne 'main') {
        Log-Info "Aktif branch 'main' olarak ayarlaniyor"
        Invoke-Cmd -Display 'git branch -M main' -Action { & git branch -M main } | Out-Null
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
        throw 'Ilk commit kullanici tarafindan iptal edildi.'
    }
}

function Guard-SensitivePaths {
    $sensitive = '(^|/)(\.env(\.|$)|secrets\.|credentials\.)|(\.pem|\.key)$'

    $untracked = Invoke-Cmd -Display 'git ls-files --others --exclude-standard' -ReadOnly -Action {
        & git ls-files --others --exclude-standard
    }
    $staged = Invoke-Cmd -Display 'git diff --cached --name-only' -ReadOnly -Action {
        & git diff --cached --name-only
    }

    $blocked = @($untracked + $staged | Where-Object { $_ -and ($_ -match $sensitive) } | Sort-Object -Unique)
    if ($blocked.Count -gt 0) {
        Log-Err 'Hassas dosya adlari tespit edildi. Ilk commit durduruldu.'
        $blocked | ForEach-Object { Add-Content -Path $logFile -Value "  - $_"; Write-Host "  - $_" }
        throw 'Bu dosyalari guvenli hale getirmeden devam etmeyin.'
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
    } | ConvertTo-Json -Depth 10

    Invoke-Cmd -Display "gh api PUT repos/$Owner/$RepoName/branches/$Branch/protection" -Action {
        $tmp = [System.IO.Path]::GetTempFileName()
        Set-Content -Path $tmp -Value $payload -Encoding utf8
        try {
            & gh api -X PUT "repos/$Owner/$RepoName/branches/$Branch/protection" --input $tmp | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "Branch protection basarisiz: $Branch" }
        }
        finally {
            Remove-Item $tmp -ErrorAction SilentlyContinue
        }
    } | Out-Null

    Log-Ok "$Branch branch korumasi uygulandi"
}

Show-Banner
if ($DryRun) {
    Write-Host "${Yellow}[DRY-RUN] Mod aktif - yazma islemleri atlanacak, yalnizca loglanacak.${Reset}"
}

try {
    Ensure-Tools

    $hasGit = $true
    $skipLocalGitChecks = $false
    & git rev-parse --git-dir *> $null
    if ($LASTEXITCODE -ne 0) {
        $hasGit = $false
    }

    if (-not $hasGit) {
        Log-Info 'Git reposu bulunamadi. Baslatiliyor...'
        Invoke-Cmd -Display 'git init -b main' -Action { & git init -b main | Out-Null } | Out-Null
        Log-Ok 'git init tamamlandi'

        if ($DryRun) {
            # Dry-run modunda git init gercekten calismadigi icin
            # git metadata gerektiren okuma kontrollerini atla.
            $skipLocalGitChecks = $true
            Log-Info '[DRY-RUN] Yerel git metadata kontrolleri atlanacak (repo henuz fiziksel olarak olusmadi).'
        }
    }

    if (-not $skipLocalGitChecks) {
        Ensure-MainBranch

        $hasCommit = $true
        & git log --oneline -1 *> $null
        if ($LASTEXITCODE -ne 0) {
            $hasCommit = $false
        }

        if (-not $hasCommit) {
            Confirm-InitialCommit
            Guard-SensitivePaths
            Log-Info 'Staging ve initial commit yapiliyor...'
            Invoke-Cmd -Display 'git add .' -Action { & git add . } | Out-Null
            Invoke-Cmd -Display 'git commit -m chore: initial commit' -Action { & git commit -m 'chore: initial commit' | Out-Null } | Out-Null
            Log-Ok 'Initial commit atildi'
        }
        else {
            Log-Info 'Mevcut commit gecmisi korunuyor'
        }

        Invoke-Cmd -Display 'git remote get-url origin' -ReadOnly -Action {
            & git remote get-url origin *> $null
            if ($LASTEXITCODE -eq 0) {
                throw "'origin' remote zaten tanimli. Once 'git remote remove origin' calistirin."
            }
        } | Out-Null
    }
    else {
        Log-Info "[DRY-RUN] Atlandi: git symbolic-ref --short HEAD"
        Log-Info "[DRY-RUN] Atlandi: git log --oneline -1"
        Log-Info "[DRY-RUN] Atlandi: git remote get-url origin"
    }

    Log-Info "Repo olusturuluyor: $Owner/$RepoName ($Visibility)"
    Invoke-Cmd -Display "gh repo create $Owner/$RepoName --$Visibility --source=. --push" -Action {
        & gh repo create "$Owner/$RepoName" "--$Visibility" --source=. --push | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'gh repo create basarisiz.' }
    } | Out-Null
    Log-Ok 'Repo olusturuldu ve main push edildi'

    $developExists = $false
    if (-not $skipLocalGitChecks) {
        & git show-ref --verify --quiet refs/heads/develop
        if ($LASTEXITCODE -eq 0) {
            $developExists = $true
        }
    }

    if ($developExists) {
        Log-Warn 'develop branch zaten var, push ediliyor'
        Invoke-Cmd -Display 'git checkout develop' -Action { & git checkout develop | Out-Null } | Out-Null
    }
    else {
        Log-Info 'develop branch olusturuluyor'
        Invoke-Cmd -Display 'git checkout -b develop' -Action { & git checkout -b develop | Out-Null } | Out-Null
    }

    Invoke-Cmd -Display 'git push -u origin develop' -Action { & git push -u origin develop | Out-Null } | Out-Null
    Log-Ok 'develop branch push edildi'

    Invoke-Cmd -Display 'git checkout main' -Action { & git checkout main | Out-Null } | Out-Null
    Log-Info "main branch'e geri donuldu"

    Log-Info 'develop default branch olarak ayarlaniyor'
    Invoke-Cmd -Display "gh api PATCH repos/$Owner/$RepoName -f default_branch=develop" -Action {
        & gh api -X PATCH "repos/$Owner/$RepoName" -f default_branch=develop | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'default_branch ayarlanamadi.' }
    } | Out-Null
    Log-Ok 'develop default branch oldu'

    Apply-BranchProtection -Branch 'main'
    Apply-BranchProtection -Branch 'develop'

    Log-Info 'Merge yontemi squash-only olarak ayarlaniyor'
    Invoke-Cmd -Display "gh api PATCH repos/$Owner/$RepoName squash-only" -Action {
        & gh api -X PATCH "repos/$Owner/$RepoName" -f allow_squash_merge=true -f allow_merge_commit=false -f allow_rebase_merge=false | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Merge yontemi ayarlanamadi.' }
    } | Out-Null
    Log-Ok 'Merge yontemi squash-only'

    Log-Info 'Copilot Auto Review aktif ediliyor'
    if ($DryRun) {
        Log-Info "[DRY-RUN] Atlandi: gh api PUT repos/$Owner/$RepoName/code-review-assistants/copilot"
    }
    else {
        $copilotResp = & gh api -X PUT "repos/$Owner/$RepoName/code-review-assistants/copilot" -f enabled=true 2>&1
        if ($LASTEXITCODE -ne 0) {
            $respText = $copilotResp -join "`n"
            if ($respText -match '"status":\s*"404"' -or $respText -match '\b404\b') {
                Log-Warn 'Copilot Auto Review bu organizasyonda veya repo planinda desteklenmiyor (404)'
            }
            else {
                Log-Err 'Copilot Auto Review aktif edilemedi.'
                $copilotResp | ForEach-Object { Write-Host "[ERROR]   $_" }
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
}
catch {
    Log-Err $_.Exception.Message
    exit 1
}
