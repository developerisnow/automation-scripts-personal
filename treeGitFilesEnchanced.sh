#!/bin/bash

OUTPUT_FILE="treeGitFiles_$(basename "$(pwd)")-$(date "+%Y-%m-%d_%H-%M").md"

FILES=$(git ls-files | sort)

FILE_COUNT=$(echo "$FILES" | wc -l)
FOLDER_COUNT=$(echo "$FILES" | xargs -n1 dirname | sort -u | wc -l)

IMAGES_COUNT=$(echo "$FILES" | grep -Ei '\.(png|jpg|jpeg|gif|svg|ico)$' | wc -l)
ARCHIVES_COUNT=$(echo "$FILES" | grep -Ei '\.(zip|tar|gz|rar)$' | wc -l)
LOGS_DB_COUNT=$(echo "$FILES" | grep -Ei '\.(log|sqlite|db)$' | wc -l)
BUILDS_COUNT=$(echo "$FILES" | grep -Ei '\.(pyc|pyo|pyd|class)$' | wc -l)

echo "# Git-Tracked Directory Tree for $(basename "$(pwd)")" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "### File Type Summary:" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "- Images (png|jpg|jpeg|gif|svg|ico): $IMAGES_COUNT files" >> "$OUTPUT_FILE"
echo "- Archives (zip|tar|gz|rar): $ARCHIVES_COUNT files" >> "$OUTPUT_FILE"
echo "- Build artifacts (pyc|pyo|pyd|class): $BUILDS_COUNT files" >> "$OUTPUT_FILE"
echo "- Logs and databases (log|sqlite|db): $LOGS_DB_COUNT files" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "- **Files:** $FILE_COUNT" >> "$OUTPUT_FILE"
echo "- **Folders:** $FOLDER_COUNT" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "### Repository Structure:" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Use a temp file for compatibility
TMP_TREE_FILE=$(mktemp)
echo "$FILES" > "$TMP_TREE_FILE"

print_tree() {
  local prefix="$1"
  local dir="$2"
  local files=()
  local dirs=()
  local entries=()

  # Find all entries (files and dirs) directly under $dir
  while IFS= read -r entry; do
    local rel="$entry"
    if [ -n "$dir" ]; then
      rel="${entry#$dir/}"
      # skip if not under this dir
      case "$entry" in
        $dir/*) ;;
        *) continue ;;
      esac
    fi
    # Only direct children (no '/')
    if [ "$rel" != "${rel#*/}" ]; then
      # has a slash, so it's a subdir
      local subdir="${rel%%/*}"
      if [ -z "${subdir}" ]; then continue; fi
      local found=0
      for d in "${dirs[@]}"; do
        if [ "$d" = "$subdir" ]; then found=1; break; fi
      done
      if [ $found -eq 0 ]; then dirs+=("$subdir"); fi
    elif [ -n "$rel" ]; then
      files+=("$rel")
    fi
  done < "$TMP_TREE_FILE"

  entries=("${dirs[@]}" "${files[@]}")
  local total=${#entries[@]}
  local i=0
  for entry in "${entries[@]}"; do
    i=$((i+1))
    local connector="|--"
    local next_prefix="$prefix|   "
    if [ $i -eq $total ]; then
      connector="\`--"
      next_prefix="$prefix    "
    fi
    local is_dir=0
    for d in "${dirs[@]}"; do
      if [ "$d" = "$entry" ]; then is_dir=1; break; fi
    done
    if [ $is_dir -eq 1 ]; then
      echo "${prefix}${connector} $entry/" >> "$OUTPUT_FILE"
      if [ -z "$dir" ]; then
        print_tree "$next_prefix" "$entry"
      else
        print_tree "$next_prefix" "$dir/$entry"
      fi
    else
      echo "${prefix}${connector} $entry" >> "$OUTPUT_FILE"
    fi
  done
}

print_tree "" ""

rm "$TMP_TREE_FILE"
echo ""
echo "Tree structure has been saved to $OUTPUT_FILE"
# Uncomment to print to stdout:
# cat "$OUTPUT_FILE"