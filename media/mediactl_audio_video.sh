# ~/bin/mediactl.sh
#!/usr/bin/env bash
# Universal FFmpeg wrapper: ① audio→YouTube-MP4 ② audio→M4A ③ any WebM→MP4
set -euo pipefail

# ───────── Defaults ─────────
IMG_DEFAULT="$HOME/Pictures/cover.png"   # 1920×1080 JPEG/PNG
OUT_DIR_DEFAULT="$HOME/NextCloud2/__Vaults_Databases_nxtcld/__Recordings_nxtcld/_by-projects/0y-recordings"
AUDIO_BR="192k"
VIDEO_BR="1M"
FPS=1
PRESET="veryslow"
TUNE="stillimage"

usage() {
cat <<EOF
Usage: $(basename "$0") -m {cover|audio|transcode} -i INPUT [-I IMAGE] [-o OUT] [-v]

  -m  Mode:
        cover      audio + static cover → MP4   (YouTube-ready)
        audio      audio → M4A                  (AAC)
        transcode  WebM/anything → MP4 H.264    (meetings, screen-caps)
  -i  Input file (audio or video)
  -I  Cover image for 'cover' mode (default: $IMG_DEFAULT)
  -o  Output file or directory (default dir: $OUT_DIR_DEFAULT)
  -v  Verbose FFmpeg log
  -h  Help
EOF
}

# ───────── Parse CLI ─────────
MODE="" ; INPUT="" ; IMAGE="$IMG_DEFAULT" ; OUT="$OUT_DIR_DEFAULT" ; VERBOSE=false
while getopts ":m:i:I:o:vh" opt; do
  case $opt in
    m) MODE="$OPTARG" ;;
    i) INPUT="$OPTARG" ;;
    I) IMAGE="$OPTARG" ;;
    o) OUT="$OPTARG" ;;
    v) VERBOSE=true ;;
    h) usage; exit 0 ;;
    \?) echo "Invalid option: -$OPTARG" >&2; usage; exit 1 ;;
    :)  echo "Option -$OPTARG requires an argument." >&2; usage; exit 1 ;;
  esac
done
shift $((OPTIND -1))

# Allow a bare positional argument to act as -i INPUT
if [[ -z "$INPUT" && $# -gt 0 ]]; then
  INPUT="$1"
fi

[[ -z "$MODE"   || -z "$INPUT" ]] && { usage; exit 1; }

[[ -f "$INPUT" ]] || { echo "Input not found: $INPUT" >&2; exit 1; }
[[ "$MODE" == "cover" ]] && [[ -f "$IMAGE" ]] || \
  { [[ "$MODE" != "cover" ]] || { echo "Cover image not found: $IMAGE" >&2; exit 1; }; }

LOGLEVEL=$([[ $VERBOSE == true ]] && echo "info" || echo "error")
IN_ABS="$(realpath "$INPUT")"
mkdir -p "$OUT_DIR_DEFAULT"

# helper: pick output name if user supplied only a directory
auto_out() {
  local dir="$1" base="$2" suffix="$3"
  mkdir -p "$dir"
  echo "$(realpath "$dir")/${base}${suffix}"
}

# ───────── Mode: cover ─────────
if [[ $MODE == "cover" ]]; then
  base="$(basename "${IN_ABS%.*}")"
  [[ -d "$OUT" ]] && OUT=$(auto_out "$OUT" "$base"_yt .mp4)
  ffmpeg -loglevel "$LOGLEVEL" \
    -loop 1 -framerate "$FPS" -i "$(realpath "$IMAGE")" -i "$IN_ABS" \
    -c:v libx264 -preset "$PRESET" -tune "$TUNE" -b:v "$VIDEO_BR" \
    -pix_fmt yuv420p -c:a aac -b:a "$AUDIO_BR" \
    -shortest -movflags +faststart "$OUT"

# ───────── Mode: audio ─────────
elif [[ $MODE == "audio" ]]; then
  base="$(basename "${IN_ABS%.*}")"
  [[ -d "$OUT" ]] && OUT=$(auto_out "$OUT" "$base" .m4a)
  ffmpeg -loglevel "$LOGLEVEL" -i "$IN_ABS" \
    -vn -c:a aac -b:a "$AUDIO_BR" -movflags +faststart "$OUT"
  

# ───────── Mode: transcode ─────────
elif [[ $MODE == "transcode" ]]; then
  base="$(basename "${IN_ABS%.*}")"
  [[ -d "$OUT" ]] && OUT=$(auto_out "$OUT" "$base" .mp4)

  # Prefer Apple VideoToolbox HW encoder if available; fall back to libx264
  if ffmpeg -hide_banner 2>&1 | grep -q h264_videotoolbox; then
    VENC="-c:v h264_videotoolbox -b:v 4M"
  else
    VENC="-c:v libx264 -crf 23 -preset medium"
  fi

  ffmpeg -loglevel "$LOGLEVEL" -i "$IN_ABS" \
    $VENC -pix_fmt yuv420p \
    -c:a aac -b:a "$AUDIO_BR" \
    -movflags +faststart "$OUT"
else
  echo "Unknown mode: $MODE" >&2; exit 1
fi

echo "✅  Output → $OUT"