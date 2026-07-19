#!/usr/bin/env bash
# =============================================================================
# Evalio Design — Android APK build
# Bundles public Supabase env (.env asset) into a release APK you can install
# on a phone. Never ships service-role / PAT secrets.
# =============================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ENV_FILE="${ENV_FILE:-$ROOT_DIR/.env}"
BUILD_MODE="${BUILD_MODE:-release}"   # release | profile | debug
OUTPUT_DIR="${OUTPUT_DIR:-$ROOT_DIR/build/apk_dist}"
STAMP="$(date +%Y%m%d_%H%M%S)"
APK_NAME="evalio-design-${BUILD_MODE}-${STAMP}.apk"

# ── logging ──────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'
  C_DIM=$'\033[2m'
  C_BOLD=$'\033[1m'
  C_BLUE=$'\033[34m'
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
  C_RED=$'\033[31m'
else
  C_RESET=; C_DIM=; C_BOLD=; C_BLUE=; C_GREEN=; C_YELLOW=; C_RED=
fi

log()  { printf '%s[%s]%s %s\n' "$C_BLUE" "$(date '+%H:%M:%S')" "$C_RESET" "$*"; }
ok()   { printf '%s[%s]%s %s\n' "$C_GREEN" "$(date '+%H:%M:%S')" "$C_RESET" "$*"; }
warn() { printf '%s[%s]%s %s\n' "$C_YELLOW" "$(date '+%H:%M:%S')" "$C_RESET" "$*"; }
err()  { printf '%s[%s]%s %s\n' "$C_RED" "$(date '+%H:%M:%S')" "$C_RESET" "$*" >&2; }
die()  { err "$*"; exit 1; }

section() {
  printf '\n%s══ %s ══%s\n' "$C_BOLD" "$*" "$C_RESET"
}

# ── helpers ──────────────────────────────────────────────────────────────────
require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

env_get() {
  local key="$1"
  local file="$2"
  # shellcheck disable=SC2002
  grep -E "^${key}=" "$file" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '\r' || true
}

env_has_key() {
  local key="$1"
  local file="$2"
  grep -Eq "^${key}=.+" "$file" 2>/dev/null
}

# ── banner ───────────────────────────────────────────────────────────────────
section "Evalio Design APK build"
log "Project:  $ROOT_DIR"
log "Env file: $ENV_FILE"
log "Mode:     $BUILD_MODE"
log "Output:   $OUTPUT_DIR/$APK_NAME"

# ── preflight ────────────────────────────────────────────────────────────────
section "Preflight checks"
require_cmd flutter
require_cmd java

log "Flutter: $(flutter --version 2>/dev/null | head -1)"
log "Java:    $(java -version 2>&1 | head -1)"

[[ -f "$ENV_FILE" ]] || die "Env file not found: $ENV_FILE
Create it from .env.example:
  cp .env.example .env
  # then set NEXT_PUBLIC_SUPABASE_URL and SUPABASE_ANON_KEY"

# Ensure the file Flutter assets load is present at repo root as .env
if [[ "$ENV_FILE" != "$ROOT_DIR/.env" ]]; then
  log "Copying $ENV_FILE → $ROOT_DIR/.env (Flutter asset path)"
  cp "$ENV_FILE" "$ROOT_DIR/.env"
fi

# ── validate public env (required for mobile) ────────────────────────────────
section "Validate Supabase client env"
REQUIRED_KEYS=(NEXT_PUBLIC_SUPABASE_URL SUPABASE_ANON_KEY)
for key in "${REQUIRED_KEYS[@]}"; do
  if ! env_has_key "$key" "$ROOT_DIR/.env"; then
    die "Missing or empty $key in .env — APK would not connect to Supabase"
  fi
  value="$(env_get "$key" "$ROOT_DIR/.env")"
  # Mask value in logs
  if [[ ${#value} -gt 12 ]]; then
    masked="${value:0:8}…${value: -4}"
  else
    masked="(set)"
  fi
  ok "$key = $masked"
done

URL="$(env_get NEXT_PUBLIC_SUPABASE_URL "$ROOT_DIR/.env")"
if [[ "$URL" != https://* ]]; then
  warn "NEXT_PUBLIC_SUPABASE_URL does not look like a https URL: $URL"
fi

# Block shipping privileged secrets inside the APK asset
FORBIDDEN_KEYS=(SERVICE_ROLE_SECRET SUPABASE_SERVICE_ROLE_KEY SUPABASE_PERSONAL_ACCESS_TOKEN)
FOUND_FORBIDDEN=0
for key in "${FORBIDDEN_KEYS[@]}"; do
  if env_has_key "$key" "$ROOT_DIR/.env"; then
    err "Refusing to build: $key is present in .env (would ship inside the APK)"
    FOUND_FORBIDDEN=1
  fi
done
if [[ "$FOUND_FORBIDDEN" -eq 1 ]]; then
  die "Move admin secrets to .env.admin (gitignored) and keep only URL + anon key in .env
Example .env:
  NEXT_PUBLIC_SUPABASE_URL=https://xxxx.supabase.co
  SUPABASE_ANON_KEY=eyJ..."
fi
ok "No service-role / PAT secrets in .env"

# ── connectivity smoke (optional, non-fatal) ─────────────────────────────────
section "Supabase connectivity smoke test"
if command -v curl >/dev/null 2>&1; then
  ANON="$(env_get SUPABASE_ANON_KEY "$ROOT_DIR/.env")"
  HTTP_CODE="$(curl -s -o /tmp/evalio_apk_health.json -w '%{http_code}' \
    -H "apikey: $ANON" \
    -H "Authorization: Bearer $ANON" \
    "${URL%/}/auth/v1/health" || true)"
  if [[ "$HTTP_CODE" == "200" ]]; then
    ok "Auth health OK (HTTP $HTTP_CODE)"
  else
    warn "Auth health returned HTTP ${HTTP_CODE:-failed} — build continues, but check your keys/URL"
    if [[ -f /tmp/evalio_apk_health.json ]]; then
      warn "Body: $(head -c 160 /tmp/evalio_apk_health.json)"
    fi
  fi
else
  warn "curl not found — skipping live Supabase check"
fi

# ── flutter deps / android ───────────────────────────────────────────────────
section "Flutter prepare"
log "flutter pub get"
flutter pub get

log "Ensuring Android platform is ready"
flutter config --enable-android >/dev/null 2>&1 || true

# ── build ────────────────────────────────────────────────────────────────────
section "Build APK ($BUILD_MODE)"
case "$BUILD_MODE" in
  release)
    log "Running: flutter build apk --release"
    flutter build apk --release
    BUILT_APK="$ROOT_DIR/build/app/outputs/flutter-apk/app-release.apk"
    ;;
  profile)
    log "Running: flutter build apk --profile"
    flutter build apk --profile
    BUILT_APK="$ROOT_DIR/build/app/outputs/flutter-apk/app-profile.apk"
    ;;
  debug)
    log "Running: flutter build apk --debug"
    flutter build apk --debug
    BUILT_APK="$ROOT_DIR/build/app/outputs/flutter-apk/app-debug.apk"
    ;;
  *)
    die "Unknown BUILD_MODE=$BUILD_MODE (use release|profile|debug)"
    ;;
esac

[[ -f "$BUILT_APK" ]] || die "Expected APK not found: $BUILT_APK"

# ── package output ───────────────────────────────────────────────────────────
section "Package output"
mkdir -p "$OUTPUT_DIR"
DEST="$OUTPUT_DIR/$APK_NAME"
cp "$BUILT_APK" "$DEST"
# Stable convenience copy
STABLE="$OUTPUT_DIR/evalio-design-latest.apk"
cp "$BUILT_APK" "$STABLE"

SIZE="$(du -h "$DEST" | awk '{print $1}')"
ok "APK ready: $DEST ($SIZE)"
ok "Latest:    $STABLE"

# ── install hints ────────────────────────────────────────────────────────────
section "Install on your phone"
cat <<EOF
${C_DIM}Option A — USB (adb)${C_RESET}
  1. Enable Developer options + USB debugging on the phone
  2. Plug in USB, accept the prompt
  3. Run:
       adb install -r "$STABLE"

${C_DIM}Option B — file transfer${C_RESET}
  1. Copy $STABLE to the phone (AirDrop/Drive/cable)
  2. Open the file and allow install from that source

${C_DIM}Login${C_RESET}
  Use an account from your Supabase project (register in-app, or create
  a user in the Supabase Auth dashboard). Do not commit credentials.

${C_BOLD}Notes${C_RESET}
  • APK embeds only public Supabase URL + anon key from .env
  • .env is gitignored — each machine needs its own copy (see .env.example)
  • Release builds currently use the debug signing key (fine for testing)
  • Phone needs internet to reach Supabase
EOF

section "Done"
ok "Build finished successfully."
