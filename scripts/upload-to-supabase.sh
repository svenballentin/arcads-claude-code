#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Upload a local file to Supabase Storage and print its public URL.
#
# The URL is what kie.ai needs for reference images, start frames, and audio
# references. Reads credentials from .env (never commit .env).
#
# Usage:
#   ./scripts/upload-to-supabase.sh <local-file> [remote-path] [bucket]
#
# Examples:
#   # Default bucket, same filename at the bucket root:
#   ./scripts/upload-to-supabase.sh references/audio/emma-voice-ref.mp3
#
#   # Custom remote path (subfolder inside the bucket):
#   ./scripts/upload-to-supabase.sh \
#     references/influencers/emma/01-hero-front.jpg \
#     influencers/emma/01-hero-front.jpg
#
#   # Override the bucket:
#   ./scripts/upload-to-supabase.sh ./foo.jpg foo.jpg other-bucket
#
# Output:
#   On success, prints ONE line to stdout — the public URL. That's it.
#   All status messages go to stderr so the output is safe to capture:
#     URL=$(./scripts/upload-to-supabase.sh ./foo.jpg)
#
# Requires (in .env):
#   SUPABASE_URL                  https://<project-ref>.supabase.co
#   SUPABASE_SERVICE_ROLE_KEY     the service_role key (keep it in .env only)
#   SUPABASE_BUCKET               default bucket name (can be overridden via arg)
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f .env ]; then
  echo "ERROR: .env not found. Run ./scripts/setup.sh first." >&2
  exit 2
fi

# shellcheck disable=SC1091
source .env

: "${SUPABASE_URL:?SUPABASE_URL not set in .env — see .env.example}"
: "${SUPABASE_SERVICE_ROLE_KEY:?SUPABASE_SERVICE_ROLE_KEY not set in .env — see .env.example}"

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <local-file> [remote-path] [bucket]" >&2
  exit 1
fi

LOCAL_FILE="$1"
REMOTE_PATH="${2:-$(basename "$LOCAL_FILE")}"
BUCKET="${3:-${SUPABASE_BUCKET:-claude-marketing-agent-assets}}"

if [ ! -f "$LOCAL_FILE" ]; then
  echo "ERROR: file not found: $LOCAL_FILE" >&2
  exit 3
fi

# Guess MIME type from extension. Supabase infers from filename too, but being
# explicit avoids surprises for images and audio.
ext="${LOCAL_FILE##*.}"
ext_lc=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
case "$ext_lc" in
  jpg|jpeg) MIME="image/jpeg" ;;
  png)      MIME="image/png" ;;
  webp)     MIME="image/webp" ;;
  gif)      MIME="image/gif" ;;
  mp3)      MIME="audio/mpeg" ;;
  m4a)      MIME="audio/mp4" ;;
  wav)      MIME="audio/wav" ;;
  flac)     MIME="audio/flac" ;;
  ogg)      MIME="audio/ogg" ;;
  mp4)      MIME="video/mp4" ;;
  mov)      MIME="video/quicktime" ;;
  webm)     MIME="video/webm" ;;
  *)        MIME="application/octet-stream" ;;
esac

# Strip any leading slash — Supabase rejects paths that start with /
REMOTE_PATH="${REMOTE_PATH#/}"

UPLOAD_URL="$SUPABASE_URL/storage/v1/object/$BUCKET/$REMOTE_PATH"
PUBLIC_URL="$SUPABASE_URL/storage/v1/object/public/$BUCKET/$REMOTE_PATH"

echo "Uploading..." >&2
echo "  local  : $LOCAL_FILE ($MIME)" >&2
echo "  bucket : $BUCKET" >&2
echo "  remote : $REMOTE_PATH" >&2

# POST first (creates new object). If it already exists, fall back to PUT (upsert).
HTTP_CODE=$(curl -sS -o /tmp/supabase-upload-$$.log -w "%{http_code}" \
  -X POST "$UPLOAD_URL" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: $MIME" \
  -H "x-upsert: true" \
  --data-binary "@$LOCAL_FILE" || echo "000")

if [ "$HTTP_CODE" != "200" ] && [ "$HTTP_CODE" != "201" ]; then
  # Try PUT (upsert existing)
  HTTP_CODE=$(curl -sS -o /tmp/supabase-upload-$$.log -w "%{http_code}" \
    -X PUT "$UPLOAD_URL" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
    -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Content-Type: $MIME" \
    -H "x-upsert: true" \
    --data-binary "@$LOCAL_FILE" || echo "000")
fi

if [ "$HTTP_CODE" != "200" ] && [ "$HTTP_CODE" != "201" ]; then
  echo "ERROR: upload failed with HTTP $HTTP_CODE" >&2
  echo "Response body:" >&2
  cat /tmp/supabase-upload-$$.log >&2
  echo "" >&2
  echo "Common causes:" >&2
  echo "  - Bucket '$BUCKET' doesn't exist — create it in Supabase dashboard (Storage → New bucket, public=on)" >&2
  echo "  - SUPABASE_URL is wrong (must be https://<project-ref>.supabase.co)" >&2
  echo "  - SUPABASE_SERVICE_ROLE_KEY is wrong (check Project Settings → API)" >&2
  rm -f /tmp/supabase-upload-$$.log
  exit 4
fi

rm -f /tmp/supabase-upload-$$.log
echo "Uploaded ✓" >&2

# Sanity-probe the public URL — if the bucket isn't public, warn the user.
PROBE_CODE=$(curl -sS -o /dev/null -w "%{http_code}" -I "$PUBLIC_URL" || echo "000")
if [ "$PROBE_CODE" != "200" ]; then
  echo "WARN: public URL probe returned HTTP $PROBE_CODE." >&2
  echo "      The bucket may not be set to Public — fix in Supabase dashboard before kie.ai uses this URL." >&2
fi

# The one line of stdout. Capture with URL=$(./scripts/upload-to-supabase.sh ...).
echo "$PUBLIC_URL"
