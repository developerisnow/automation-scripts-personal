#!/bin/bash

# ------------------------------------------------------------------------------
# HypeTrainInfra2Promp.sh - Infrastructure Aggregation Script (FAQ & Guide)
# ------------------------------------------------------------------------------
# Purpose:
#   - Aggregates all relevant infrastructure/config files from the HypeTrain repo
#     into a single prompt file for LLMs, code review, or documentation.
#   - Removes YAML comments and blank lines to minimize output size and focus on
#     actual configuration content.
#   - Calculates the size of each file (after cleaning) to help you identify the
#     largest contributors to the output, so you can manually trim or exclude files
#     to fit size constraints (e.g., 200KB for LLM context windows).
#
# Key Features:
#   - Finds and aggregates Dockerfiles, YAML, JSON, scripts, and other infra files.
#   - For .yml/.yaml files, strips comments and blank lines for compactness.
#   - Outputs a file tree and the cleaned content of each file.
#   - Calculates and displays the size (in KB) of every processed file (after cleaning).
#   - At the end of the output, lists the top 20 largest files (by cleaned size) to help
#     you decide what to remove or trim.
#
# Usage:
#   - Run the script directly or via the provided alias (e.g., hc2pInfra).
#   - Review the output file (path is printed at the end) to see the full infra snapshot.
#   - Use the per-file size list and top 20 summary to decide which files to remove or trim
#     if you need to reduce the total size (e.g., for LLM prompt limits).
#   - No files are deleted or excluded automatically; you have full manual control.
#
# Customization:
#   - Adjust the find commands to include/exclude specific file types or paths.
#   - Change the output directory or filename as needed.
#   - The script is safe to modify for your workflow.
#
# Troubleshooting:
#   - If you see missing files, check the find paths and permissions.
#   - If the output is too large, use the size lists to target the biggest files.
#   - For YAML files, only uncommented, non-blank lines are included in the size calculation.
#
# Author: (your name/contact)
# Last updated: (date)
# ------------------------------------------------------------------------------

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
# find . -maxdepth 1 -type f -name 'pnpm-workspace.yaml' -print >> "$FOUND_FILES_LIST"
# find . -maxdepth 1 -type f -name 'tsconfig.base.json' -print >> "$FOUND_FILES_LIST"
# find . -maxdepth 1 -type f -name 'lefthook.yml' -print >> "$FOUND_FILES_LIST"
# find . -maxdepth 1 -type f -name 'renovate.json' -print >> "$FOUND_FILES_LIST"

# Find all files
find apps -path 'apps/*/Dockerfile*' -type f -print >> "$FOUND_FILES_LIST"
find apps -path 'apps/*/Dockerfile.dev*' -type f -print >> "$FOUND_FILES_LIST"
find apps -path 'apps/*/dockerignore*' -type f -print >> "$FOUND_FILES_LIST"
# find apps -path 'apps/*/yarnrc*' -type f -print >> "$FOUND_FILES_LIST"
find apps -path 'apps/*/dockerignore*' -type f -print >> "$FOUND_FILES_LIST"
# find apps -path 'apps/*/tsconfig*' -type f -print >> "$FOUND_FILES_LIST"
find apps -path '*/garden/preview.yml' -type f -print >> "$FOUND_FILES_LIST"
find apps -path '*/garden/garden.yml' -type f -print >> "$FOUND_FILES_LIST"
# find apps -path '*/garden/values.yaml' -type f -print >> "$FOUND_FILES_LIST"
# find apps -path '*/garden/Chart.yaml' -type f -print >> "$FOUND_FILES_LIST"
find apps -path '*/test/docker-compose.test.yaml' -type f -print >> "$FOUND_FILES_LIST"
find .github/workflows -maxdepth 1 -type f -name '*.yml' -print >> "$FOUND_FILES_LIST"

# Find Migrations (using corrected paths)
# find apps/hypetrain-api/src/infrastructure/database/migrations -type f -name '*.ts' -print >> "$FOUND_FILES_LIST"
# find apps/hypetrain-notification-service/src/infrastructure/storage/migrations -type f -name '*.ts' -print >> "$FOUND_FILES_LIST"
# find apps/hypetrain-message-processing-service/src/infrastructure/storage/migrations -type f -name '*.ts' -print >> "$FOUND_FILES_LIST"
# find apps/hypetrain-migration-runner/src/migrations -type f -name '*.ts' -print >> "$FOUND_FILES_LIST" # Added migration runner migrations

# Find Garden
# find /Users/user/__Repositories/HypeTrain/repositories/hypetrain-garden  -type f -name '*.yml' -print >> "$FOUND_FILES_LIST"
# Find Scripts
find scripts -type f -name '*' -print >> "$FOUND_FILES_LIST"

# Find Example Env File
# find apps/hypetrain-api/test -maxdepth 1 -type f -name 'test.env' -print >> "$FOUND_FILES_LIST"

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
# Create a temp file to store file sizes and paths
FILE_SIZES_LIST=$(mktemp)
trap 'rm -f "$FOUND_FILES_LIST" "${FOUND_FILES_LIST}.sorted" "$FILE_SIZES_LIST"' EXIT

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

    # Prepare a temp file for processed content
    TMP_CONTENT=$(mktemp)
    if [[ "$relative_path" == *.yml || "$relative_path" == *.yaml ]]; then
        grep -v '^[[:space:]]*#' "$relative_path" | grep -v '^[[:space:]]*$' > "$TMP_CONTENT"
    else
        cat "$relative_path" > "$TMP_CONTENT"
    fi
    cat "$TMP_CONTENT" >> "$OUTPUT_FILE_ABSOLUTE"
    # Ensure trailing newline before end marker
    if [[ $(tail -c1 "$TMP_CONTENT") != '' ]]; then
      echo "" >> "$OUTPUT_FILE_ABSOLUTE"
    fi
    echo '```' >> "$OUTPUT_FILE_ABSOLUTE"

    # Accumulate size (use processed size)
    current_bytes=$(stat -f%z "$TMP_CONTENT")
    total_bytes=$((total_bytes + current_bytes))
    # Store size and path for later sorting
    printf "%10d %s\n" "$current_bytes" "$relative_path" >> "$FILE_SIZES_LIST"
    rm -f "$TMP_CONTENT"

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

    # --- Append Per-File Size List to Output ---
    echo "" >> "$OUTPUT_FILE_ABSOLUTE"
    echo "File Sizes (after comment/blank-line removal):" >> "$OUTPUT_FILE_ABSOLUTE"
    echo "---------------------------------------------" >> "$OUTPUT_FILE_ABSOLUTE"
    sort -nr "$FILE_SIZES_LIST" | awk '{printf "%7.1f KB  %s\n", $1/1024, $2}' >> "$OUTPUT_FILE_ABSOLUTE"
    echo "" >> "$OUTPUT_FILE_ABSOLUTE"
    # --- Append Top 20 Largest Files to Output ---
    echo "Top 20 Largest Files (by output size):" >> "$OUTPUT_FILE_ABSOLUTE"
    echo "--------------------------------------" >> "$OUTPUT_FILE_ABSOLUTE"
    sort -nr "$FILE_SIZES_LIST" | head -20 | awk '{printf "%7.1f KB  %s\n", $1/1024, $2}' >> "$OUTPUT_FILE_ABSOLUTE"
    echo "" >> "$OUTPUT_FILE_ABSOLUTE"
    # --- Append Actual Output File Size ---
    actual_bytes=$(stat -f%z "$OUTPUT_FILE_ABSOLUTE")
    actual_kb=$(echo "scale=2; $actual_bytes / 1024" | bc)
    echo "Actual output file size on disk: $actual_bytes bytes (${actual_kb} KB)" | tee -a "$OUTPUT_FILE_ABSOLUTE"
    echo "" >> "$OUTPUT_FILE_ABSOLUTE"
else
    echo "Error: Output file was not created." >&2
    exit 1
fi

exit 0
