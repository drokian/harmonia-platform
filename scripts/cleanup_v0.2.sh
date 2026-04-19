#!/usr/bin/env bash
# cleanup_v0.2.sh
# ==============================================================================
# HARMONIA CLEANUP ENGINE
# ==============================================================================
# Amaç:
#   Bu script, belirli bir repository + PR için üretilen review artefact
#   klasörünü güvenli şekilde temizlemek için kullanılır.
#
# Neden gerekli:
#   Review akışı sonunda `ai-review/<repo>/PR<numara>` altında
#   biriken dosyalar zamanla karmaşa yaratabilir. Bu script, hedef yolu
#   doğrulayarak kontrollü temizlik sağlar.
#
# Özellikler:
#   - Parametre doğrulama (`repo`, `pr_number`)
#   - Güvenli path kontrolü (beklenen prefix doğrulaması)
#   - Hedef dizin varsa silme, yoksa bilgilendirip atlama
#   - Renkli ve okunabilir log çıktıları
#
# Değişiklik Geçmişi:
# ------------------------------------------------------------------------------
# v0.2  - [DOC] Script adı/üst bilgi standardı `HARMONIA ... ENGINE` formatına alındı
#       - [DOC] Amaç/Neden/Özellikler bölümleri eklendi
# v0.1  - İlk yayın
# ==============================================================================

set -euo pipefail

RED="\033[31m"; GREEN="\033[32m"; CYAN="\033[36m"; RESET="\033[0m"

log_info()  { echo -e "${CYAN}[INFO]${RESET}  $1"; }
log_ok()    { echo -e "${GREEN}[OK]${RESET}    $1"; }
log_error() { echo -e "${RED}[ERR]${RESET}   $1"; }

if [[ $# -lt 2 ]]; then
  log_error "Kullanım: $0 <repo> <pr_number>"
  exit 1
fi

REPO="$1"
PR_NUMBER="$2"

if ! [[ "$REPO" =~ ^[A-Za-z0-9._-]+$ ]]; then
  log_error "repo adı dosya yolu için güvenli değil: $REPO"
  exit 1
fi

if ! [[ "$PR_NUMBER" =~ ^[0-9]+$ ]]; then
  log_error "pr_number sayısal olmalı."
  exit 1
fi

BASE_DIR="ai-review/${REPO}/PR${PR_NUMBER}"

EXPECTED_PREFIX="ai-review/${REPO}/PR"
if [[ "$BASE_DIR" != ${EXPECTED_PREFIX}* ]]; then
  log_error "Geçersiz hedef dizin: $BASE_DIR"
  exit 1
fi

if [[ -d "$BASE_DIR" ]]; then
  rm -rf "$BASE_DIR"
  log_ok "Temizlendi: $BASE_DIR"
else
  log_info "Dizin yok, atlanıyor: $BASE_DIR"
fi

