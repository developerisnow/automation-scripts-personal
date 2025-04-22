#!/bin/bash
set -e
# set -o pipefail # Pipefail can mask rg errors when no files are found

# Script to search for a query within specified HypeTrain project directories
# using ripgrep (rg), respecting .gitignore, and outputting the full content
# of matching files in a formatted prompt file.

# --- Configuration ---
# Comma-separated list of absolute paths to search within
HYPETRAIN_SEARCH_PATHS_CSV="/Users/user/__Repositories/hypetrain-backend,/Users/user/__Repositories/hypetrain-devops-helm,/Users/user/__Repositories/hypetrain-frontend,/Users/user/__Repositories/hypetrain-dynamic-env-wh-proxy"
OUTPUT_DIR_ABSOLUTE="/Users/user/____Sandruk/___PKM/temp/code2prompt" # Output directory

# --- Input Validation ---
if [[ -z "$1" ]]; then
  echo "Usage: $0 <search_query>" >&2
  exit 1
fi
QUERY="$1"

# --- Prepare Filename and Output Path ---
SANITIZED_QUERY=$(echo "$QUERY" | sed 's/[^a-zA-Z0-9]/-/g')
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M')
OUTPUT_FILENAME="search2prompt_${SANITIZED_QUERY}_${TIMESTAMP}.txt"
OUTPUT_FILE_ABSOLUTE="$OUTPUT_DIR_ABSOLUTE/$OUTPUT_FILENAME"

# --- Create Output Directory ---
mkdir -p "$OUTPUT_DIR_ABSOLUTE"
if [[ $? -ne 0 ]]; then
    echo "Error: Could not create output directory: $OUTPUT_DIR_ABSOLUTE" >&2
    exit 1
fi

# --- Check Tools ---
if ! command -v rg &> /dev/null; then
    echo "Error: ripgrep (rg) is not installed or not in PATH." >&2
    exit 1
fi
if ! command -v tree &> /dev/null; then
   echo "Warning: tree command not found. Tree view will be skipped." >&2
   TREE_CMD_FOUND=false
else
   TREE_CMD_FOUND=true
fi
if ! command -v bc &> /dev/null; then
    echo "Warning: bc command not found. Size calculation may be approximate." >&2
    BC_CMD_FOUND=false
else
    BC_CMD_FOUND=true
fi

# --- Process Search Paths ---
INITIAL_PWD=$(pwd)
# Use temporary files for lists and cleanup
ALL_MATCHED_FILES_ABS=$(mktemp) # Stores absolute paths for the tree
CURRENT_MATCHED_FILES_REL=$(mktemp) # Temp file for relative paths per dir
trap 'rm -f "$ALL_MATCHED_FILES_ABS" "$CURRENT_MATCHED_FILES_REL"' EXIT

TOTAL_FILES_FOUND=0

# Convert CSV string to array
IFS=',' read -ra SEARCH_PATHS <<< "$HYPETRAIN_SEARCH_PATHS_CSV"

echo "Searching across specified paths..."
for search_root in "${SEARCH_PATHS[@]}"; do
    echo "--> Searching in: $search_root"
    if [[ ! -d "$search_root" ]]; then
        echo "    Warning: Path not found, skipping: $search_root" >&2
        continue
    fi

    cd "$search_root" || {
        echo "    Warning: Could not cd to path, skipping: $search_root" >&2
        continue
    }

    # Find files relative to current search_root
    rg -l -iF "$QUERY" . > "$CURRENT_MATCHED_FILES_REL" || true
    current_count=$(wc -l < "$CURRENT_MATCHED_FILES_REL")
    echo "    Found $current_count matching files in this path."

    if [[ "$current_count" -gt 0 ]]; then
        # Add absolute paths to the global list for the tree
        while IFS= read -r rel_path; do
            # Ensure rel_path is not empty and make path absolute
            if [[ -n "$rel_path" ]]; then
                 # Construct absolute path correctly
                 abs_path="$(cd "$search_root" && realpath "$rel_path")"
                 echo "$abs_path" >> "$ALL_MATCHED_FILES_ABS"
            fi
        done < "$CURRENT_MATCHED_FILES_REL"
    fi

    cd "$INITIAL_PWD" # Go back for the next iteration
done

# Remove duplicates from the absolute path list
sort -u -o "$ALL_MATCHED_FILES_ABS" "$ALL_MATCHED_FILES_ABS"
TOTAL_FILES_FOUND=$(wc -l < "$ALL_MATCHED_FILES_ABS")

if [[ "$TOTAL_FILES_FOUND" -eq 0 ]]; then
  echo "No files found containing the query '$QUERY' across all specified paths."
  exit 0
fi
echo "Total unique matching files found across all paths: $TOTAL_FILES_FOUND"

# --- Generate Tree ---
TREE_OUTPUT="(Tree generation skipped or failed)"
if $TREE_CMD_FOUND; then
    echo "Generating file tree..."
    # Tree needs paths relative to current dir or absolute. Use absolute.
    TREE_OUTPUT=$(tree --fromfile "$ALL_MATCHED_FILES_ABS" --noreport -a || echo "(Error generating tree)")
fi

# --- Initialize Output File ---
> "$OUTPUT_FILE_ABSOLUTE"
echo "Search Query: '$QUERY'" > "$OUTPUT_FILE_ABSOLUTE"
echo "Timestamp: $TIMESTAMP" >> "$OUTPUT_FILE_ABSOLUTE"
echo "Searched Paths: ${HYPETRAIN_SEARCH_PATHS_CSV}" >> "$OUTPUT_FILE_ABSOLUTE"
echo "" >> "$OUTPUT_FILE_ABSOLUTE"
echo "Source Tree (All Matched Files):" >> "$OUTPUT_FILE_ABSOLUTE"
echo "" >> "$OUTPUT_FILE_ABSOLUTE"
echo '```' >> "$OUTPUT_FILE_ABSOLUTE"
echo "$TREE_OUTPUT" >> "$OUTPUT_FILE_ABSOLUTE"
echo '```' >> "$OUTPUT_FILE_ABSOLUTE"
echo "" >> "$OUTPUT_FILE_ABSOLUTE"

# --- Aggregate Full File Contents ---
echo "Aggregating full content of matching files..."
TOTAL_BYTES=0

# Loop through search paths again for aggregation
for search_root in "${SEARCH_PATHS[@]}"; do
    if [[ ! -d "$search_root" ]]; then continue; fi # Skip if dir vanished

    cd "$search_root" || continue # Skip if cd fails

    # Find matching files relative to this root *again*
    rg -l -iF "$QUERY" . > "$CURRENT_MATCHED_FILES_REL" || true
    current_count=$(wc -l < "$CURRENT_MATCHED_FILES_REL")

    # Only add section header if files were found here
    if [[ "$current_count" -gt 0 ]]; then
        echo "" >> "$OUTPUT_FILE_ABSOLUTE"
        echo "#-----------------------------------" >> "$OUTPUT_FILE_ABSOLUTE"
        echo "# Files found in: $search_root" >> "$OUTPUT_FILE_ABSOLUTE"
        echo "#-----------------------------------" >> "$OUTPUT_FILE_ABSOLUTE"

        while IFS= read -r relative_path; do
            if [[ -z "$relative_path" ]]; then continue; fi

            # Ensure file still exists and is readable
            if [[ ! -f "$relative_path" || ! -r "$relative_path" ]]; then
                 echo "    Warning: Skipping missing/unreadable file: $search_root/$relative_path" >&2
                 continue
            fi

            echo "    Adding content: $relative_path"

            # Append Header (Relative Path)
            echo "" >> "$OUTPUT_FILE_ABSOLUTE"
            echo "/$relative_path:" >> "$OUTPUT_FILE_ABSOLUTE"
            echo '```' >> "$OUTPUT_FILE_ABSOLUTE"

            # Append Full Content
            cat "$relative_path" >> "$OUTPUT_FILE_ABSOLUTE"

            # Ensure trailing newline before end marker
            if [[ $(tail -c1 "$relative_path" 2>/dev/null) != '' ]]; then
                echo >> "$OUTPUT_FILE_ABSOLUTE"
            fi
            echo '```' >> "$OUTPUT_FILE_ABSOLUTE"

            # Accumulate size
            current_bytes=$(stat -f%z "$relative_path")
            TOTAL_BYTES=$((TOTAL_BYTES + current_bytes))

        done < "$CURRENT_MATCHED_FILES_REL"
    fi # end if current_count > 0

    cd "$INITIAL_PWD" # Go back
done

# --- Report Results ---
if [ -f "$OUTPUT_FILE_ABSOLUTE" ]; then
    if $BC_CMD_FOUND; then
        size_kb=$(echo "scale=2; $TOTAL_BYTES / 1024" | bc)
        size_mb=$(echo "scale=2; $TOTAL_BYTES / 1024 / 1024" | bc)
        size_string="${size_kb} KB / ${size_mb} MB"
    else
        size_kb=$((TOTAL_BYTES / 1024))
        size_string="Approx. ${size_kb} KB (bc not found)"
    fi

    echo "-----------------------------------"
    echo "Search complete."
    echo "Query: '$QUERY'"
    echo "Total Matching Files: $TOTAL_FILES_FOUND"
    echo "Output saved to: $OUTPUT_FILE_ABSOLUTE"
    echo "Total Size of Matched Files: ${size_string}"
    echo "-----------------------------------"
else
    echo "Error: Output file was not created." >&2
    exit 1
fi

exit 0
