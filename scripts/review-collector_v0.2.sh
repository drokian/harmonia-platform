#!/usr/bin/env bash
# review-collector_v0.2.sh
# ==============================================================================
# HARMONIA REVIEW COLLECTOR ENGINE
# ==============================================================================
# Amaç:
#   Bu script, belirli bir Pull Request için Copilot review verilerini tek yerde
#   toplayarak deterministik analiz ve yanıt akışını besler.
#
# Neden gerekli:
#   Review yorumları REST ve GraphQL kaynaklarına dağılmış durumda olduğu için
#   tekil çağrılarla güvenilir takip zorlaşır. Collector, bu verileri normalize
#   ederek sonraki otomasyon adımları için tutarlı bir temel üretir.
#
# Özellikler:
#   - REST API üzerinden tüm PR review comment ve review event verilerini çekme
#   - GraphQL üzerinden review thread + thread comment verilerini sayfalı toplama
#   - Cursor pagination ile 100+ kayıt senaryolarını eksiksiz işleme
#   - PR klasörüne JSON artefaktları ve Markdown özet üretimi
#   - Copilot odaklı filtreleme için login bazlı ayrıştırma
#
# Değişiklik Geçmişi:
# ------------------------------------------------------------------------------
# v0.2  - [DOC] Script üst bilgisi HARMONIA ... ENGINE formatına geçirildi
#       - [DOC] Amaç/Neden/Özellikler bölümleri detaylandırıldı
#       - [CHORE] Sürüm geçmişi ve dosya adı uyumu güncellendi
# v0.1  - İlk yayın
# ============================================================================== 

set -euo pipefail

# Renkler
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
MAGENTA="\033[35m"
BOLD="\033[1m"
RESET="\033[0m"

log_info()    { echo -e "${CYAN}[INFO]${RESET}    $1"; }
log_success() { echo -e "${GREEN}[OK]${RESET}      $1"; }
log_error()   { echo -e "${RED}[ERROR]${RESET}   $1"; }

banner() {
  echo -e "${MAGENTA}"
  cat << 'EOF'
██╗  ██╗ █████╗ ██████╗ ███╗   ███╗ ██████╗ ███╗   ██╗██╗ █████╗
██║  ██║██╔══██╗██╔══██╗████╗ ████║██╔═══██╗████╗  ██║██║██╔══██╗
███████║███████║██████╔╝██╔████╔██║██║   ██║██╔██╗ ██║██║███████║
██╔══██║██╔══██║██╔══██╗██║╚██╔╝██║██║   ██║██║╚██╗██║██║██╔══██║
██║  ██║██║  ██║██║  ██║██║ ╚═══╝██║╚██████╔╝██║ ╚████║██║██║  ██║
╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝

                 H A R M O N I A   C L I
         Order • Balance • Structure • Discipline
EOF
  echo -e "${RESET}"
}

# Help
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo -e "${BOLD}Kullanım: $0 <owner> <repo> <pr_number>${RESET}"
  exit 0
fi

banner

# Parametreler
if [[ $# -lt 3 ]]; then
  log_error "Eksik: <owner> <repo> <pr_number>"
  exit 1
fi

OWNER="$1"
REPO="$2"
PR_NUMBER="$3"

# Sayısal kontrol
if ! [[ "$PR_NUMBER" =~ ^[0-9]+$ ]]; then
  log_error "pr_number sayısal olmalı."
  exit 1
fi

if ! [[ "$OWNER" =~ ^[A-Za-z0-9-]+$ ]]; then
  log_error "owner değeri güvenli değil: $OWNER"
  exit 1
fi

if ! [[ "$REPO" =~ ^[A-Za-z0-9._-]+$ ]]; then
  log_error "repo adı dosya yolu için güvenli değil: $REPO"
  exit 1
fi

# Araç kontrolleri
for cmd in gh jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log_error "$cmd gerekli."
    exit 1
  fi
done

if ! gh auth status >/dev/null 2>&1; then
  log_error "gh auth login gerekli."
  exit 1
fi

# Output
OUTPUT_DIR="ai-review/${REPO}/PR${PR_NUMBER}"
mkdir -p "$OUTPUT_DIR"

COMMENTS_JSON="${OUTPUT_DIR}/copilot-comments.json"
REVIEWS_JSON="${OUTPUT_DIR}/copilot-reviews.json"
THREADS_JSON="${OUTPUT_DIR}/review-threads.json"
MD_FILE="${OUTPUT_DIR}/copilot-review.md"
COPILOT_COMMENTS_LOGIN="${COPILOT_COMMENTS_LOGIN:-Copilot}"
COPILOT_REVIEWS_LOGIN="${COPILOT_REVIEWS_LOGIN:-copilot-pull-request-reviewer[bot]}"

# REST: comments + reviews
log_info "REST API: comments + reviews alınıyor..."

fetch_all_pages() {
  local endpoint="$1"
  local all="[]"
  local page=1

  while true; do
    local resp
    if ! resp=$(gh api "${endpoint}?per_page=100&page=${page}" 2>/dev/null); then
      log_error "REST API çağrısı başarısız oldu: ${endpoint} (page=${page})"
      exit 1
    fi

    local count
    count=$(echo "$resp" | jq 'length')
    all=$(echo "$all $resp" | jq -s '.[0] + .[1]')
    [[ "$count" -lt 100 ]] && break
    page=$((page+1))
  done

  echo "$all"
}

COMMENTS_RESPONSE=$(fetch_all_pages "repos/${OWNER}/${REPO}/pulls/${PR_NUMBER}/comments")
REVIEWS_RESPONSE=$(fetch_all_pages "repos/${OWNER}/${REPO}/pulls/${PR_NUMBER}/reviews")

echo "$COMMENTS_RESPONSE" > "$COMMENTS_JSON"
echo "$REVIEWS_RESPONSE" > "$REVIEWS_JSON"

log_success "REST API kaydedildi."

# GraphQL: reviewThreads
log_info "GraphQL: review thread'leri alınıyor..."

fetch_thread_comments_pages() {
  local thread_id="$1"
  local cursor="$2"
  local comments_acc
  comments_acc='[]'
  local has_next="true"

  while [[ "$has_next" == "true" ]]; do
    local after_clause=""
    if [[ -n "$cursor" ]]; then
      after_clause=", after: \"${cursor}\""
    fi

    local query
    query=$(cat <<EOF
query {
  node(id: "${thread_id}") {
    ... on PullRequestReviewThread {
      comments(first: 100${after_clause}) {
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
EOF
)

    local resp
    resp=$(gh api graphql -f query="$query" 2>/dev/null || echo '{}')

    local page_nodes
    page_nodes=$(echo "$resp" | jq '.data.node.comments.nodes // []')
    comments_acc=$(jq -s '.[0] + .[1]' <(echo "$comments_acc") <(echo "$page_nodes"))

    has_next=$(echo "$resp" | jq -r '.data.node.comments.pageInfo.hasNextPage // false')
    cursor=$(echo "$resp" | jq -r '.data.node.comments.pageInfo.endCursor // ""')
  done

  echo "$comments_acc"
}

fetch_review_threads() {
  local threads_acc
  threads_acc='[]'
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
EOF
)

    local resp
    resp=$(gh api graphql -f query="$query" 2>/dev/null || echo '{}')

    local page_threads
    page_threads=$(echo "$resp" | jq '.data.repository.pullRequest.reviewThreads.nodes // []')
    local page_count
    page_count=$(echo "$page_threads" | jq 'length')

    if [[ "$page_count" -gt 0 ]]; then
      local idx
      for ((idx=0; idx<page_count; idx++)); do
        local thread
        thread=$(echo "$page_threads" | jq ".[$idx]")

        local thread_id
        thread_id=$(echo "$thread" | jq -r '.id')
        local thread_comments
        thread_comments=$(echo "$thread" | jq '.comments.nodes // []')
        local comments_has_next
        comments_has_next=$(echo "$thread" | jq -r '.comments.pageInfo.hasNextPage // false')
        local comments_cursor
        comments_cursor=$(echo "$thread" | jq -r '.comments.pageInfo.endCursor // ""')

        if [[ "$comments_has_next" == "true" ]]; then
          local more_comments
          more_comments=$(fetch_thread_comments_pages "$thread_id" "$comments_cursor")
          thread_comments=$(jq -s '.[0] + .[1]' <(echo "$thread_comments") <(echo "$more_comments"))
        fi

        local normalized_thread
        normalized_thread=$(jq -n \
          --arg id "$thread_id" \
          --argjson resolved "$(echo "$thread" | jq '.isResolved')" \
          --argjson comments "$thread_comments" \
          '{id: $id, isResolved: $resolved, comments: {nodes: $comments}}')

        threads_acc=$(jq -s '.[0] + [.[1]]' <(echo "$threads_acc") <(echo "$normalized_thread"))
      done
    fi

    has_next=$(echo "$resp" | jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.hasNextPage // false')
    cursor=$(echo "$resp" | jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.endCursor // ""')
  done

  echo "$threads_acc"
}

THREADS_RESPONSE=$(fetch_review_threads)
echo "$THREADS_RESPONSE" > "$THREADS_JSON"

log_success "Thread verileri kaydedildi."

# Markdown raporu
log_info "Markdown raporu üretiliyor..."

{
  echo "# Copilot Review Summary for PR #${PR_NUMBER}"
  echo ""
  echo "Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo ""

  COMMENT_COUNT=$(echo "$COMMENTS_RESPONSE" | jq 'length' 2>/dev/null || echo 0)
  REVIEW_COUNT=$(echo "$REVIEWS_RESPONSE" | jq 'length' 2>/dev/null || echo 0)
  THREAD_COUNT=$(echo "$THREADS_RESPONSE" | jq 'length' 2>/dev/null || echo 0)
  
  echo "**Summary:** Threads: $THREAD_COUNT | Comments: $COMMENT_COUNT | Reviews: $REVIEW_COUNT"
  echo ""

  if [[ $REVIEW_COUNT -gt 0 ]]; then
    echo "## Copilot Reviews"
    echo ""
    jq -r --arg login "$COPILOT_REVIEWS_LOGIN" '
      .[]
      | select(.user.login == $login)
      | "- " + (.state // "UNKNOWN") + " at " + (.submitted_at // "N/A")
    ' <<< "$REVIEWS_RESPONSE" 2>/dev/null || true
    echo ""
  fi

  # Threads
  if [[ $THREAD_COUNT -gt 0 ]]; then
    echo "## Review Threads"
    echo ""
    jq -r '.[] | "- \(.id) (Resolved: \(.isResolved))"' <<< "$THREADS_RESPONSE" 2>/dev/null || true
    echo ""
  fi

  # Comments
  if [[ $COMMENT_COUNT -gt 0 ]]; then
    echo "## Copilot Comments"
    echo ""
    jq -r --arg login "$COPILOT_COMMENTS_LOGIN" '.[] | select(.user.login == $login) | "### \(.path):\(.original_line // .line // 0)\n\n\(.body)\n"' <<< "$COMMENTS_RESPONSE" 2>/dev/null || true
  fi

} > "$MD_FILE"

log_success "Markdown: $MD_FILE"
log_success "Tamamlandı!"

echo ""
echo "📁 Klasör: $OUTPUT_DIR"
ls -lh "$OUTPUT_DIR" | tail -n +2 | awk '{print "   " $9 " (" $5 ")"}'
