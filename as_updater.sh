#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${MEKAR_ASSET_BASE_URL:-}"
ARCHIVE_NAME="assets.tar.gz"
CHECKSUM_NAME="assets.sha256"
LOCK_FILE="assets.lock"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
BASE_URL="${BASE_URL%/}"
ARCHIVE_URL="${BASE_URL}/${ARCHIVE_NAME}"
CHECKSUM_URL="${BASE_URL}/${CHECKSUM_NAME}"
LOCK_PATH="${ROOT}/${LOCK_FILE}"

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

size_human() {
  LC_ALL=C du -sh assets 2>/dev/null | awk '{print $1}' || true
}

read_lock() {
  [ -f "$LOCK_PATH" ] || return 0
  awk -F= '/^sha256=/{print $2; exit}' "$LOCK_PATH"
}

write_lock() {
  local sha="$1" files="$2"
  cat > "$LOCK_PATH" <<EOF
sha256=${sha}
files=${files}
installed=$(date -u +%Y-%m-%dT%H:%M:%SZ)
url=${BASE_URL}
EOF
}

remote_rev() {
  [ -n "$BASE_URL" ] || return 0
  curl -fsSL --retry 2 --max-time 15 "$CHECKSUM_URL" 2>/dev/null | awk '{print $1; exit}' || true
}

remote_size() {
  [ -n "$BASE_URL" ] || return 0
  curl -fsSLI --retry 2 --max-time 15 "$ARCHIVE_URL" 2>/dev/null \
    | tr -d '\r' | awk 'tolower($1)=="content-length:"{print $2}' | tail -1 || true
}

short() { printf '%s' "${1:0:7}"; }

state_label() {
  local remote="$1" local_sha="$2" files="$3"
  if [ -z "$remote" ]; then
    printf '%s' "${C_YEL}unknown${C_OFF} (remote checksum unavailable)"
  elif [ "$files" -eq 0 ] || [ -z "$local_sha" ]; then
    printf '%s' "${C_YEL}missing${C_OFF} (run sync)"
  elif [ "$remote" = "$local_sha" ]; then
    printf '%s' "${C_GRN}up to date${C_OFF}"
  else
    printf '%s' "${C_YEL}outdated${C_OFF} (run sync)"
  fi
}

print_status() {
  local remote local_sha files
  remote="$(remote_rev)"
  local_sha="$(read_lock)"
  files="$(count_files)"

  title "status"; echo
  row "url" "${BASE_URL:-${C_YEL}<not set>${C_OFF}}"
  if [ -n "$remote" ]; then row "remote" "rev $(short "$remote")"; else row "remote" "${C_YEL}unavailable${C_OFF}"; fi
  if [ -n "$local_sha" ]; then
    row "local" "rev $(short "$local_sha")  ${C_DIM}(${files} files)${C_OFF}"
  else
    row "local" "not synced  ${C_DIM}(${files} files)${C_OFF}"
  fi
  row "state" "$(state_label "$remote" "$local_sha" "$files")"
  echo
}

do_sync() {
  local force="${1:-false}" remote local_sha files start elapsed
  [ -n "$BASE_URL" ] || die "MEKAR_ASSET_BASE_URL is not set. See: ./as_updater.sh help"

  remote="$(remote_rev)"
  local_sha="$(read_lock)"
  files="$(count_files)"

  title "sync"; echo
  if [ -n "$remote" ]; then row "remote" "rev $(short "$remote")"; else row "remote" "${C_YEL}unavailable${C_OFF}"; fi
  if [ -n "$local_sha" ]; then
    row "local" "rev $(short "$local_sha")  ${C_DIM}(${files} files)${C_OFF}"
  else
    row "local" "not synced  ${C_DIM}(${files} files)${C_OFF}"
  fi

  if [ "$force" != "true" ] && [ -n "$remote" ] && [ "$remote" = "$local_sha" ] && [ "$files" -gt 0 ]; then
    row "state" "${C_GRN}up to date${C_OFF}"
    echo
    return 0
  fi

  row "state" "${C_YEL}updating${C_OFF}"
  echo

  start=$SECONDS

  TMP_FILE="$(mktemp "${TMPDIR:-/tmp}/mekar-assets.XXXXXX.tar.gz")"
  cleanup() { [ -n "${TMP_FILE:-}" ] && rm -f "$TMP_FILE"; }
  trap cleanup EXIT

  local rsize
  rsize="$(remote_size)"
  if [ -n "$rsize" ]; then
    step "downloading ${ARCHIVE_NAME}  ${C_DIM}($(human_size "$rsize"))${C_OFF}"
  else
    step "downloading ${ARCHIVE_NAME}"
  fi
  curl -fL --progress-bar --retry 3 --retry-delay 2 -o "$TMP_FILE" "$ARCHIVE_URL" \
    || die "download failed — check MEKAR_ASSET_BASE_URL and that the bucket is public."

  step "verifying checksum"
  local archive_sha
  archive_sha="$(sha256_of "$TMP_FILE")"
  if [ -n "$remote" ] && [ "$archive_sha" != "$remote" ]; then
    die "checksum mismatch (expected $(short "$remote"), got $(short "$archive_sha"))."
  fi
  ok "checksum ok  ${C_DIM}($(short "$archive_sha"))${C_OFF}"

  step "extracting assets"
  tar -xzf "$TMP_FILE" -C "$ROOT"
  rm -f "$TMP_FILE"; TMP_FILE=""

  files="$(count_files)"
  write_lock "$archive_sha" "$files"

  elapsed=$((SECONDS - start))
  ok "done — ${files} files, $(size_human), ${elapsed}s"
  echo
}

usage() {
  cat <<EOF
${C_BOLD}mekar-assets${C_OFF} — sync game assets from Cloudflare R2

${C_BOLD}Usage${C_OFF}
  ./as_updater.sh            sync assets (default)
  ./as_updater.sh status     show local vs remote state
  ./as_updater.sh update     force re-download
  ./as_updater.sh help       show this help

${C_BOLD}Config${C_OFF}
  Set the bucket base URL once:
    export MEKAR_ASSET_BASE_URL="https://assets.example.com"

${C_BOLD}Files${C_OFF}
  assets.lock    local state (last synced revision) — not committed
EOF
}

main() {
  case "${1:-sync}" in
    sync|install|"") do_sync false ;;
    update|pull)     do_sync true  ;;
    status|st)       print_status  ;;
    help|-h|--help)  usage         ;;
    *) die "unknown command: $1 (try: ./as_updater.sh help)" ;;
  esac
}

main "$@"