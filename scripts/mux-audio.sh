#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Mux an audio track onto a (silent) video file with ffmpeg.
#
# Used by Path B of the Seedance 2.0 voice-source gate: generate the video
# silent (audio: false), generate the audio separately in ElevenLabs, then
# overlay the audio onto the video here.
#
# Behavior:
#   - Video stream is copied as-is (no re-encode → no quality loss)
#   - Audio is re-encoded to AAC 192k (MP4 container needs AAC for broad
#     compatibility; source mp3 can be any bitrate)
#   - -shortest trims the output to whichever input is shorter. Plan your
#     audio length to match the video length; any trailing audio past the
#     video's end will be dropped.
#   - If the input video already has an audio track, it is silently replaced.
#
# Requires:
#   - ffmpeg on PATH (brew install ffmpeg)
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

if [ "$#" -lt 3 ]; then
  cat >&2 <<EOF
Usage: $0 <video.mp4> <audio.mp3> <output.mp4>

Example:
  $0 outputs/ad/clip2-silent.mp4 references/audio/real-sarah-layers-vo.mp3 outputs/ad/clip2-final.mp4

Options:
  VIDEO   a silent (or any) MP4 from Seedance
  AUDIO   mp3/m4a/wav — the ElevenLabs track to overlay
  OUTPUT  destination MP4 path (will be overwritten if it exists)
EOF
  exit 1
fi

VIDEO="$1"
AUDIO="$2"
OUTPUT="$3"

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ERROR: ffmpeg not found on PATH. Install with: brew install ffmpeg" >&2
  exit 2
fi

if [ ! -f "$VIDEO" ]; then
  echo "ERROR: video not found: $VIDEO" >&2
  exit 3
fi

if [ ! -f "$AUDIO" ]; then
  echo "ERROR: audio not found: $AUDIO" >&2
  exit 4
fi

mkdir -p "$(dirname "$OUTPUT")"

echo "Muxing…"
echo "  video : $VIDEO"
echo "  audio : $AUDIO"
echo "  out   : $OUTPUT"

ffmpeg -y \
  -i "$VIDEO" \
  -i "$AUDIO" \
  -map 0:v:0 \
  -map 1:a:0 \
  -c:v copy \
  -c:a aac -b:a 192k \
  -shortest \
  "$OUTPUT"

echo "Done → $OUTPUT"

# Probe the output so the user can eyeball duration/streams.
if command -v ffprobe >/dev/null 2>&1; then
  ffprobe -v error -show_entries stream=codec_type,codec_name,duration,bit_rate \
    -of default=noprint_wrappers=1 "$OUTPUT" || true
fi
