#!/usr/bin/env bash
set -euo pipefail

# override: MEKAR_ASSET_BASE_URL=https://other.example.com ./async.sh
BASE_URL="${MEKAR_ASSET_BASE_URL:-https://pub-a7a75b256f2a45ea9e266a6ed801466d.r2.dev}"
ARCHIVE_NAME="assets.tar.gz"
CHECKSUM_NAME="assets.sha256"
LOCK_FILE="assets.lock"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
BASE_URL="${BASE_URL%/}"
ARCHIVE_URL="${BASE_URL}/${ARCHIVE_NAME}"
CHECKSUM_URL="${BASE_URL}/${CHECKSUM_NAME}"
LOCK_PATH="${ROOT}/${LOCK_FILE}"

REMOTE_ETAG=""
REMOTE_SIZE=""
REMOTE_SHA=""

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'; C_GRN=$'\033[32m'; C_YEL=$'\033[33m'; C_RED=$'\033[31m'; C_OFF=$'\033[0m'
else
  C_BOLD=''; C_DIM=''; C_GRN=''; C_YEL=''; C_RED=''; C_OFF=''
fi

title() { printf '%s\n' "${C_BOLD}mekar-assets${C_OFF} ${C_DIM}·${C_OFF} $1"; }
row()   { printf '  %-7s %s\n' "$1" "$2"; }
step()  { printf '  %s%s%s %s\n' "$C_DIM" '›' "$C_OFF" "$1"; }
ok()    { printf '  %s%s%s %s\n' "$C_GRN" '✓' "$C_OFF" "$1"; }
die()   { printf '  %s%s%s %s\n' "$C_RED" '✗' "$C_OFF" "$1" >&2; exit 1; }

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

md5_of() {
  if command -v md5sum >/dev/null 2>&1; then
    md5sum "$1" | awk '{print $1}'
  else
    md5 -q "$1"
  fi
}

human_size() {
  awk -v b="${1:-0}" 'BEGIN {
    if (b >= 1073741824) printf "%.1f GB", b/1073741824;
    else if (b >= 1048576) printf "%.1f MB", b/1048576;
    else if (b >= 1024)    printf "%.0f KB", b/1024;
    else                   printf "%d B", b;
  }'
}

asset_files() {
  find assets -type f ! -name '*.import' ! -name '*.uid' ! -path '*__MACOSX*' 2>/dev/null || true
}

count_files() { asset_files | wc -l | tr -d ' '; }

size_human() { LC_ALL=C du -sh assets 2>/dev/null | awk '{print $1}' || true; }

fetch_headers() {
  local url="$1" out="" i=1
  while [ "$i" -le 3 ]; do
    if out="$(curl -fsSLI --connect-timeout 15 "$url" 2>/dev/null | tr -d '\r')"; then
      printf '%s' "$out"; return 0
    fi
    i=$((i+1))
    if [ "$i" -le 3 ]; then sleep 2; fi
  done
  return 1
}

fetch_file() {
  local url="$1" out="$2" i=1
  LAST_HTTP_CODE=""
  while [ "$i" -le 3 ]; do
    if curl -fL --progress-bar --connect-timeout 15 -w '%{http_code}' -o "$out" "$url" >"${out}.http"; then
      rm -f "${out}.http"; return 0
    fi
    LAST_HTTP_CODE="$(cat "${out}.http" 2>/dev/null)"
    rm -f "${out}.http"
    i=$((i+1))
    if [ "$i" -le 3 ]; then step "retrying ($i/3)..."; sleep 2; fi
  done
  return 1
}

probe_remote() {
  REMOTE_ETAG=""; REMOTE_SIZE=""; REMOTE_SHA=""
  [ -n "$BASE_URL" ] || return 0
  local headers
  headers="$(fetch_headers "$ARCHIVE_URL" || true)"
  REMOTE_SIZE="$(printf '%s\n' "$headers" | awk 'tolower($1)=="content-length:"{print $2}' | tail -1)"
  REMOTE_ETAG="$(printf '%s\n' "$headers" | awk -F'"' 'tolower($1) ~ /^etag:/{print $2; exit}')"
  REMOTE_SHA="$(curl -fsSL --connect-timeout 15 "$CHECKSUM_URL" 2>/dev/null | awk '{print $1; exit}' || true)"
}

remote_rev() {
  if [ -n "$REMOTE_SHA" ]; then printf '%s' "$REMOTE_SHA"; else printf '%s' "$REMOTE_ETAG"; fi
}

short() { printf '%s' "${1:0:7}"; }

read_lock() {
  [ -f "$LOCK_PATH" ] || return 0
  awk -F= '/^rev=/{print $2; exit}' "$LOCK_PATH"
}

write_lock() {
  local rev="$1" files="$2"
  cat > "$LOCK_PATH" <<EOF
rev=${rev}
files=${files}
installed=$(date -u +%Y-%m-%dT%H:%M:%SZ)
url=${BASE_URL}
EOF
}

state_label() {
  local rev="$1" local_rev="$2" files="$3"
  if [ -z "$rev" ]; then
    printf '%s' "${C_YEL}unknown${C_OFF} (remote unreachable)"
  elif [ "$files" -eq 0 ] || [ -z "$local_rev" ]; then
    printf '%s' "${C_YEL}missing${C_OFF} (run sync)"
  elif [ "$rev" = "$local_rev" ]; then
    printf '%s' "${C_GRN}up to date${C_OFF}"
  else
    printf '%s' "${C_YEL}outdated${C_OFF} (run sync)"
  fi
}

print_status() {
  local rev local_rev files
  probe_remote
  rev="$(remote_rev)"; local_rev="$(read_lock)"; files="$(count_files)"

  title "status"; echo
  row "url" "$BASE_URL"
  if [ -n "$rev" ]; then row "remote" "rev $(short "$rev")"; else row "remote" "${C_YEL}unreachable${C_OFF}"; fi
  if [ -n "$local_rev" ]; then
    row "local" "rev $(short "$local_rev")  ${C_DIM}(${files} files)${C_OFF}"
  else
    row "local" "not synced  ${C_DIM}(${files} files)${C_OFF}"
  fi
  row "state" "$(state_label "$rev" "$local_rev" "$files")"
  echo
}

do_sync() {
  local force="${1:-false}" rev local_rev files start elapsed expect algo actual
  probe_remote
  rev="$(remote_rev)"; local_rev="$(read_lock)"; files="$(count_files)"

  title "sync"; echo
  row "url" "$BASE_URL"
  if [ -n "$rev" ]; then row "remote" "rev $(short "$rev")"; else row "remote" "${C_YEL}unreachable${C_OFF}"; fi
  if [ -n "$local_rev" ]; then
    row "local" "rev $(short "$local_rev")  ${C_DIM}(${files} files)${C_OFF}"
  else
    row "local" "not synced  ${C_DIM}(${files} files)${C_OFF}"
  fi

  if [ "$force" != "true" ] && [ -n "$rev" ] && [ "$rev" = "$local_rev" ] && [ "$files" -gt 0 ]; then
    row "state" "${C_GRN}up to date${C_OFF}"
    echo
    return 0
  fi

  row "state" "${C_YEL}updating${C_OFF}"
  echo
  start=$SECONDS

  TMP_FILE="$(mktemp "${TMPDIR:-/tmp}/mekar-assets.XXXXXX.tar.gz")"
  cleanup() { [ -n "${TMP_FILE:-}" ] && rm -f "$TMP_FILE"; return 0; }
  trap cleanup EXIT

  if [ -n "$REMOTE_SIZE" ]; then
    step "downloading ${ARCHIVE_NAME}  ${C_DIM}($(human_size "$REMOTE_SIZE"))${C_OFF}"
  else
    step "downloading ${ARCHIVE_NAME}"
  fi
  fetch_file "$ARCHIVE_URL" "$TMP_FILE" || die "download failed (HTTP ${LAST_HTTP_CODE:-?}) — $ARCHIVE_URL"

  # verify against assets.sha256 if present, else against the R2 ETag (md5)
  step "verifying"
  expect=""; algo=""
  if [ -n "$REMOTE_SHA" ]; then
    expect="$REMOTE_SHA"; algo="sha256"
  elif printf '%s' "$REMOTE_ETAG" | grep -Eq '^[0-9a-fA-F]{32}$'; then
    expect="$(printf '%s' "$REMOTE_ETAG" | tr 'A-F' 'a-f')"; algo="md5"
  fi

  if [ -n "$expect" ]; then
    if [ "$algo" = "sha256" ]; then actual="$(sha256_of "$TMP_FILE")"; else actual="$(md5_of "$TMP_FILE")"; fi
    [ "$actual" = "$expect" ] || die "checksum mismatch (expected $(short "$expect"), got $(short "$actual"))."
    ok "${algo} ok  ${C_DIM}$(short "$actual")${C_OFF}"
  else
    ok "no reference checksum — skipped"
  fi

  step "extracting"
  tar -xzf "$TMP_FILE" -C "$ROOT"
  rm -f "$TMP_FILE"; TMP_FILE=""

  files="$(count_files)"
  [ -n "$rev" ] || rev="$(sha256_of "$LOCK_PATH" 2>/dev/null || true)"
  write_lock "$rev" "$files"

  elapsed=$((SECONDS - start))
  ok "done — ${files} files, $(size_human), ${elapsed}s"
  echo
}

usage() {
  cat <<EOF
${C_BOLD}mekar-assets${C_OFF} — sync game assets from Cloudflare R2

${C_BOLD}Usage${C_OFF}
  ./async.sh            sync assets (default)
  ./async.sh status     show local vs remote state
  ./async.sh update     force re-download
  ./async.sh help       show this help

${C_BOLD}Config${C_OFF}
  Base URL is built in. Override with:
    export MEKAR_ASSET_BASE_URL="https://..."

${C_BOLD}Files${C_OFF}
  assets.lock    local state (last synced revision) — not committed
EOF
}

main() {
  case "$BASE_URL" in
    *example.com*|*xxxx*) die "MEKAR_ASSET_BASE_URL looks like a placeholder: '$BASE_URL'. Unset it or set the real bucket URL." ;;
  esac
  case "${1:-sync}" in
    sync|install|"") do_sync false ;;
    update|pull)     do_sync true  ;;
    status|st)       print_status  ;;
    help|-h|--help)  usage         ;;
    *) die "unknown command: $1 (try: ./async.sh help)" ;;
  esac
}

main "$@"