#!/bin/bash

# Standalone script to aggregate HypeTrain infrastructure files into a single prompt file.
# Does not rely on code2prompt.sh.

HYPETRAIN_REPO_PATH="/Users/user/__Repositories/HypeTrain/repositories/hypetrain-backend"
# OUTPUT_DIR_RELATIVE="references/o1-pro" # Relative to repo path
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M')
OUTPUT_FILENAME="c2p_infra_${TIMESTAMP}.txt"

# --- Validate Paths ---
if [[ ! -d "$HYPETRAIN_REPO_PATH" ]]; then
  echo "Error: HypeTrain repo path not found: $HYPETRAIN_REPO_PATH" >&2
  exit 1
fi

# OUTPUT_DIR_ABSOLUTE="$HYPETRAIN_REPO_PATH/$OUTPUT_DIR_RELATIVE"
OUTPUT_DIR_ABSOLUTE="/Users/user/____Sandruk/___PKM/temp/code2prompt"
OUTPUT_FILE_ABSOLUTE="$OUTPUT_DIR_ABSOLUTE/$OUTPUT_FILENAME"

# --- Create Output Directory ---
mkdir -p "$OUTPUT_DIR_ABSOLUTE"
if [[ $? -ne 0 ]]; then
    echo "Error: Could not create output directory: $OUTPUT_DIR_ABSOLUTE" >&2
    exit 1
fi

# --- Find Files ---
echo "Finding infrastructure files..."
cd "$HYPETRAIN_REPO_PATH" || { echo "Error: Could not cd to $HYPETRAIN_REPO_PATH"; exit 1; }

# Use a temporary file to store found file paths relative to repo root
FOUND_FILES_LIST=$(mktemp)
# Ensure temp file is cleaned up on exit
trap 'rm -f "$FOUND_FILES_LIST" "${FOUND_FILES_LIST}.sorted"' EXIT

# Find top-level files individually
find . -maxdepth 1 -type f -name 'README.md' -print >> "$FOUND_FILES_LIST"
find . -maxdepth 1 -type f -name 'TECH_DESC.md' -print >> "$FOUND_FILES_LIST"
find . -maxdepth 1 -type f -name 'TECH_REQ.md' -print >> "$FOUND_FILES_LIST"
find . -maxdepth 1 -type f -name 'garden.yml' -print >> "$FOUND_FILES_LIST"
find . -maxdepth 1 -type f -name 'docker-compose.yaml' -print >> "$FOUND_FILES_LIST"
find . -maxdepth 1 -type f -name 'pnpm-workspace.yaml' -print >> "$FOUND_FILES_LIST"
find . -maxdepth 1 -type f -name 'tsconfig.base.json' -print >> "$FOUND_FILES_LIST"
find . -maxdepth 1 -type f -name 'lefthook.yml' -print >> "$FOUND_FILES_LIST"
find . -maxdepth 1 -type f -name 'renovate.json' -print >> "$FOUND_FILES_LIST"

# Find all files
find apps -path 'apps/*/Dockerfile*' -type f -print >> "$FOUND_FILES_LIST"
find apps -path 'apps/*/Dockerfile.dev*' -type f -print >> "$FOUND_FILES_LIST"
find apps -path 'apps/*/dockerignore*' -type f -print >> "$FOUND_FILES_LIST"
find apps -path 'apps/*/yarnrc*' -type f -print >> "$FOUND_FILES_LIST"
find apps -path 'apps/*/dockerignore*' -type f -print >> "$FOUND_FILES_LIST"
find apps -path 'apps/*/tsconfig*' -type f -print >> "$FOUND_FILES_LIST"
find apps -path '*/garden/preview.yml' -type f -print >> "$FOUND_FILES_LIST"
find apps -path '*/garden/garden.yml' -type f -print >> "$FOUND_FILES_LIST"
find apps -path '*/garden/values.yaml' -type f -print >> "$FOUND_FILES_LIST"
find apps -path '*/garden/Chart.yaml' -type f -print >> "$FOUND_FILES_LIST"
find apps -path '*/test/docker-compose.test.yaml' -type f -print >> "$FOUND_FILES_LIST"
find .github/workflows -maxdepth 1 -type f -name '*.yml' -print >> "$FOUND_FILES_LIST"

# Find Migrations (using corrected paths)
find apps/hypetrain-api/src/infrastructure/database/migrations -type f -name '*.ts' -print >> "$FOUND_FILES_LIST"
find apps/hypetrain-notification-service/src/infrastructure/storage/migrations -type f -name '*.ts' -print >> "$FOUND_FILES_LIST"
find apps/hypetrain-message-processing-service/src/infrastructure/storage/migrations -type f -name '*.ts' -print >> "$FOUND_FILES_LIST"
find apps/hypetrain-migration-runner/src/migrations -type f -name '*.ts' -print >> "$FOUND_FILES_LIST" # Added migration runner migrations

# Find Garden
find /Users/user/__Repositories/HypeTrain/repositories/hypetrain-garden  -type f -name '*.yml' -print >> "$FOUND_FILES_LIST"
# Find Scripts
find scripts -type f -name '*' -print >> "$FOUND_FILES_LIST"

# Find Example Env File
find apps/hypetrain-api/test -maxdepth 1 -type f -name 'test.env' -print >> "$FOUND_FILES_LIST"

# Sort and remove duplicates (like ./garden.yml if also found via apps/*)
# Also remove leading ./ for cleaner paths
sort -u "$FOUND_FILES_LIST" | sed 's|^\\./||g' > "${FOUND_FILES_LIST}.sorted"
mv "${FOUND_FILES_LIST}.sorted" "$FOUND_FILES_LIST"

file_count=$(wc -l < "$FOUND_FILES_LIST")
echo "Found $file_count files."

# --- Generate Tree ---
echo "Generating file tree..."
TREE_OUTPUT=$(tree --fromfile "$FOUND_FILES_LIST" --noreport)
if [[ $? -ne 0 ]]; then
    echo "Warning: Could not generate tree output. Proceeding without it." >&2
    TREE_OUTPUT="(Could not generate tree)"
fi

# --- Initialize Output File ---
> "$OUTPUT_FILE_ABSOLUTE"
echo "Project Path: Infrastructure Files" > "$OUTPUT_FILE_ABSOLUTE"
echo "" >> "$OUTPUT_FILE_ABSOLUTE"
echo "Source Tree:" >> "$OUTPUT_FILE_ABSOLUTE"
echo "" >> "$OUTPUT_FILE_ABSOLUTE"
echo '```' >> "$OUTPUT_FILE_ABSOLUTE"
echo "$TREE_OUTPUT" >> "$OUTPUT_FILE_ABSOLUTE"
echo '```' >> "$OUTPUT_FILE_ABSOLUTE"
echo "" >> "$OUTPUT_FILE_ABSOLUTE"

# --- Process Files and Calculate Size ---
echo "Aggregating file contents..."
total_bytes=0
while IFS= read -r relative_path; do
    if [[ -z "$relative_path" ]]; then continue; fi # Skip empty lines

    # Check file exists and is readable (relative to HYPETRAIN_REPO_PATH)
    if [[ ! -f "$relative_path" || ! -r "$relative_path" ]]; then
        echo "Warning: Skipping non-file or unreadable path: $relative_path" >&2
        continue
    fi

    echo "Adding: $relative_path"

    # Append Header
    echo "" >> "$OUTPUT_FILE_ABSOLUTE"
    echo "/$relative_path:" >> "$OUTPUT_FILE_ABSOLUTE"
    echo '```' >> "$OUTPUT_FILE_ABSOLUTE"

    # Append Content (filtering comments for YAML)
    if [[ "$relative_path" == *.yml || "$relative_path" == *.yaml ]]; then
        grep -v '^[[:space:]]*#' "$relative_path" >> "$OUTPUT_FILE_ABSOLUTE"
    else
        cat "$relative_path" >> "$OUTPUT_FILE_ABSOLUTE"
    fi
    # Ensure trailing newline before end marker
    # Check if the file ends with a newline, if not, add one
    if [[ $(tail -c1 "$relative_path") != '' ]]; then
      echo "" >> "$OUTPUT_FILE_ABSOLUTE"
    fi
    echo '```' >> "$OUTPUT_FILE_ABSOLUTE"

    # Accumulate size
    current_bytes=$(stat -f%z "$relative_path")
    total_bytes=$((total_bytes + current_bytes))

done < "$FOUND_FILES_LIST"

# Clean up temp file is handled by trap

cd - > /dev/null # Return to original directory silently

# --- Report Results ---
if [ -f "$OUTPUT_FILE_ABSOLUTE" ]; then
    # Calculate size in KB/MB using bc (check if bc exists)
    if command -v bc &> /dev/null; then
        size_kb=$(echo "scale=2; $total_bytes / 1024" | bc)
        size_mb=$(echo "scale=2; $total_bytes / 1024 / 1024" | bc)
        size_string="${size_kb} KB / ${size_mb} MB"
    else
        size_kb=$((total_bytes / 1024))
        size_string="Approx. ${size_kb} KB (bc not found for precise calculation)"
    fi

    echo "-----------------------------------"
    echo "Successfully aggregated $file_count infrastructure files."
    echo "Infra prompt saved to: $OUTPUT_FILE_ABSOLUTE"
    echo "Total Original Size (before comment removal): ${size_string}"
    echo "-----------------------------------"
else
    echo "Error: Output file was not created." >&2
    exit 1
fi

exit 0
