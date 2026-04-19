#!/usr/bin/env bash
# verify-review-threads_v0.2.sh
# ==============================================================================
# HARMONIA REVIEW THREAD VERIFICATION ENGINE
# ==============================================================================
# Amaç:
#   Bu script, belirli bir Pull Request için review thread durumlarını doğrular.
#   Özellikle "tüm thread'ler resolve edildi mi?" sorusuna deterministic yanıt verir.
#
# Neden gerekli:
#   reply-resolve akışı çalıştıktan sonra geriye açık thread kalıp kalmadığını
#   manuel kontrol etmek zaman alır ve hata riski taşır.
#   Bu script, GraphQL üzerinden tek ve güvenilir bir doğrulama adımı sağlar.
#
# Özellikler:
#   - Harmonia tasarım diline uygun banner ve renkli loglar
#   - Detaylı yardım metni
#   - PR bazlı thread durumu doğrulama
#   - Cursor pagination (100+ thread durumları için eksiksiz çekim)
#   - Markdown + JSON çıktı üretimi
#   - Açık thread varsa non-zero exit code
#
# Çıktı dosyaları:
#   ai-review/<repo>/PR<numara>/
#       ├── review-thread-verification.json
#       ├── review-thread-verification.md
#       └── verify-review-threads-YYYYMMDD-HHMMSS.log
#
# Exit code:
#   0  -> Tüm thread'ler resolve
#   2  -> Açık thread var
#   1  -> Parametre/ortam/API hatası
#
# Değişiklik Geçmişi:
# ------------------------------------------------------------------------------
# v0.2  - [CHORE] Sürüm geçmişi normalize edildi (ilk yayın v0.1)
#       - [CHORE] Dosya adı/sürüm eşleşmesi v0.2 olarak güncellendi
# v0.1  - İlk yayın
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# Renkler ve log yardımcıları
# ------------------------------------------------------------------------------
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
MAGENTA="\033[35m"
BOLD="\033[1m"
RESET="\033[0m"

log_info()    { echo -e "${CYAN}[INFO]${RESET}    $1" | tee -a "$LOG_FILE"; }
log_success() { echo -e "${GREEN}[OK]${RESET}      $1" | tee -a "$LOG_FILE"; }
log_warn()    { echo -e "${YELLOW}[WARN]${RESET}    $1" | tee -a "$LOG_FILE"; }
log_error()   { echo -e "${RED}[ERROR]${RESET}   $1" | tee -a "$LOG_FILE"; }

# ------------------------------------------------------------------------------
# Harmonia Banner
# ------------------------------------------------------------------------------
show_banner() {
  echo -e "${MAGENTA}"
  cat << 'EOF'
██╗  ██╗ █████╗ ██████╗ ███╗   ███╗ ██████╗ ███╗   ██╗██╗ █████╗
██║  ██║██╔══██╗██╔══██╗████╗ ████║██╔═══██╗████╗  ██║██║██╔══██╗
███████║███████║██████╔╝██╔████╔██║██║   ██║██╔██╗ ██║██║███████║
██╔══██║██╔══██║██╔══██╗██║╚██╔╝██║██║   ██║██║╚██╗██║██║██╔══██║
██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║╚██████╔╝██║ ╚████║██║██║  ██║
╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝

    H A R M O N I A   V E R I F I C A T I O N   E N G I N E
           Order • Balance • Structure • Discipline
EOF
  echo -e "${RESET}"
}

# ------------------------------------------------------------------------------
# Yardım metni
# ------------------------------------------------------------------------------
show_help() {
  cat << 'EOF'
Kullanım:
  verify-review-threads_v0.2.sh <owner> <repo> <pr_number> [--show-resolved]

Parametreler:
  owner           Repo sahibi (org veya user)
  repo            Repo adı
  pr_number       Pull Request numarası (sayısal)

Opsiyonlar:
  --show-resolved Resolve edilmiş thread ID'lerini de listele
  --help, -h      Yardım ekranını göster

Ornek:
  bash scripts/verify-review-threads_v0.2.sh \
    docyazilim harmonia-platform-development 4

Not:
  Script varsayılan olarak sadece açık (isResolved=false) thread ID'lerini listeler.
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  show_help
  exit 0
fi

SHOW_RESOLVED="false"

if [[ $# -lt 3 ]]; then
  echo "[ERROR] Eksik parametre. --help ile kullanım bilgisini görün."
  exit 1
fi

OWNER="$1"
REPO="$2"
PR_NUMBER="$3"
shift 3 || true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --show-resolved)
      SHOW_RESOLVED="true"
      shift
      ;;
    --help|-h)
      show_help
      exit 0
      ;;
    *)
      echo "[ERROR] Bilinmeyen argüman: $1"
      exit 1
      ;;
  esac
done

if ! [[ "$PR_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "[ERROR] pr_number sayısal olmalı."
  exit 1
fi

if ! [[ "$OWNER" =~ ^[A-Za-z0-9-]+$ ]]; then
  echo "[ERROR] owner değeri güvenli değil: $OWNER"
  exit 1
fi

if ! [[ "$REPO" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "[ERROR] repo adı dosya yolu için güvenli değil: $REPO"
  exit 1
fi

OUTPUT_DIR="ai-review/${REPO}/PR${PR_NUMBER}"
mkdir -p "$OUTPUT_DIR"

LOG_FILE="${OUTPUT_DIR}/verify-review-threads-$(date +%Y%m%d-%H%M%S).log"
SUMMARY_JSON="${OUTPUT_DIR}/review-thread-verification.json"
SUMMARY_MD="${OUTPUT_DIR}/review-thread-verification.md"

show_banner

# ------------------------------------------------------------------------------
# Ortam kontrolü
# ------------------------------------------------------------------------------
if ! command -v gh >/dev/null 2>&1; then
  log_error "gh CLI bulunamadı. Önce GitHub CLI kurulumunu tamamlayın."
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  log_error "jq bulunamadı. Önce jq kurulumunu tamamlayın."
  exit 1
fi

if ! gh auth status -h github.com >/dev/null 2>&1; then
  log_error "GitHub oturumu aktif değil. Lütfen 'gh auth login' çalıştırın."
  exit 1
fi

log_success "Ortam doğrulaması tamamlandı"

# ------------------------------------------------------------------------------
# GraphQL üzerinden tüm review thread'leri cursor pagination ile çek
# ------------------------------------------------------------------------------
fetch_all_review_threads() {
  local all_threads='[]'
  local has_next="true"
  local cursor=""

  while [[ "$has_next" == "true" ]]; do
    local after_clause=""
    if [[ -n "$cursor" ]]; then
      after_clause=", after: \"${cursor}\""
    fi

    local query
    query=$(cat <<EOF
query {
  repository(owner: "${OWNER}", name: "${REPO}") {
    pullRequest(number: ${PR_NUMBER}) {
      reviewThreads(first: 100${after_clause}) {
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
EOF
)

    local response
    if ! response=$(gh api graphql -f query="$query" 2>/dev/null); then
      log_error "GraphQL çağrısı başarısız oldu."
      exit 1
    fi

    if [[ -z "$response" ]]; then
      log_error "GraphQL yanıtı boş geldi."
      exit 1
    fi

    local gql_errors
    gql_errors=$(echo "$response" | jq '.errors // [] | length')
    if [[ "$gql_errors" -gt 0 ]]; then
      log_error "GraphQL hata döndürdü."
      echo "$response" | jq -r '.errors[]?.message' | sed 's/^/[ERROR]   /' | tee -a "$LOG_FILE"
      exit 1
    fi

    local pr_exists
    pr_exists=$(echo "$response" | jq '.data.repository.pullRequest != null')
    if [[ "$pr_exists" != "true" ]]; then
      log_error "Pull Request bulunamadı veya erişilemiyor (owner/repo/pr_number kontrol edin)."
      exit 1
    fi

    local page_threads
    page_threads=$(echo "$response" | jq '.data.repository.pullRequest.reviewThreads.nodes // []')
    all_threads=$(jq -s '.[0] + .[1]' <(echo "$all_threads") <(echo "$page_threads"))

    has_next=$(echo "$response" | jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.hasNextPage // false')
    cursor=$(echo "$response" | jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.endCursor // ""')
  done

  echo "$all_threads"
}

log_info "PR #${PR_NUMBER} için review thread verileri çekiliyor..."
THREADS_JSON=$(fetch_all_review_threads)

TOTAL_COUNT=$(echo "$THREADS_JSON" | jq 'length')
RESOLVED_COUNT=$(echo "$THREADS_JSON" | jq '[.[] | select(.isResolved==true)] | length')
UNRESOLVED_COUNT=$(echo "$THREADS_JSON" | jq '[.[] | select(.isResolved==false)] | length')

UNRESOLVED_IDS=$(echo "$THREADS_JSON" | jq -r '.[] | select(.isResolved==false) | .id')
RESOLVED_IDS=$(echo "$THREADS_JSON" | jq -r '.[] | select(.isResolved==true) | .id')

# ------------------------------------------------------------------------------
# Makine okunabilir JSON özet
# ------------------------------------------------------------------------------
jq -n \
  --arg owner "$OWNER" \
  --arg repo "$REPO" \
  --arg pr "$PR_NUMBER" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --argjson total "$TOTAL_COUNT" \
  --argjson resolved "$RESOLVED_COUNT" \
  --argjson unresolved "$UNRESOLVED_COUNT" \
  --argjson threads "$THREADS_JSON" \
  '{
    generatedAt: $ts,
    owner: $owner,
    repo: $repo,
    prNumber: ($pr | tonumber),
    summary: {
      totalThreads: $total,
      resolvedThreads: $resolved,
      unresolvedThreads: $unresolved
    },
    threads: $threads
  }' > "$SUMMARY_JSON"

# ------------------------------------------------------------------------------
# İnsan okunabilir Markdown özet
# ------------------------------------------------------------------------------
{
  echo "# Review Thread Verification - PR #${PR_NUMBER}"
  echo ""
  echo "Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo ""
  echo "## Summary"
  echo ""
  echo "- Total: ${TOTAL_COUNT}"
  echo "- Resolved: ${RESOLVED_COUNT}"
  echo "- Unresolved: ${UNRESOLVED_COUNT}"
  echo ""

  echo "## Unresolved Thread IDs"
  echo ""
  if [[ "$UNRESOLVED_COUNT" -eq 0 ]]; then
    echo "- None"
  else
    while IFS= read -r tid; do
      [[ -z "$tid" ]] && continue
      echo "- ${tid}"
    done <<< "$UNRESOLVED_IDS"
  fi

  if [[ "$SHOW_RESOLVED" == "true" ]]; then
    echo ""
    echo "## Resolved Thread IDs"
    echo ""
    if [[ "$RESOLVED_COUNT" -eq 0 ]]; then
      echo "- None"
    else
      while IFS= read -r tid; do
        [[ -z "$tid" ]] && continue
        echo "- ${tid}"
      done <<< "$RESOLVED_IDS"
    fi
  fi
} > "$SUMMARY_MD"

log_success "JSON özet oluşturuldu: $SUMMARY_JSON"
log_success "Markdown özet oluşturuldu: $SUMMARY_MD"

log_info "Toplam thread: $TOTAL_COUNT"
log_info "Resolved: $RESOLVED_COUNT"
log_info "Unresolved: $UNRESOLVED_COUNT"

if [[ "$UNRESOLVED_COUNT" -gt 0 ]]; then
  log_warn "Açık thread bulundu. ID listesi rapora yazıldı."
  exit 2
fi

log_success "Tüm review thread'leri resolve edilmiş durumda."
exit 0
