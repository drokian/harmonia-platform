#!/usr/bin/env bash
# create-repo.sh
# ==============================================================================
# HARMONIA REPO BOOTSTRAP ENGINE
# ==============================================================================
# Bu script, bir yerel çalışma dizinini GitHub'a bağlar ve standart proje
# yapılandırmalarını tek komutla uygular.
#
# Uygulanan adımlar sırasıyla:
# ------------------------------------------------------------------------------
# • Git Başlatma
#     - Çalışma dizininde git repo yoksa otomatik olarak başlatılır
#     - Aktif branch "main" olarak adlandırılır
#
# • İlk Commit
#     - Hassas dosya varlığı kontrol edilir (.env, *.key, *.pem vb.)
#     - .gitignore'da tanımlı dosyalar tarama dışı bırakılır
#     - Kullanıcıdan onay istenir; onay gelmezse işlem durur
#     - git add . → chore: initial commit
#
# • GitHub Repo Oluşturma
#     - gh repo create --push ile repo açılır ve main push edilir
#
# • Branch Yapısı
#     - develop branch oluşturulur ve push edilir
#     - develop default branch olarak ayarlanır
#
# • Branch Koruma
#     - main ve develop için branch protection kuralları uygulanır
#     - Force push ve deletion engellenir
#
# • Merge Yöntemi
#     - Yalnızca squash merge aktif edilir
#
# • Copilot Auto Review
#     - Repo düzeyinde Copilot Auto Review aktif edilir
#
# Dry-Run Modu (--dry-run / -n):
# ------------------------------------------------------------------------------
# • Tüm yazma işlemleri (git commit, git push, gh api, gh repo create) atlanır
# • Atlanacak komutlar [DRY-RUN] etiketiyle ekrana ve log dosyasına yazılır
# • Okuma ve doğrulama adımları (gh auth, git log, hassas dosya tarama) çalışır
# • Gerçek işlem yapmadan log çıktısını incelemek için kullanılır
#
# Bağımlılıklar:
# ------------------------------------------------------------------------------
# • bash 4+
# • gh (GitHub CLI) — oturum açık olmalı
# • git
#
# Harmonia İlkeleri:
# ------------------------------------------------------------------------------
# Order     → Hassas dosya kontrolü ve kullanıcı onayı olmadan commit yapılmaz
# Balance   → Okuma operasyonları dry-run'da da çalışır, yazma operasyonları atlanır
# Structure → Bootstrap adımları deterministik sırayla uygulanır
# Discipline→ Her kritik adım sonrası başarı/hata logu yazılır
#
# Değişiklik Geçmişi:
# ------------------------------------------------------------------------------
# v0.3  - [FIX] Copilot Auto Review endpoint'i 404 dönerse işlem artık fatal
#           hata yerine uyarı olarak ele alınıyor; organizasyon veya repo planı
#           bu özelliği desteklemese de bootstrap akışı tamamlanabiliyor
# v0.2  - [FIX] guard_sensitive_paths: find yerine git ls-files kullanılıyor;
#           .gitignore'da tanımlı dosyalar artık false positive üretmiyor
#       - [FIX] gh repo create | tee pipe'ında pipefail bypass riski giderildi;
#           gh çıktısı önce dosyaya yönlendiriliyor, PIPESTATUS kontrol ediliyor
#       - [FIX] HAS_GIT_REPO flag mantığı basitleştirildi; git init sonrası
#           ensure_main_branch koşulsuz olarak dry() sarmalayıcısına devrediliyor
#       - [FIX] develop checkout sonrası main'e geri dönülüyor; branch
#           bağlamı deterministik hale getirildi
# v0.1  - İlk yayın
# ==============================================================================

set -euo pipefail

# Renkler
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
CYAN="\033[36m"
BOLD="\033[1m"
RESET="\033[0m"

show_help() {
    echo -e "${BOLD}${CYAN}Kullanım:${RESET}"
    echo -e "  ${YELLOW}./create-repo.sh [--dry-run] <hesap> <repo-adi> <public|private>${RESET}"
    echo

    echo -e "${BOLD}${CYAN}Açıklama:${RESET}"
    echo -e "  Workspace klasörünü GitHub'a bağlar ve standart yapılandırmaları uygular."
    echo -e "  Git reposu yoksa otomatik olarak başlatılır ve ilk commit atılır."
    echo -e "  ${GREEN}main${RESET} ve ${GREEN}develop${RESET} branch'leri olusturulur,"
    echo -e "  ${GREEN}develop${RESET} default yapilir,"
    echo -e "  branch koruma kuralları uygulanır,"
    echo -e "  merge yöntemi ${MAGENTA}squash-only${RESET} yapılır,"
    echo -e "  Copilot Auto Review aktif edilir."
    echo

    echo -e "${BOLD}${CYAN}Seçenekler:${RESET}"
    echo -e "  ${YELLOW}--dry-run, -n${RESET}  Gerçek işlem yapmadan tüm adımları loglar"
    echo

    echo -e "${BOLD}${CYAN}Parametreler:${RESET}"
    echo -e "  ${YELLOW}hesap${RESET}          GitHub hesabi veya organizasyon (orn: ${GREEN}drokian${RESET}, ${GREEN}docyazilim${RESET})"
    echo -e "  ${YELLOW}repo-adi${RESET}       Olusturulacak repo adi (orn: ${GREEN}doc-notes${RESET})"
    echo -e "  ${YELLOW}public|private${RESET} Repo görünürlüğü"
    echo

    echo -e "${BOLD}${CYAN}Ornek:${RESET}"
    echo -e "  ${GREEN}./create-repo.sh docyazilim doc-notes private${RESET}"
    echo -e "  ${GREEN}./create-repo.sh --dry-run docyazilim doc-notes private${RESET}"
    echo
}

DRY_RUN=false

# Help flag kontrolü
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    show_help
    exit 0
fi

# Dry-run flag kontrolü
if [[ "${1:-}" == "--dry-run" || "${1:-}" == "-n" ]]; then
    DRY_RUN=true
    shift
fi

# Parametre kontrolü
if [ $# -ne 3 ]; then
    echo -e "${RED}Hatalı kullanım.${RESET}"
    echo
    show_help
    exit 1
fi

show_banner() {
    echo -e "${MAGENTA}"
    cat << 'EOF'
██╗  ██╗ █████╗ ██████╗ ███╗   ███╗ ██████╗ ███╗   ██╗██╗ █████╗
██║  ██║██╔══██╗██╔══██╗████╗ ████║██╔═══██╗████╗  ██║██║██╔══██╗
███████║███████║██████╔╝██╔████╔██║██║   ██║██╔██╗ ██║██║███████║
██╔══██║██╔══██║██╔══██╗██║╚██╔╝██║██║   ██║██║╚██╗██║██║██╔══██║
██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║╚██████╔╝██║ ╚████║██║██║  ██║
╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝

                 H A R M O N I A   C L I
         Order • Balance • Structure • Discipline
EOF
    echo -e "${RESET}"
}

# Banner (help modunda gösterilmez)
show_banner

if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}[DRY-RUN] Mod aktif — yazma işlemleri atlanacak, yalnızca loglanacak.${RESET}"
fi

ACCOUNT="$1"
REPO="$2"
VISIBILITY="$3"

LOG_FILE="create-repo-$(date +%Y%m%d-%H%M%S).log"

log_info()    { echo -e "${CYAN}[INFO]${RESET}    $1" | tee -a "$LOG_FILE"; }
log_success() { echo -e "${GREEN}[OK]${RESET}      $1" | tee -a "$LOG_FILE"; }
log_warn()    { echo -e "${YELLOW}[WARN]${RESET}    $1" | tee -a "$LOG_FILE"; }
log_error()   { echo -e "${RED}[ERROR]${RESET}   $1" | tee -a "$LOG_FILE"; }

# Dry-run komut sarmalayıcı:
# Dry-run modunda komutu atlar ve loglar; normal modda çalıştırır.
dry() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Atlandı: $*"
        return 0
    fi
    "$@"
}

ensure_main_branch() {
    local current_branch
    current_branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)

    if [[ -z "$current_branch" ]]; then
        log_error "Aktif branch belirlenemedi. Detached HEAD durumunda işlem yapılamaz."
        exit 1
    fi

    if [[ "$current_branch" != "main" ]]; then
        log_info "Aktif branch 'main' olarak ayarlanıyor"
        dry git branch -M main
        log_success "Aktif branch 'main' oldu"
    fi
}

confirm_initial_commit() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Kullanıcı onayı atlandı (dry-run modunda commit yapılmaz)"
        return 0
    fi
    local answer
    echo
    echo -e "${YELLOW}Bu işlem ilk commit'i oluşturacak ve çalışma dizinindeki dosyaları stage edecektir.${RESET}"
    echo -ne "Devam etmek istiyor musunuz? [y/N]: "
    read -r answer

    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        log_error "İlk commit kullanıcı tarafından iptal edildi."
        exit 1
    fi
}

# [FIX v1.3] guard_sensitive_paths: find tabanlı tarama .gitignore'u görmezden
# geldiğinden false positive üretiyordu. Yeni yaklaşım:
#   1. git ls-files --others --exclude-standard   → untracked ama .gitignore'suz dosyalar
#   2. git diff --cached --name-only              → zaten staged olan dosyalar
# Her iki küme de hassas pattern'e karşı kontrol ediliyor.
# Bu sayede .gitignore'da tanımlı .env vb. dosyalar taramayı tetiklemez.
guard_sensitive_paths() {
    local sensitive_pattern='(^|/)(\.env(\.|$)|secrets\.|credentials\.)|(\.pem|\.key)$'
    local blocked_untracked blocked_staged blocked_files

    blocked_untracked=$(git ls-files --others --exclude-standard \
        | grep -E "$sensitive_pattern" || true)

    blocked_staged=$(git diff --cached --name-only \
        | grep -E "$sensitive_pattern" || true)

    blocked_files=$(printf '%s\n%s' "$blocked_untracked" "$blocked_staged" \
        | grep -v '^$' | sort -u || true)

    if [[ -n "$blocked_files" ]]; then
        log_error "Hassas dosya adları tespit edildi. İlk commit durduruldu."
        printf '%s\n' "$blocked_files" | sed 's#^#  - #' | tee -a "$LOG_FILE"
        log_error "Bu dosyaları gözden geçirip güvenli hale getirmeden devam etmeyin."
        exit 1
    fi
}

# Görünürlük doğrulaması
if [[ "$VISIBILITY" != "public" && "$VISIBILITY" != "private" ]]; then
    log_error "Geçersiz görünürlük: '$VISIBILITY'. 'public' veya 'private' olmalı."
    exit 1
fi

# gh auth kontrolü
if ! command -v gh >/dev/null 2>&1; then
    log_error "GitHub CLI bulunamadı. Önce 'gh' kurup PATH'e ekleyin."
    exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
    log_error "GitHub CLI oturumu açık değil. Lütfen önce 'gh auth login' çalıştırın."
    exit 1
fi
log_success "GitHub CLI oturumu doğrulandı"

# [FIX v1.3] HAS_GIT_REPO flag'i kaldırıldı. Önceki tasarımda dry-run'da
# HAS_GIT_REPO=false set edilip else bloğuna giriliyordu; bu blok DRY_RUN
# kontrolü yapmadığından normal modda git repo yokken ensure_main_branch
# atlanabilirdi. Yeni tasarım: ensure_main_branch her zaman dry() üzerinden
# çağrılıyor; git init yoksa zaten set -e script'i durdurur.
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    log_info "Git reposu bulunamadı. Başlatılıyor..."
    dry git init -b main
    log_success "git init tamamlandı"
fi

# ensure_main_branch: dry() sarmalayıcısı içinde zaten no-op olur (dry-run'da
# git branch -M atlanır); ayrı bir flag yönetimine gerek kalmaz.
ensure_main_branch

# İlk commit yoksa oluşturulur
if ! git log --oneline -1 >/dev/null 2>&1; then
    confirm_initial_commit
    guard_sensitive_paths
    log_info "Staging ve initial commit yapılıyor..."
    dry git add .
    dry git commit -m "chore: initial commit"
    log_success "Initial commit atıldı"
else
    log_info "Mevcut commit geçmişi korunuyor"
fi

# Remote zaten tanımlıysa uyar ve dur
if git remote get-url origin >/dev/null 2>&1; then
    log_error "'origin' remote zaten tanımlı. Önce 'git remote remove origin' çalıştırın."
    exit 1
fi

# [FIX v1.3] gh repo create çıktısı doğrudan tee'ye pipe edildiğinde
# set -euo pipefail altında gh hata verse bile tee başarılı döndüğünden
# hata sessizce yutuluyordu. Yeni yaklaşım: stdout+stderr önce log dosyasına
# tee ile yazılır, ardından PIPESTATUS[0] ile gh'nin exit code'u kontrol edilir.
log_info "Repo oluşturuluyor: $ACCOUNT/$REPO ($VISIBILITY)"
if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[DRY-RUN] Atlandı: gh repo create $ACCOUNT/$REPO --$VISIBILITY --source=. --push"
else
    gh repo create "$ACCOUNT/$REPO" \
        --"$VISIBILITY" \
        --source=. \
        --push \
        2>&1 | tee -a "$LOG_FILE"
    # pipefail yeterli değil; gh exit code'unu PIPESTATUS üzerinden doğrula
    if [[ "${PIPESTATUS[0]}" -ne 0 ]]; then
        log_error "gh repo create başarısız oldu. Log dosyasını inceleyin: $LOG_FILE"
        exit 1
    fi
fi
log_success "Repo oluşturuldu ve main push edildi"

# [FIX v1.3] develop branch işlemleri tamamlandıktan sonra main'e geri dönülüyor.
# Önceki tasarımda script develop üzerinde kalıyordu; sonraki adımlarda yanlış
# branch bağlamında işlem yapma riski vardı.
if git show-ref --verify --quiet refs/heads/develop; then
    log_warn "develop branch zaten var, push ediliyor"
    dry git checkout develop
else
    log_info "develop branch oluşturuluyor"
    dry git checkout -b develop
fi
dry git push -u origin develop
log_success "develop branch push edildi"

# develop işi bitti; deterministik branch bağlamı için main'e dön
dry git checkout main
log_info "main branch'e geri dönüldü"

log_info "develop default branch olarak ayarlanıyor"
if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[DRY-RUN] Atlandı: gh api PATCH repos/$ACCOUNT/$REPO -f default_branch=develop"
else
    gh api \
      -X PATCH \
      "repos/$ACCOUNT/$REPO" \
      -f default_branch=develop \
      2>&1 | tee -a "$LOG_FILE"
    if [[ "${PIPESTATUS[0]}" -ne 0 ]]; then
        log_error "default_branch ayarlanamadı. Log dosyasını inceleyin: $LOG_FILE"
        exit 1
    fi
fi
log_success "develop default branch oldu"

apply_branch_protection() {
    local BRANCH="$1"
    local payload
    log_info "$BRANCH branch protection ayarlanıyor"
    payload=$(cat <<EOF
{
    "required_status_checks": null,
    "enforce_admins": true,
    "required_pull_request_reviews": {
        "required_approving_review_count": 0
    },
    "restrictions": null,
    "allow_force_pushes": false,
    "allow_deletions": false,
    "block_creations": false,
    "required_conversation_resolution": false,
    "lock_branch": false,
    "allow_fork_syncing": false
}
EOF
)
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Atlandı: gh api PUT repos/$ACCOUNT/$REPO/branches/$BRANCH/protection"
    else
        gh api \
          -X PUT \
          "repos/$ACCOUNT/$REPO/branches/$BRANCH/protection" \
          --input - \
          <<< "$payload" \
          2>&1 | tee -a "$LOG_FILE"
        if [[ "${PIPESTATUS[0]}" -ne 0 ]]; then
            log_error "$BRANCH branch protection ayarlanamadı. Log: $LOG_FILE"
            exit 1
        fi
    fi
    log_success "$BRANCH branch koruması uygulandı"
}

apply_branch_protection "main"
apply_branch_protection "develop"

log_info "Merge yöntemi squash-only olarak ayarlanıyor"
if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[DRY-RUN] Atlandı: gh api PATCH repos/$ACCOUNT/$REPO squash-only merge"
else
    gh api \
      -X PATCH \
      "repos/$ACCOUNT/$REPO" \
      -f allow_squash_merge=true \
      -f allow_merge_commit=false \
      -f allow_rebase_merge=false \
      2>&1 | tee -a "$LOG_FILE"
    if [[ "${PIPESTATUS[0]}" -ne 0 ]]; then
        log_error "Merge yöntemi ayarlanamadı. Log: $LOG_FILE"
        exit 1
    fi
fi
log_success "Merge yöntemi squash-only"

log_info "Copilot Auto Review aktif ediliyor"
if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[DRY-RUN] Atlandı: gh api PUT repos/$ACCOUNT/$REPO/code-review-assistants/copilot"
else
    response=$(gh api \
      -X PUT \
      "repos/$ACCOUNT/$REPO/code-review-assistants/copilot" \
      -f enabled=true \
      2>&1)
    status=$?
    printf '%s\n' "$response" | tee -a "$LOG_FILE"

    if [[ "$status" -ne 0 ]]; then
        if echo "$response" | grep -q '"status": "404"'; then
            log_warn "Copilot Auto Review bu organizasyonda veya repo planında desteklenmiyor (404)"
        else
            log_error "Copilot Auto Review aktif edilemedi. Log: $LOG_FILE"
            exit 1
        fi
    else
        log_success "Copilot Auto Review aktif"
    fi
fi

log_success "Tüm işlemler başarıyla tamamlandı!"
if [[ "$DRY_RUN" == "true" ]]; then
    log_warn "DRY-RUN modu: Gerçek işlem yapılmadı. Log dosyası: $LOG_FILE"
else
    log_success "Repo hazır: https://github.com/$ACCOUNT/$REPO"
fi