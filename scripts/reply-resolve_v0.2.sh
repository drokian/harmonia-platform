#!/usr/bin/env bash
# reply-resolve_v0.2.sh
# ==============================================================================
# HARMONIA REPLY & RESOLVE ENGINE
# ==============================================================================
# Bu script, GitHub Pull Request’lerindeki Copilot yorumlarını otomatik olarak
# yanıtlamak ve ilgili review thread’lerini resolve etmek için tasarlanmış
# deterministik, üretim seviyesinde bir otomasyon aracıdır.
#
# Özellikler:
# ------------------------------------------------------------------------------
# • REST API (comments + reviews)
#     - Copilot tarafından oluşturulan satır bazlı yorumlar (pulls/:number/comments)
#     - Copilot review event’leri (pulls/:number/reviews)
#
# • GraphQL API (reviewThreads)
#     - thread.id (GraphQL node ID)
#     - isResolved durumu
#     - thread içindeki tüm comment node’ları (id, body, path, line)
#
# • Comment → Thread Eşleştirme
#     - REST comment.id (integer) → reply için kullanılır
#     - REST comment.node_id (GraphQL node ID) → thread eşleştirme için kullanılır
#     - GraphQL thread.comments.nodes[].id → node_id eşleşmesi yapılır
#     - Böylece her comment doğru thread ile deterministik olarak eşleşir
#
# • Çok Modlu Reply Sistemi
#     --mode all           : Tüm yorumlara aynı yanıt
#     --mode filter-text   : Belirli metni içeren yorumlara yanıt
#     --mode filter-regex  : Regex ile eşleşen yorumlara yanıt
#     --mode map           : Pattern → reply JSON haritası (deterministik)
#
# • Map Modu Güvenlik Kuralları
#     - Bir comment body’si birden fazla pattern ile eşleşirse script hata verir
#     - Harmonia disiplinine uygun olarak belirsiz davranışa izin verilmez
#
# • Renkli Loglama ve Harmonia Banner
#     - INFO / OK / WARN / ERROR seviyeleri
#     - Tüm loglar PR klasörüne yazılır
#
# • Minimal Bağımlılık
#     - bash
#     - gh (GitHub CLI)
#     - jq
#
# • Dosya Yapısı
#     ai-review/<repo>/PR<numara>/
#         ├── copilot-comments.json
#         ├── review-threads.json
#         ├── harmonia-reply-resolve-YYYYMMDD-HHMMSS.log
#         └── (opsiyonel) reply-map.json / reply.txt
#
# Amaç:
# ------------------------------------------------------------------------------
# Copilot yorumlarını hızlı, güvenli, deterministik ve tekrarlanabilir şekilde
# yanıtlamak ve ilgili review thread’lerini otomatik olarak resolve etmek.
#
# Harmonia İlkeleri:
# ------------------------------------------------------------------------------
# Order     → Belirsiz eşleşme yok, deterministik davranış
# Balance   → REST + GraphQL hibrit mimari
# Structure → Net dosya yapısı, modüler mod sistemi
# Discipline→ Çoklu pattern eşleşmesinde hata, sessiz geçiş yok
#
# Değişiklik Geçmişi:
# ------------------------------------------------------------------------------
# v0.2  - [CHORE] Sürüm geçmişi normalize edildi (ilk yayın v0.1)
#       - [CHORE] Dosya adı/sürüm eşleşmesi v0.2 olarak güncellendi
# v0.1  - İlk yayın
#
# ==============================================================================

set -euo pipefail

if (( BASH_VERSINFO[0] < 4 )); then
  echo "[ERROR] Bu script Bash 4+ gerektirir (assoc array kullanılıyor)."
  echo "[ERROR] macOS varsayılan /bin/bash (3.2) yerine modern bash kullanın."
  exit 1
fi

# ==============================================================================
# --help (en başta)
# ==============================================================================
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat << 'EOF'
Kullanım:
  reply-resolve_v0.2.sh <owner> <repo> <pr_number> --mode <mode> [seçenekler]

Modlar:
  --mode all            : Tüm Copilot comment'lerine aynı reply
      --reply-file <dosya>

  --mode filter-text    : Body içinde metin geçenlere reply
      --filter <metin>
      --reply-file <dosya>

  --mode filter-regex   : Body regex ile eşleşenlere reply
      --regex <pattern>
      --reply-file <dosya>

  --mode map            : Pattern → reply JSON haritası
      --map-file <json>
EOF
  exit 0
fi

# ==============================================================================
# Minimum arg kontrolü
# ==============================================================================
if [[ $# -lt 4 ]]; then
  echo "[ERROR] Eksik parametre. --help ile kullanım bilgisine bakabilirsiniz."
  exit 1
fi

# ==============================================================================
# Arg parse
# ==============================================================================
OWNER="$1"; shift
REPO="$1"; shift
PR_NUMBER="$1"; shift

MODE=""
REPLY_FILE=""
FILTER_TEXT=""
FILTER_REGEX=""
MAP_FILE=""

require_option_value() {
  local option_name="$1"
  local option_value="${2:-}"
  if [[ -z "$option_value" || "$option_value" == --* ]]; then
    echo "[ERROR] ${option_name} icin deger gerekli."
    exit 1
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      require_option_value "--mode" "${2:-}"
      MODE="$2"
      shift 2
      ;;
    --reply-file)
      require_option_value "--reply-file" "${2:-}"
      REPLY_FILE="$2"
      shift 2
      ;;
    --filter)
      require_option_value "--filter" "${2:-}"
      FILTER_TEXT="$2"
      shift 2
      ;;
    --regex)
      require_option_value "--regex" "${2:-}"
      FILTER_REGEX="$2"
      shift 2
      ;;
    --map-file)
      require_option_value "--map-file" "${2:-}"
      MAP_FILE="$2"
      shift 2
      ;;
    *)
      echo "[ERROR] Bilinmeyen argüman: $1"
      exit 1
      ;;
  esac
done

# ==============================================================================
# Mode doğrulaması (arg parse SONRASI)
# ==============================================================================
if [[ -z "$MODE" ]]; then
  echo "[ERROR] --mode zorunlu."
  exit 1
fi

case "$MODE" in
  all)
    if [[ -z "${REPLY_FILE:-}" ]]; then
      echo "[ERROR] --reply-file all modu için zorunlu."
      exit 1
    fi
    ;;
  filter-text)
    if [[ -z "${FILTER_TEXT:-}" ]]; then
      echo "[ERROR] --filter boş olamaz (filter-text modu)."
      exit 1
    fi
    if [[ -z "${REPLY_FILE:-}" ]]; then
      echo "[ERROR] --reply-file filter-text modu için zorunlu."
      exit 1
    fi
    ;;
  filter-regex)
    if [[ -z "${FILTER_REGEX:-}" ]]; then
      echo "[ERROR] --regex boş olamaz (filter-regex modu)."
      exit 1
    fi
    if [[ -z "${REPLY_FILE:-}" ]]; then
      echo "[ERROR] --reply-file filter-regex modu için zorunlu."
      exit 1
    fi
    ;;
  map)
    if [[ -z "${MAP_FILE:-}" ]]; then
      echo "[ERROR] --map-file map modu için zorunlu."
      exit 1
    fi
    ;;
  *)
    echo "[ERROR] Geçersiz mode: $MODE"
    exit 1
    ;;
esac

# ==============================================================================
# Temel doğrulamalar
# ==============================================================================
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

if ! command -v gh >/dev/null 2>&1; then
  echo "[ERROR] gh CLI gerekli."
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "[ERROR] gh auth login gerekli."
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "[ERROR] jq gerekli."
  exit 1
fi

# ==============================================================================
# BASE_DIR + LOG_FILE (doğru sırada)
# ==============================================================================
BASE_DIR="ai-review/${REPO}/PR${PR_NUMBER}"
mkdir -p "$BASE_DIR"

LOG_FILE="${BASE_DIR}/harmonia-reply-resolve-$(date +%Y%m%d-%H%M%S).log"

# ==============================================================================
# Renkler & Log
# ==============================================================================
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

# ==============================================================================
# Banner
# ==============================================================================
show_banner() {
  echo -e "${MAGENTA}"
  cat << 'EOF'
██╗  ██╗ █████╗ ██████╗ ███╗   ███╗ ██████╗ ███╗   ██╗██╗ █████╗
██║  ██║██╔══██╗██╔══██╗████╗ ████║██╔═══██╗████╗  ██║██║██╔══██╗
███████║███████║██████╔╝██╔████╔██║██║   ██║██╔██╗ ██║██║███████║
██╔══██║██╔══██║██╔══██╗██║╚██╔╝██║██║   ██║██║╚██╗██║██║██╔══██║
██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║╚██████╔╝██║ ╚████║██║██║  ██║
╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝

          H A R M O N I A   C O P I L O T   E N G I N E
            Order • Balance • Structure • Discipline
EOF
  echo -e "${RESET}"
}

show_banner

# ==============================================================================
# JSON dosyaları
# ==============================================================================
COMMENTS_JSON="${BASE_DIR}/copilot-comments.json"
THREADS_JSON="${BASE_DIR}/review-threads.json"

if [[ ! -f "$COMMENTS_JSON" || ! -f "$THREADS_JSON" ]]; then
  log_error "Collector çıktıları bulunamadı: $BASE_DIR"
  exit 1
fi

COPILOT_LOGIN="${COPILOT_COMMENTS_LOGIN:-Copilot}"

# ==============================================================================
# Comment → Thread map (node_id bazlı)
# ==============================================================================
log_info "Comment node_id → Thread ID eşleştirme hazırlanıyor..."

declare -A COMMENT_TO_THREAD

THREAD_COUNT=$(jq 'length' "$THREADS_JSON")
for ((i=0; i<THREAD_COUNT; i++)); do
  THREAD_ID=$(jq -r ".[$i].id" "$THREADS_JSON")
  COMMENT_COUNT=$(jq ".[$i].comments.nodes | length" "$THREADS_JSON")
  for ((j=0; j<COMMENT_COUNT; j++)); do
    CID_NODE=$(jq -r ".[$i].comments.nodes[$j].id" "$THREADS_JSON")
    COMMENT_TO_THREAD["$CID_NODE"]="$THREAD_ID"
  done
done

log_success "Eşleştirme tamamlandı."

# ==============================================================================
# Reply seçimi (deterministik)
# ==============================================================================
get_reply_for_comment() {
  local comment_body="$1"

  if [[ "$MODE" == "map" ]]; then
    MATCHES=$(jq -r --arg body "$comment_body" '
      .[] | select(.pattern as $p | $body | test($p)) | .reply
    ' "$MAP_FILE")

    COUNT=$(printf "%s" "$MATCHES" | grep -c '.' || true)

    if [[ "$COUNT" -gt 1 ]]; then
      log_error "Map modunda birden fazla pattern eşleşti!"
      log_error "Comment body: $comment_body"
      log_error "Eşleşen reply sayısı: $COUNT"
      exit 1
    fi

    if [[ "$COUNT" -eq 1 ]]; then
      echo "$MATCHES"
      return
    fi

    echo ""
    return
  fi

  cat "$REPLY_FILE"
}

# ==============================================================================
# Hedef comment seti (id|node_id)
# ==============================================================================
log_info "Copilot comment listesi hazırlanıyor..."

case "$MODE" in
  all)
    COMMENT_PAIRS=$(jq -r --arg login "$COPILOT_LOGIN" '
      .[] | select(.user.login==$login) |
      (.id|tostring) + "|" + .node_id
    ' "$COMMENTS_JSON")
    ;;
  filter-text)
    COMMENT_PAIRS=$(jq -r --arg login "$COPILOT_LOGIN" --arg f "$FILTER_TEXT" '
      .[] | select(.user.login==$login and (.body | contains($f))) |
      (.id|tostring) + "|" + .node_id
    ' "$COMMENTS_JSON")
    ;;
  filter-regex)
    COMMENT_PAIRS=$(jq -r --arg login "$COPILOT_LOGIN" --arg r "$FILTER_REGEX" '
      .[] | select(.user.login==$login and (.body | test($r))) |
      (.id|tostring) + "|" + .node_id
    ' "$COMMENTS_JSON")
    ;;
  map)
    COMMENT_PAIRS=$(jq -r --arg login "$COPILOT_LOGIN" '
      .[] | select(.user.login==$login) |
      (.id|tostring) + "|" + .node_id
    ' "$COMMENTS_JSON")
    ;;
esac

COUNT=$(echo "$COMMENT_PAIRS" | sed '/^$/d' | wc -l | tr -d ' ')
log_info "Hedef Copilot comment sayısı: $COUNT"

if [[ "$COUNT" -eq 0 ]]; then
  log_warn "İşlenecek comment bulunamadı."
  exit 0
fi

# ==============================================================================
# Ana döngü: reply + resolve
# ==============================================================================
while IFS="|" read -r COMMENT_ID COMMENT_NODE_ID; do
  [[ -z "$COMMENT_ID" || -z "$COMMENT_NODE_ID" ]] && continue

  THREAD_ID="${COMMENT_TO_THREAD[$COMMENT_NODE_ID]:-}"
  if [[ -z "$THREAD_ID" ]]; then
    log_warn "Thread bulunamadı → comment_id=$COMMENT_ID node_id=$COMMENT_NODE_ID"
    continue
  fi

  COMMENT_BODY=$(jq -r --arg id "$COMMENT_ID" '
    .[] | select((.id|tostring)==$id) | .body
  ' "$COMMENTS_JSON")

  REPLY_TEXT=$(get_reply_for_comment "$COMMENT_BODY" || true)

  if [[ -z "$REPLY_TEXT" ]]; then
    log_warn "Reply bulunamadı (mode=$MODE) → comment_id=$COMMENT_ID"
    continue
  fi

  log_info "Reply ekleniyor → comment_id=$COMMENT_ID thread_id=$THREAD_ID"

  gh api \
    -X POST \
    "repos/${OWNER}/${REPO}/pulls/${PR_NUMBER}/comments/${COMMENT_ID}/replies" \
    -f body="$REPLY_TEXT" >/dev/null

  log_success "Reply eklendi → $COMMENT_ID"

  gh api graphql \
    -f query="
      mutation {
        resolveReviewThread(input:{threadId:\"${THREAD_ID}\"}) {
          thread { id isResolved }
        }
      }
    " >/dev/null

  log_success "Thread resolve edildi → $THREAD_ID"

done <<< "$COMMENT_PAIRS"

log_success "İşlem tamamlandı."
