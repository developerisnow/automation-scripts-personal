# Obsidian Note Aggregator (`obs2prompt`) Specification & Guide

This document details the functionality, usage, and configuration of the `obs2prompt` script and its associated aliases.

## 1. Overview

`obs2prompt` is a Python script designed to traverse linked Obsidian notes starting from a specified entry point. It collects the content of the starting note and any linked notes up to a defined depth, aggregates the content into a single text file, calculates statistics, and copies the result to the clipboard.

The primary goal is to consolidate related notes into a single context, often for use with Large Language Models (LLMs).

## 2. Core Functionality

- **Recursive Link Following:** Starts from an input Markdown file and follows `[[WikiLinks]]` within the content.
- **Depth Control:** Allows specifying the maximum depth of links to follow (default is 1).
- **File Discovery:**
    - Searches the Obsidian vault specified by the `--vault` argument or the `OBSIDIAN_VAULT_PATH` environment variable. Defaults to the current working directory if neither is set.
    - Handles various filename variations (with/without `.md`, common prefixes like `$`, `@`, `=`, `MOC-`, `$.`, etc.).
    - Performs a recursive search within the vault if the file isn't found in the root.
    - Supports following symbolic links within the vault.
    - Includes partial filename matching for broader discovery.
- **Content Aggregation:** Combines the content of all discovered files into a single output string.
- **Output Formatting:**
    - Adds a header section with metadata (start file, generation date, depth, file count).
    - Includes an optional file structure tree view if more than one file is collected.
    - Separates content from different files with headers (`### FileName`) and path information.
    - Appends a statistics section (Total Files, Lines, Size, Tokens).
- **Statistics:** Calculates and displays:
    - Total number of files collected.
    - Total number of lines across all collected files.
    - Total size of all collected files (human-readable format).
    - Total token count (attempts to use `code2prompt --tokens`, falls back to word count).
- **Clipboard Integration:** Copies the aggregated content to the system clipboard using `pyperclip` (can be disabled).
- **File Output:** Saves the aggregated content to a text file. The default location is `temp/aggregate_<input_filename>.txt` relative to the vault path or current directory, configurable via `O2P_OUTPUT_DIR` environment variable or `--output` argument.
- **Debugging:** Provides verbose debug logging via the `--debug` flag.
- **Verbose Mode:** Offers detailed progress messages via the `--verbose` flag (implicitly enabled by `--debug`).

## 3. Script Usage (`obs2prompt_obsidian_to_prompt.py`)

```bash
python3 /path/to/obs2prompt_obsidian_to_prompt.py <input_file> [options]
```

**Arguments:**
1
- `<input_file>` (Required): The path or name of the starting Obsidian note (e.g., `"My Starting Note.md"` or `"My Starting Note"`).

**Options:**

- `--depth <N>`: Maximum depth of links to follow (default: `1`).
- `--vault <path>`: Path to the Obsidian vault directory. Overrides `OBSIDIAN_VAULT_PATH`.
- `--output <path>`: Full path for the output file. Overrides default naming and `O2P_OUTPUT_DIR`.
- `--debug`: Enable detailed debug logging.
- `--verbose`: Enable progress messages (automatically enabled with `--debug`).
- `--no-clipboard`: Disable copying the output content to the clipboard.

**Environment Variables:**

- `OBSIDIAN_VAULT_PATH`: Specifies the default path to the Obsidian vault if `--vault` is not provided.
- `O2P_OUTPUT_DIR`: Specifies the default directory for output files if `--output` is not provided.

## 4. Zsh Aliases (`.zshrc`)

Several convenience aliases are defined in `.zshrc` to simplify running the script:

- **`o2p <filename> [depth] [debug]`**: The main function.
    - `depth`: Optional, defaults to `1`.
    - `debug`: Optional, pass any non-empty string (e.g., `"debug"`) to enable debug mode.
    - Example: `o2p "My Note" 2` (runs with depth 2)
    - Example: `o2p "Another Note" 1 debug` (runs with depth 1 and debug)

- **`o2p1 <filename>`**: Runs `o2p` with `depth=1`.
    - Example: `o2p1 "My Note"`

- **`o2p2 <filename>`**: Runs `o2p` with `depth=2`.
    - Example: `o2p2 "My Note"`

- **`o2p3 <filename>`**: Runs `o2p` with `depth=3`.
    - Example: `o2p3 "My Note"`

- **`o2pd <filename>`**: Runs `o2p` with `depth=1` and enables debug mode.
    - Example: `o2pd "My Note"`

- **`o2p-check`**: Checks if the script, vault, and output directory paths are correctly configured and if `python3` and `pyperclip` are available.

**Environment Variables Used by Aliases:**

- `O2P_SCRIPT_PATH`: Path to the Python script.
- `O2P_OUTPUT_DIR`: Default output directory.
- `OBSIDIAN_VAULT_PATH`: Default vault path.

## 5. Dependencies

- Python 3
- `pyperclip` library (`pip install pyperclip`)
- `code2prompt` (Optional, for accurate token counting)

## 6. Current Limitations & Planned Features

### Current Limitations
- **Alias Links:** Does not currently parse link aliases (`[[Link|Alias]]`). It uses the `Link` part.
- **Simple Heading Extraction:** Does not specifically handle links pointing *only* to headings (`[[#Heading]]`) within the *same* file. 
- **Token Count Fallback:** Relies on `code2prompt` for accurate token counts; the word count fallback is a rough estimate.
- **Error Handling:** Basic error handling. Could be improved for edge cases (malformed links, unsupported encodings).

### Planned Features (Including Implemented)
- **✅ [Implemented] Embed/Heading Link Handling (`![[Link#Heading]]` or `[[Link#Heading]]`):
    - The script now successfully recognizes links pointing to specific headings within other notes.
    - When such a link is encountered, it extracts *only* the content under that specific heading (from the heading line until the next heading of the same or lower level, or the end of the file).
    - The standard `[[Link]]` (without `#Heading`) still includes the entire file content.
    - The heading extraction is smart enough to handle different heading formats:
        - Spaces vs. colons in headings (e.g., `# 04:10 Q1 Deep research` will match with `04 10 Q1 Deep research`)
        - Case-insensitive matching
        - Handling of other common punctuation (dashes, underscores)
    - Embedded links (`!`) are treated the same as regular links (`[[...]]`) in terms of content extraction; the `!` primarily affects Obsidian's rendering, not this script's logic.
    - **Smart Link Processing and Deduplication**:
        - The script intelligently groups all links by their target file
        - **Strict Prioritization**: When both general links (`[[Link]]`) and heading-specific links (`[[Link#Heading]]`) to the same file exist, the script processes ONLY the general link, entirely skipping the heading-specific links to avoid duplicate content
        - **Multiple Heading Support**: When there are ONLY heading-specific links (no general link) to a file, the script processes each unique heading separately, extracting the specific sections
        - This approach guarantees that each target file is processed exactly once, with the most comprehensive version (full file content) prioritized when available
    - **De-duplication**: The script tracks which file+heading combinations have been processed and won't process the same combination twice, even if it's linked multiple times or referenced from different files
    - **Statistics**: File statistics (size, token count) are calculated based on the original full file sizes, providing a complete picture of the processed data

---

*This specification reflects the state as of 2025-04-06. Last updated to include smart link prioritization and enhanced deduplication logic.*