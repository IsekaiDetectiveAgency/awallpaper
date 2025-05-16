#!/data/data/com.termux/files/usr/bin/bash

set -uo pipefail

WALL_DIR="$HOME/storage/pictures/Wallpapers"
mkdir -p "$WALL_DIR"
TMP_IMG=$(mktemp)

URLS=(
  "https://wallhaven.cc/api/v1/search?q=anime&categories=110&purity=100&ratios=9x16%2C10x16%2C9x18&sorting=random&order=desc&ai_art_filter=0"
  "https://wallhaven.cc/api/v1/search?q=anime%20girls&categories=110&purity=100&ratios=9x16%2C10x16%2C9x18&sorting=random&order=desc&ai_art_filter=0"
)
LABELS=(
  "anime"
  "anime girls"
)
rm ~/boot_test_log.txt
sleep 3
echo "BOOT SCRIPT RAN at $(date)" >> ~/boot_test_log.txt

while true; do
  echo "BOOT SCRIPT REPEAT at $(date)" >> ~/boot_test_log.txt
  WORKING_URLS=()
  WORKING_LABELS=()

  TEST_URL="https://wallhaven.cc/api/v1/search?q=anime&categories=110&purity=100&ratios=9x16%2C10x16%2C9x18&sorting=random&order=desc&ai_art_filter=0"
  echo "Testing wallhaven... " >> ~/boot_test_log.txt
  if curl -sSf --head "$TEST_URL" > /dev/null; then
    echo "OK" >> ~/boot_test_log.txt
    echo "wallhaven works"
    WORKING_URLS=$URLS
    WORKING_LABELS=$LABELS
  else
  echo "wallhaven failed"
    TEST_URL="https://waifu.pics"
    echo "Testing waifu... " >> ~/boot_test_log.txt
    if curl -sSf --head "$TEST_URL" > /dev/null; then
      echo "OK" >> ~/boot_test_log.txt
      echo "waifu works"
      URLS=(
        "https://api.waifu.pics/sfw/waifu"
        "https://api.waifu.pics/sfw/neko"
        "https://api.nekosia.cat/api/v1/images/cuteness-is-justice"
        "https://api.nekosia.cat/api/v1/images/random"
        "https://api.waifu.im/search/"
        "https://pic.re/image"
      )
      LABELS=(
        "waifu.pics"
        "waifu.neko.pics"
        "nekosia-justice"
        "nekosia"
        "waifu.im"
        "pic.re"
      )
      WORKING_URLS=$URLS
      WORKING_LABELS=$LABELS
    else
      echo "Failed" >> ~/boot_test_log.txt
      echo "waifu failed"
      URLS=(
        "https://wallhaven.cc/api/v1/search?q=anime&categories=110&purity=100&ratios=9x16%2C10x16%2C9x18&sorting=random&order=desc&ai_art_filter=0"
        "https://wallhaven.cc/api/v1/search?q=anime%20girls&categories=110&purity=100&ratios=9x16%2C10x16%2C9x18&sorting=random&order=desc&ai_art_filter=0"
        "https://api.waifu.pics/sfw/waifu"
        "https://api.waifu.pics/sfw/neko"
        "https://api.nekosia.cat/api/v1/images/cuteness-is-justice"
        "https://api.nekosia.cat/api/v1/images/random"
        "https://api.waifu.im/search/"
        "https://pic.re/image"
      )
      LABELS=(
        "anime"
        "anime girls"
        "waifu.pics"
        "waifu.neko.pics"
        "nekosia-justice"
        "nekosia"
        "waifu.im"
        "pic.re"
      )

    fi
  fi
  sleep 1
  IDX=$(( RANDOM % ${#URLS[@]} ))
  URL=${URLS[$IDX]}
  LABEL=${LABELS[$IDX]}

  if [ ${#WORKING_URLS[@]} -eq 0 ]; then
    echo "❌ No working URLs. at $(date)" >> ~/boot_test_log.txt
    OUT_BASE="${LABEL// /_}"
  RAW_IMG="$WALL_DIR/${OUT_BASE}.jpg"
  LETTER_IMG="$WALL_DIR/${OUT_BASE}_blurlettered.jpg"
  echo "calling termux api"
  am start -n com.termux.api/.activities.TermuxAPILauncherActivity
  echo "$LABEL"
  termux-wallpaper -l -f "$LETTER_IMG" || { echo "❌ termux-wallpaper failed"; continue; }
  echo "✔ Wallpaper lockscreen set: $LABEL at $(date)" >> ~/boot_test_log.txt

  termux-wallpaper -f "$LETTER_IMG" || { echo "❌ termux-wallpaper failed"; continue; }
  echo "✔ Wallpaper set: $LABEL at $(date)" >> ~/boot_test_log.txt
  echo "wait time"
  sleep 60
  echo "first sleep at $(date)" >> ~/boot_test_log.txt
  sleep 120
  echo "second sleep at $(date)" >> ~/boot_test_log.txt
  sleep 240
  echo "third sleep at $(date)" >> ~/boot_test_log.txt
  sleep 480
  echo "fourth sleep at $(date)" >> ~/boot_test_log.txt
  sleep 960
  echo "fifth sleep at $(date)" >> ~/boot_test_log.txt
  sleep 1740
  echo "last sleep at $(date)" >> ~/boot_test_log.txt
      continue
  fi



  echo "getting $LABEL"
  if [ "$LABEL" = "waifu.pics" ]; then
    JSON=$(curl -s "$URL" || echo '{}')
    IMG_URL=$(echo "$JSON" | jq -r '.url // empty')
  elif [ "$LABEL" = "waifu.neko.pics" ]; then
    JSON=$(curl -s "$URL" || echo '{}')
    IMG_URL=$(echo "$JSON" | jq -r '.url // empty')
  elif [ "$LABEL" = "nekosia-justice" ]; then
    JSON=$(curl -s "$URL" || echo '{}')
    IMG_URL=$(echo "$JSON" | jq -r '.image' | jq -r '.compressed' | jq -r '.url // empty')
  elif [ "$LABEL" = "nekosia" ]; then
    JSON=$(curl -s "$URL" || echo '{}')
    IMG_URL=$(echo "$JSON" | jq -r '.image' | jq -r '.compressed' | jq -r '.url // empty')
  elif [ "$LABEL" = "waifu.im" ]; then
    JSON=$(curl -s "$URL" || echo '{}')
    IMG_URL=$(echo "$JSON" | jq -r '.images[0].url // empty')
  elif [ "$LABEL" = "pic.re" ]; then
    IMG_URL=https://pic.re/image
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
        echo "❌ No images found; retrying iteration." >> ~/boot_test_log.txt
        sleep 5
        continue 2
      fi
    done
    SEL_JSON=${IMGS[RANDOM % ${#IMGS[@]}]}
    IMG_URL=$(echo "$SEL_JSON" | jq -r '.path // empty')
    FAVS=$(echo "$SEL_JSON" | jq -r '.favorites // 0')
    echo "[*] Selected: $IMG_URL (favorites: $FAVS)" >> ~/boot_test_log.txt
  fi

  if [ -z "${IMG_URL-}" ]; then
    echo "❌ Failed to parse image URL; retrying iteration." >> ~/boot_test_log.txt
    sleep 5
    continue
  fi

  if ! wget -q -O "$TMP_IMG" "$IMG_URL"; then
    echo "❌ Download failed; retrying iteration." >> ~/boot_test_log.txt
    sleep 5
    continue
  fi

  if ! file "$TMP_IMG" | grep -qE 'image|bitmap'; then
    echo "❌ Not a valid image; retrying iteration." >> ~/boot_test_log.txt
    rm -f "$TMP_IMG"
    sleep 5
    continue
  fi

  OUT_BASE="${LABEL// /_}"
  RAW_IMG="$WALL_DIR/${OUT_BASE}.jpg"
  LETTER_IMG="$WALL_DIR/${OUT_BASE}_blurlettered.jpg"
  mv "$TMP_IMG" "$RAW_IMG"

  WIDTH=1080 HEIGHT=2340

  if ! command -v convert &>/dev/null && ! command -v magick &>/dev/null; then
    echo "❌ Install ImageMagick: pkg install imagemagick" >> ~/boot_test_log.txt
    exit 1
  fi
  IM_CMD=$(command -v magick &>/dev/null && echo magick || echo convert)

  $IM_CMD "$RAW_IMG" -resize "${WIDTH}x${HEIGHT}^" -gravity center -extent "${WIDTH}x${HEIGHT}" -blur 0x20 "${LETTER_IMG}.bg.jpg" || { echo "❌ Blur failed"; continue; }
  $IM_CMD "$RAW_IMG" -resize "${WIDTH}x${HEIGHT}" "${LETTER_IMG}.fg.png" || { echo "❌ Resize failed"; continue; }
  $IM_CMD "${LETTER_IMG}.bg.jpg" "${LETTER_IMG}.fg.png" -gravity center -composite "$LETTER_IMG" || { echo "❌ Composite failed"; continue; }
  rm -f "${LETTER_IMG}.bg.jpg" "${LETTER_IMG}.fg.png"
  echo "calling termux api" >> ~/boot_test_log.txt
echo "calling termux api"
echo "$LABEL"
am start -n com.termux.api/.activities.TermuxAPILauncherActivity
  termux-wallpaper -l -f "$LETTER_IMG" || { echo "❌ termux-wallpaper failed"; continue; }
  echo "✔ Wallpaper lockscreen set: $LABEL at $(date)" >> ~/boot_test_log.txt

  termux-wallpaper -f "$LETTER_IMG" || { echo "❌ termux-wallpaper failed"; continue; }
  echo "✔ Wallpaper set: $LABEL at $(date)" >> ~/boot_test_log.txt
  echo "wait time"
  sleep 60
  echo "first sleep at $(date)" >> ~/boot_test_log.txt
  sleep 120
  echo "second sleep at $(date)" >> ~/boot_test_log.txt
  sleep 240
  echo "third sleep at $(date)" >> ~/boot_test_log.txt
  sleep 480
  echo "fourth sleep at $(date)" >> ~/boot_test_log.txt
  sleep 960
  echo "fifth sleep at $(date)" >> ~/boot_test_log.txt
  sleep 1740
  echo "sixth sleep at $(date)" >> ~/boot_test_log.txt
  sleep 3480
  echo "seventh sleep at $(date)" >> ~/boot_test_log.txt
  sleep 6960
  echo "eighth sleep at $(date)" >> ~/boot_test_log.txt
  sleep 13920
  echo "ninth sleep at $(date)" >> ~/boot_test_log.txt
  sleep 15240
  echo "last sleep at $(date)" >> ~/boot_test_log.txt


done
