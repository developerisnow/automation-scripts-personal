# Prompts
## Spec Tempalte for Bash Scripts
````prompt

````
## Re-organize markdown notes from "*_inputs/*" to "/Users/user/____Sandruk/___PKM/__SecondBrain/Dailies_Outputs"
````prompt
# Objectives What I want and why?
I've previously used all my notes and other input materials with PARA methodology with some modification to use following template
```bash
/Users/user/____Sandruk/___PARA/__Projects/_templates/_Template_Project0
├── .references/ (symlinks and all hidden from Obsidian information folders, files)
├── _inputs/
    ...
└── _outputs/
    ...
.gitignore
.cursorrules
```
But I've used Obsidian for Second Brain and better to use one folder because I'm combining it with my AI-Cursor.com-IDE for embeddings, chat with data MCP and many others things.
To prevent overhead indexing by amount of context and files I need keep it clean without any unnecessary files and folders. But for e.g. _outputs and .references really uncontrolled and could link many different repos for example https://github.com/mermaid-js/mermaid 100mb of markdowns and other useless stuff and I couldn't control it good, so I make a decision to separate it.

# Feature checklist:
- [ ] all markdown notes need to be moved from "*_inputs/*" to "/Users/user/____Sandruk/___PKM/__SecondBrain/Dailies_Outputs" but with some artefacts in title for better organization and sturcturing
- [ ] ending filename title mask should be like "YYYY-MM-DD-hhmm-<title>__<project-foldername>.md" 
    - [ ] date should be in format YYYY-MM-DD and check specific (each) markdown file created date and time and setup in title
    - [ ] <project-foldername> means for e.g. "/Users/user/____Sandruk/___PARA/__Resources/_MCP-Anthropic/_inputs/learn-mcp-anthropic-model-context-protocol.md" should be written "MCP-Anthropic" - without underscores but all other symbols
        - [ ] be aware of sub-folders when it's needed for e.g. some "*/_inputs/**/" has sub-folders and we need to align "../_inputs/" orientation folder higher level it's project folder. DOes it clear?
    - [ ] separator between <project-foldername> and <title> is "__" 2 underscores
- [ ] after move all markdown notes in a source folders for each moved files with need to add workable symlinks from target folder to source folder, for e.g. 
    - `ln -s  2024-12-13-1218-learn-mcp-anthropic-model-context-protocol__MCP-Anthropic.md /Users/user/____Sandruk/___PARA/__Resources/_MCP-Anthropic/_inputs/`
- [ ] need yyyy-mm-dd-hhmm-<common-run-title>.log all actions from $source to $target for: 1) moving renaming, 2) symlinking

!Important

We setup configuration path for e.g. in our case is "/Users/user/____Sandruk/___PARA/__Projects" and $matchSubfolder "*/_inputs/"


# Sequence
1. Step 1. Analyse with output.csv: `filename before renaming,lines,size-kb,created,updated,path`
2. Step 2. Run script to execute actions

# Afterwards
1. Understand, criticize and improve my idea and spec if needed or feel free to ask for help understanding and improovement my solution
2. Do step 1, and then step 2.

# Context
@treeFolders_____Sandruk-2025-02-27_10-21.md
````

### Prompt 2
````prompt
looks like we have new proble and need update @spec__inputs_move.md and @analyze_markdown_notes.py @reorganize_markdown_notes.sh @move_markdown_notes.py because of I forgot to say что все прошито бывает symlinks, потому что я не хотел дублей и 1 ssot/dry, например ты видишь ошибку "" нет файла потому что он symlinks 

/Users/user/____Sandruk/___PARA/__Projects/_Backlog/AIRPG-MMORPG__2024Q4/_outputs/_docs/symlinks/meetings-calls = "/Users/user/____Sandruk/___PKM/__Vaults_Databases/__People__vault/Meetings/networking" и наверное нужно пропускать symlinks и это логировать а в конце обработки еще подсчитывать сколько штук symlinks пропущено

Касательно этого symlinks мы его вернем когда по очереди и доберемся до папки другой
````

### Prompt 3
````prompt
I run script but looks like it's wrong - some duplications 
1) FIY wrong binary with "*._" in the middle "2025-02-19-0809-._2025-01-26-daily-airpg__AIRPG-MMORPG__2024Q4.md"   "/Users/user/____Sandruk/___PKM/__SecondBrain/Dailies_Outputs/2025-02-19-0809-._2025-01-26-daily-airpg__AIRPG-MMORPG__2024Q4.md" 
2) FIY looks fine  "/Users/user/____Sandruk/___PKM/__SecondBrain/Dailies_Outputs/2025-02-19-0809-2025-01-26-daily-airpg__AIRPG-MMORPG__2024Q4" 
3) Но я забыл о важной детали, не нужно было переносить YYYY-MM-DD-hhmm если у файла есть уже "YYYY-mm-dd" or "YYYY-mm-dd-hhmm" тогда он актуален, в таком случае как все исправить? мы же перенесли файлы? Наверное отдельный скрипт по переименованию таких кейсов и первый timestamp условно убирать и начинать со второго (не с дефиса бро, не перепутай не делай глупых ошибок смотрю наперед )
4) Ну и нужно убрать эти нерабочие файлы - хотя я их сам удалю и 1,2 просто FIY, разве что поясни почему так произошло выдвине понимание еслиз наешь
5) напиши спеку @spec__inputs_move.md   у тебя есть промпты и наш диалог чтобы осталось история как работаю скрипты что где и как запускать и тп 

# Context
- logs attached
- @analyze_markdown_notes.py 
- @move_markdown_notes.py 
- @reorganize_markdown_notes.sh 
````
### Prompt 4
````prompt
when I run script @fix-duplicated-dates-2025-02-27-1057.log --dry-run it works fast, when run without dry it works 5 min and I stop nothing happens - something wrong @fix-duplicated-dates-2025-02-27-1058.log @fix_duplicated_dates.py 
````

### prompt 5
````prompt
- good works @fix-duplicated-dates-2025-02-27-1103.log 
- but also check dates with following format "20250201-1510-1653" use it left it's okay without "-" kebabcase from "2025-02-19-0809-20250201-1510-1653-lessons-from-learning-again-basics-architecture-coding__AIRPG-MMORPG__2024Q4"
- also it's a overhelming to put them in one folder let's put them in subfolder you could match by 
"__%foldername%.md" and create sub-folder - for files which has only two underscores "__"
````

### prompt 6,7
````prompt
Check attached 3 runs (one of them dry) and outputs and tree , and log @fix-duplicated-dates-2025-02-27-1114.log  nothing changed
- filenames is it not difficult you see "2025-02-19-0809-20250201-0520-learn-architecture-models-services-etc__AIRPG-MMORPG__2024Q4" - remove "2025-02-19-0809-" from it right?
- sub-folders also put it all "*__AIRPG-MMORPG__2024Q4" in a "/Users/user/____Sandruk/___PKM/__SecondBrain/Dailies_Outputs/__AIRPG-MMORPG__2024Q4"!
-- important I see two time two underscores here! it's tricky, i think you need improove algorithm to use it with last from right to left i mean use this "AIRPG-MMORPG__2024Q4"

----
again nothing happened @fix-duplicated-dates-2025-02-27-1119.log 
````

# Markdown Notes Reorganization System Specification

## Overview

This project provides a suite of tools to reorganize markdown notes from various `_inputs` folders across a PARA methodology-based directory structure into a single centralized directory. The tools handle the renaming of files according to a standardized format, create symlinks from the original locations to maintain workflow integrity, and provide detailed logs and reports of actions taken.

## Features

- **Automatic Analysis**: Scans and analyzes markdown files in `_inputs` directories
- **Smart File Renaming**: Renames files with format `YYYY-MM-DD-hhmm-<title>__<project-foldername>.md`
- **Date Pattern Detection**: Detects files that already have date patterns to avoid redundant prefixes
- **Symlink Management**: Creates symlinks from original locations to maintain workflow
- **Symlink Detection**: Detects and skips existing symlinks to prevent circular references
- **Detailed Logging**: Logs all actions with timestamps for reference and troubleshooting
- **CSV Reporting**: Generates detailed CSV reports with file metadata
- **Dry Run Mode**: Preview changes without modifying files
- **Cleanup Tools**: Fix issues like redundant date prefixes or problematic filenames
- **Subfolder Organization**: Organizes files into project-specific subfolders based on filename patterns

## Scripts

### 1. analyze_markdown_notes.py

Scans `_inputs` directories for markdown files and generates a CSV report with file information.

#### Key Features:
- Detects and skips symlinks
- Extracts project folder names from paths
- Detects existing date patterns in filenames
- Generates appropriate new filenames based on file creation date

### 2. move_markdown_notes.py

Moves markdown files to the target directory, renames them according to the format, and creates symlinks from the original locations.

#### Key Features:
- Handles file copying with metadata preservation
- Creates symlinks from original locations to the new centralized location
- Generates detailed logs of all actions taken
- Provides dry run mode for previewing changes
- Skips existing symlinks to prevent circular references

### 3. reorganize_markdown_notes.sh

A shell script that orchestrates the entire process, running both the analysis and move scripts with appropriate parameters.

#### Key Features:
- Single command execution for the entire reorganization process
- Configurable parameters for directory paths and options
- Detailed help information with usage examples
- Creates necessary directories if they don't exist
- Provides clear progress feedback

### 4. fix_duplicated_dates.py

A utility script to fix issues with filenames, particularly for files with redundant date prefixes or problematic characters, and organize them into subfolders.

#### Key Features:
- Detects and renames files with redundant date prefixes
- Can delete or fix files with problematic filenames (e.g., "._" in the middle)
- Updates symlinks pointing to renamed files
- Detailed logging of all actions taken
- Provides dry run mode for previewing changes
- **Enhanced Project Name Extraction**: Intelligently extracts project names from filenames with multiple "__" patterns by:
  - For filenames with multiple "__" patterns (e.g., "title__AIRPG-MMORPG__2024Q4.md"), extracts the project name (AIRPG-MMORPG) from between the last two "__" occurrences
  - For filenames with a single "__" pattern, extracts the text after "__" as the project name
- **Subfolder Organization**: Creates and organizes files into project-specific subfolders:
  - Creates subfolders named after the extracted project names
  - Moves files into their appropriate project subfolders
  - Updates symlinks to maintain references
  - Tracks and reports created subfolders and moved files

## Usage

### Basic Usage

To reorganize your markdown notes:

```bash
./automations/markdown/reorganize_markdown_notes.sh --base-dir "/Users/user/____Sandruk/___PARA/__Projects" --dry-run
```

This will:
1. Analyze markdown files in the specified directory
2. Generate a CSV report
3. Show what changes would be made without actually making them

Once you're satisfied with the proposed changes, run without the `--dry-run` flag:

```bash
./automations/markdown/reorganize_markdown_notes.sh --base-dir "/Users/user/____Sandruk/___PARA/__Projects"
```

### Fixing Issues with File Names

If you encounter issues with redundant date prefixes or problematic filenames:

```bash
python3 automations/markdown/fix_duplicated_dates.py --directory "/Users/user/____Sandruk/___PKM/__SecondBrain/Dailies_Outputs" --organize-subfolders --dry-run
```

To apply the fixes:

```bash
python3 automations/markdown/fix_duplicated_dates.py --directory "/Users/user/____Sandruk/___PKM/__SecondBrain/Dailies_Outputs" --organize-subfolders
```

To delete problematic files with "._" in their names:

```bash
python3 automations/markdown/fix_duplicated_dates.py --directory "/Users/user/____Sandruk/___PKM/__SecondBrain/Dailies_Outputs" --delete-dot-files
```

### Advanced Options

#### reorganize_markdown_notes.sh

```
Options:
  -h, --help                Show help message
  -b, --base-dir DIR        Base directory to start searching (default: /Users/user/____Sandruk/___PARA)
  -t, --target-dir DIR      Target directory for moved files (default: /Users/user/____Sandruk/___PKM/__SecondBrain/Dailies_Outputs)
  -c, --csv-file FILE       Name of CSV analysis file (default: markdown_files_analysis.csv)
  -l, --log-dir DIR         Directory for log files (default: logs)
  -p, --pattern PATTERN     Directory name pattern to match (default: _inputs)
  -s, --symlinks-log FILE   Name of symlinks log file (default: symlinks_skipped.log)
  -d, --dry-run             Dry run mode (no actual changes)
```

#### fix_duplicated_dates.py

```
Options:
  -h, --help                Show help message
  --directory DIR           Directory containing markdown files to fix
  --delete-dot-files        Delete files with "._" in their names instead of trying to fix them
  --organize-subfolders     Organize files into subfolders based on project name (from filename)
  --dry-run                 Dry run mode (no actual changes)
  --debug                   Enable debug output for each file
```

## Implementation Details

### File Renaming Logic

Files are renamed according to the following rules:

1. If the filename already starts with a date pattern (YYYY-MM-DD or YYYY-MM-DD-HHMM), the date pattern is preserved and only the project folder name is appended.
2. If the filename doesn't have a date pattern, a new date prefix is added based on the file's creation date, followed by the original filename and project folder name.
3. The script also recognizes non-kebab-case date formats like "20250201-1510-1653" and preserves them appropriately.

### Project Name Extraction

The system extracts project names from filenames using these rules:

1. For filenames with multiple "__" patterns (e.g., "title__AIRPG-MMORPG__2024Q4.md"):
   - Finds all positions of "__" in the filename
   - Takes what's between the second-to-last and last "__" (e.g., "AIRPG-MMORPG")
   - Uses this as the project name for subfolder organization

2. For filenames with only one "__" pattern (e.g., "title__Project.md"):
   - Extracts the text after "__" and before any other special characters
   - Uses this as the project name

### Subfolder Organization

The system organizes files into subfolders by:

1. Extracting the project name from each filename using the rules above
2. Creating a subfolder with that project name if it doesn't exist
3. Moving the file into the appropriate subfolder
4. Updating any symlinks that point to the moved file

### Symlink Handling

The system carefully handles symlinks to prevent circular references:

1. If a source file is already a symlink, it is skipped and logged
2. When files are moved, symlinks are created from the original location to the new location
3. When files are moved to subfolders, any symlinks pointing to them are updated
4. A detailed log of skipped symlinks is generated for reference

### Error Handling

The system includes robust error handling:

1. Files that don't exist or can't be read are skipped
2. Actions that fail are logged with error messages
3. Target files that already exist are not overwritten
4. Unicode decoding errors are gracefully handled

## File Organization

The files in the target directory are organized with a standardized naming convention:

1. Files that already had date patterns: `<original-date-pattern>-<title>__<project-foldername>.md`
2. Files that didn't have date patterns: `YYYY-MM-DD-hhmm-<title>__<project-foldername>.md`

Additionally, files are now organized into subfolders based on their project names:

```
/Target_Directory/
    /AIRPG-MMORPG/
        20250201-0520-learn-architecture-models-services-etc__AIRPG-MMORPG__2024Q4.md
        20250129-0700-game-flow-yaml-is-it-really-need-ssot__AIRPG-MMORPG__2024Q4.md
        ...
    /aleo-zk-testnet1-2024Q3/
        aleo-nodes_log__aleo-zk-testnet1-2024Q3.md
        session_kyc__aleo-zk-testnet1-2024Q3.md
        ...
    ...other project folders...
```

## Log Files

Logs are stored in the specified log directory (default: `logs/`) and include:

1. **Action Logs**: Detailed logs of all actions taken during file moving
2. **Symlinks Log**: A list of symlinks that were skipped during processing
3. **Fix Logs**: Logs of any filename fixes or cleanup actions

A typical log entry for the fix_duplicated_dates.py script looks like:

```
[2025-02-27 11:25:48] RENAMED
  Source: /Users/user/____Sandruk/___PKM/__SecondBrain/Dailies_Outputs/2025-02-19-0809-20250201-0520-learn-architecture-models-services-etc__AIRPG-MMORPG__2024Q4.md
  Target: /Users/user/____Sandruk/___PKM/__SecondBrain/Dailies_Outputs/AIRPG-MMORPG/20250201-0520-learn-architecture-models-services-etc__AIRPG-MMORPG__2024Q4.md
```

## Sequence

1. **Step 1**: Analyze with output.csv: information includes filename, lines, size-kb, created date, updated date, path
2. **Step 2**: Run script to execute actions (move files, rename, create symlinks)
3. **Step 3** (if needed): Run fix_duplicated_dates.py to clean up any issues with redundant date prefixes, organize into subfolders

## Example Results

After running all scripts, you should see:
```
PROCESSING COMPLETE
Total files: 138
Renamed files: 52
Moved to subfolders: 52
Deleted files: 0
Skipped files: 34
Subfolders created: 9
Errors: 0
```

## Implementation Notes

- The scripts use Python's standard libraries for file operations
- Timestamps are based on file creation times from the filesystem
- Regular expressions are used to detect existing date patterns
- The shell script ensures all necessary directories exist before processing
- All scripts include appropriate logging for troubleshooting and verification