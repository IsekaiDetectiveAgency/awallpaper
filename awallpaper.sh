#!/data/data/com.termux/files/usr/bin/bash

# A truly uncrashable anime wallpaper rotator for Termux
# Uses robust continue-based flow control to never exit the main loop.

set -uo pipefail  # strict unset var + fail on pipe errors

WALL_DIR="$HOME/storage/pictures/Wallpapers"
mkdir -p "$WALL_DIR"
TMP_IMG=$(mktemp)

# Define API endpoints and labels
URLS=(
  "https://wallhaven.cc/api/v1/search?q=anime&categories=110&purity=100&ratios=9x16%2C10x16%2C9x18&sorting=random&order=desc&ai_art_filter=0"
  "https://wallhaven.cc/api/v1/search?q=anime%20girls&categories=110&purity=100&ratios=9x16%2C10x16%2C9x18&sorting=random&order=desc&ai_art_filter=0"
  "https://api.waifu.pics/sfw/waifu"
)
LABELS=(
  "anime"
  "anime girls"
  "waifu.pics"
)
rm ~/boot_test_log.txt
sleep 1
echo "BOOT SCRIPT RAN at $(date)" >> ~/boot_test_log.txt

while true; do
echo "BOOT SCRIPT REPEAT at $(date)" >> ~/boot_test_log.txt
  # Reset working arrays each iteration
  WORKING_URLS=()
  WORKING_LABELS=()

  # Connectivity test
  for i in "${!URLS[@]}"; do
    TEST_URL="${URLS[$i]}"
    [ "${LABELS[$i]}" = "waifu.pics" ] && TEST_URL="https://waifu.pics"
    echo -n "Testing ${LABELS[$i]}... "
    if curl -sSf --head "$TEST_URL" > /dev/null; then
      echo "OK"
      WORKING_URLS+=("${URLS[$i]}")
      WORKING_LABELS+=("${LABELS[$i]}")
    else
      echo "Failed"
    fi
    sleep 1
  done

  # If none reachable, retry iteration
  if [ ${#WORKING_URLS[@]} -eq 0 ]; then
    echo "❌ No working URLs; retrying in 30 seconds."
    sleep 30
    continue
  fi

  # Pick random source safely
  IDX=$(( RANDOM % ${#WORKING_URLS[@]} ))
  URL=${WORKING_URLS[$IDX]}
  LABEL=${WORKING_LABELS[$IDX]}

  # Fetch image URL
  if [ "$LABEL" = "waifu.pics" ]; then
    JSON=$(curl -s "$URL" || echo '{}')
    IMG_URL=$(echo "$JSON" | jq -r '.url // empty')
  else
    JSON=$(curl -s "$URL" || echo '{"data":[]}')
    THRESH=50
    while :; do
      mapfile -t IMGS < <(echo "$JSON" | jq -c --argjson t "$THRESH" '.data[] | select(.favorites >= $t)')
      if (( ${#IMGS[@]} > 0 )); then
        break
      fi
      (( THRESH-- ))
      if (( THRESH < 0 )); then
        echo "❌ No images found; retrying iteration."
        sleep 5
        continue 2
      fi
    done
    SEL_JSON=${IMGS[RANDOM % ${#IMGS[@]}]}
    IMG_URL=$(echo "$SEL_JSON" | jq -r '.path // empty')
    FAVS=$(echo "$SEL_JSON" | jq -r '.favorites // 0')
    echo "[*] Selected: $IMG_URL (favorites: $FAVS)"
  fi

  # Ensure we have a URL
  if [ -z "${IMG_URL-}" ]; then
    echo "❌ Failed to parse image URL; retrying iteration."
    sleep 5
    continue
  fi

  # Download image
  if ! wget -q -O "$TMP_IMG" "$IMG_URL"; then
    echo "❌ Download failed; retrying iteration."
    sleep 5
    continue
  fi

  # Validate image file
  if ! file "$TMP_IMG" | grep -qE 'image|bitmap'; then
    echo "❌ Not a valid image; retrying iteration."
    rm -f "$TMP_IMG"
    sleep 5
    continue
  fi

  # Prepare output
  OUT_BASE="${LABEL// /_}"
  RAW_IMG="$WALL_DIR/${OUT_BASE}.jpg"
  LETTER_IMG="$WALL_DIR/${OUT_BASE}_blurlettered.jpg"
  mv "$TMP_IMG" "$RAW_IMG"

  # Dimensions
  WIDTH=1080 HEIGHT=2340

  # Check ImageMagick
  if ! command -v convert &>/dev/null && ! command -v magick &>/dev/null; then
    echo "❌ Install ImageMagick: pkg install imagemagick"
    exit 1
  fi
  IM_CMD=$(command -v magick &>/dev/null && echo magick || echo convert)

  # Process images
  $IM_CMD "$RAW_IMG" -resize "${WIDTH}x${HEIGHT}^" -gravity center -extent "${WIDTH}x${HEIGHT}" -blur 0x20 "${LETTER_IMG}.bg.jpg" || { echo "❌ Blur failed"; continue; }
  $IM_CMD "$RAW_IMG" -resize "${WIDTH}x${HEIGHT}" "${LETTER_IMG}.fg.png" || { echo "❌ Resize failed"; continue; }
  $IM_CMD "${LETTER_IMG}.bg.jpg" "${LETTER_IMG}.fg.png" -gravity center -composite "$LETTER_IMG" || { echo "❌ Composite failed"; continue; }
  rm -f "${LETTER_IMG}.bg.jpg" "${LETTER_IMG}.fg.png"

  # Set wallpaper
  termux-wallpaper -l -f "$LETTER_IMG" || { echo "❌ termux-wallpaper failed"; continue; }
echo "✔ Wallpaper set: $LABEL at $(date)" >> ~/boot_test_log.txt

  # Wait before next
  sleep 3600

done
