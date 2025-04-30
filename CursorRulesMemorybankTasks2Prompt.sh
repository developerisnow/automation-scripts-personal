#!/bin/bash

# Aggregates .cursor/rules, memory-bank, and tasks folders into a single prompt file for Cursor

BASE_DIR="${1:-$(pwd)}"
OUTPUT_DIR="/Users/user/____Sandruk/___PKM/temp/code2prompt"
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M')
PROJECT_NAME=$(basename "$BASE_DIR")
FOLDERS=(".cursor/rules" "memory-bank" "tasks")
OUTPUT_FILE="$OUTPUT_DIR/c2p_cursor-${PROJECT_NAME}-${TIMESTAMP}.txt"

mkdir -p "$OUTPUT_DIR" || { echo "Failed to create output dir: $OUTPUT_DIR"; exit 1; }

echo "Project: $PROJECT_NAME" > "$OUTPUT_FILE"
echo "Aggregated folders: ${FOLDERS[*]}" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

for FOLDER in "${FOLDERS[@]}"; do
  SRC_PATH="$BASE_DIR/$FOLDER"
  if [[ ! -d "$SRC_PATH" ]]; then
    echo "Skipping missing folder: $SRC_PATH"
    continue
  fi

  echo "==== $FOLDER ====" >> "$OUTPUT_FILE"
  find "$SRC_PATH" -type f | sort | while read -r FILE; do
    REL_PATH=$(python3 -c "import os.path; print(os.path.relpath('$FILE', '$BASE_DIR'))")
    echo "" >> "$OUTPUT_FILE"
    echo "/$REL_PATH:" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    cat "$FILE" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
  done
done

echo "Done: $OUTPUT_FILE"
