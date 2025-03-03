#!/bin/bash
# Script to run both analysis and move scripts for markdown note reorganization

set -e  # Exit on any error

# Default values
BASE_DIR="/Users/user/____Sandruk/___PARA"
TARGET_DIR="/Users/user/____Sandruk/___PKM/__SecondBrain/Dailies_Outputs"
CSV_FILE="markdown_files_analysis.csv"
LOG_DIR="logs"
PATTERN="_inputs"
SYMLINKS_LOG="symlinks_skipped.log"
DRY_RUN=false

# Help function
show_help() {
    echo "Markdown Note Reorganization Tool"
    echo ""
    echo "This script reorganizes markdown notes from *_inputs/* directories to a centralized location,"
    echo "renaming them with a standardized format and creating symlinks from original locations."
    echo ""
    echo "NOTE: Any existing symlinks in the source directories will be detected and skipped."
    echo "      A log of all skipped symlinks will be created for reference."
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help                Show this help message"
    echo "  -b, --base-dir DIR        Base directory to start searching (default: $BASE_DIR)"
    echo "  -t, --target-dir DIR      Target directory for moved files (default: $TARGET_DIR)"
    echo "  -c, --csv-file FILE       Name of CSV analysis file (default: $CSV_FILE)"
    echo "  -l, --log-dir DIR         Directory for log files (default: $LOG_DIR)"
    echo "  -p, --pattern PATTERN     Directory name pattern to match (default: $PATTERN)"
    echo "  -s, --symlinks-log FILE   Name of symlinks log file (default: $SYMLINKS_LOG)"
    echo "  -d, --dry-run             Dry run mode (no actual changes)"
    echo ""
    echo "Example:"
    echo "  $0 --base-dir '/Users/user/____Sandruk/___PARA/__Projects' --dry-run"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -b|--base-dir)
            BASE_DIR="$2"
            shift 2
            ;;
        -t|--target-dir)
            TARGET_DIR="$2"
            shift 2
            ;;
        -c|--csv-file)
            CSV_FILE="$2"
            shift 2
            ;;
        -l|--log-dir)
            LOG_DIR="$2"
            shift 2
            ;;
        -p|--pattern)
            PATTERN="$2"
            shift 2
            ;;
        -s|--symlinks-log)
            SYMLINKS_LOG="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Ensure target directories exist
mkdir -p "$TARGET_DIR"
mkdir -p "$LOG_DIR"

echo "======================================================================================="
echo "STEP 1: Analyzing markdown files"
echo "======================================================================================="
echo "Base directory: $BASE_DIR"
echo "Pattern: $PATTERN"
echo "CSV output: $CSV_FILE"
echo "Symlinks log: $SYMLINKS_LOG"
echo ""

python3 $(dirname "$0")/analyze_markdown_notes.py --base-dir "$BASE_DIR" --output "$CSV_FILE" --pattern "$PATTERN" --symlinks-log "$SYMLINKS_LOG"

echo ""
echo "======================================================================================="
echo "STEP 2: Moving files and creating symlinks"
echo "======================================================================================="
echo "Target directory: $TARGET_DIR"
echo "Log directory: $LOG_DIR"
if [ "$DRY_RUN" = true ]; then
    echo "Mode: DRY RUN (no actual changes)"
    DRY_RUN_ARG="--dry-run"
else
    echo "Mode: ACTUAL RUN"
    DRY_RUN_ARG=""
fi
echo ""

python3 $(dirname "$0")/move_markdown_notes.py --csv-file "$CSV_FILE" --target-dir "$TARGET_DIR" --log-dir "$LOG_DIR" $DRY_RUN_ARG

echo ""
echo "======================================================================================="
echo "Process complete!"
echo "=======================================================================================" 