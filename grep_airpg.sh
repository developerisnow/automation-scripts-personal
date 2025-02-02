#!/bin/bash
#
# grep_airpg.sh: Search recursively (only in *.ts files) for a provided keyword
# in one or more paths, print match statistics, output matching lines, and copy
# everything to the macOS clipboard.
#
# Usage:
#   grep_airpg.sh <match_keyword> "<comma-separated-paths>"
#
# Example:
#   grep_airpg.sh "SimpleLogger" "test/,src/"
#
# This command will do roughly:
#   grep -R --include="*.ts" "SimpleLogger" test/ src/
#
# It prints:
#   Matches 
#   {N} in test/
#   {M} in src/
#   Total {L} in all test/,src/
# followed by the actual match lines, and then copies output to clipboard.

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <match_keyword> <comma-separated-paths>"
  exit 1
fi

KEYWORD="$1"
PATHS_ARG="$2"

# Convert comma-separated paths into array
IFS=',' read -ra PATHS <<< "$PATHS_ARG"
TOTAL_COUNT=0
STAT_OUTPUT="Matches\n"
MATCH_OUTPUT=""

# Loop through each provided path and perform grep
for path in "${PATHS[@]}"; do
  # Trim any leading/trailing whitespace from the path
  TRIMMED_PATH=$(echo "$path" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  
  # Count occurrences by outputting only matching occurrences (-o) then counting lines.
  COUNT=$(grep -R --include="*.ts" -o "$KEYWORD" "$TRIMMED_PATH" 2>/dev/null | wc -l)
  
  # Capture all matching lines (filename:line format)
  CURRENT_MATCHES=$(grep -R --include="*.ts" "$KEYWORD" "$TRIMMED_PATH" 2>/dev/null)
  
  # Append statistics and update total count
  STAT_OUTPUT="${STAT_OUTPUT}${COUNT} in ${TRIMMED_PATH}\n"
  TOTAL_COUNT=$((TOTAL_COUNT + COUNT))
  
  # Append matches (if any exist)
  MATCH_OUTPUT="${MATCH_OUTPUT}\n${CURRENT_MATCHES}"
done

STAT_OUTPUT="${STAT_OUTPUT}Total ${TOTAL_COUNT} in all ${PATHS_ARG}\n"

FINAL_OUTPUT="${STAT_OUTPUT}\n${MATCH_OUTPUT}"

# Output to terminal
echo -e "$FINAL_OUTPUT"

# Copy final output to macOS clipboard
echo -e "$FINAL_OUTPUT" | pbcopy
echo "Output copied to clipboard."
