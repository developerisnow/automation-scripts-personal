# File Extensions Finder Specification
##  Prompts
`````prompts
1. Check @compare_folders.py @spec__compare_folders.md @sync_folders.py @spec__sync_folders.md coding style, spec style plus way to configure in the top of script and then log of course. Learn, understand?
2. Write spec to build script check path or paths and make a list of existing file extensions there with amount of files and size in csv, structure is:
```
extension,amount,size-mb
pdf,99,100
```
3. write script  @find_extensions.py 
----
4. скрипт туповат он смотрит часть имени если там несколько точек - сделай только последнее
----
5. you didn't follow my (2) point, remember 1,2 ? @spec__find_extensions.md @find_extensions.py 
`````
## Objectives
1. Build a script to scan one or more directories (configured at the top of the script) and list out all file extensions present in those directories.
2. For each file, use only the part after the last dot as its extension (e.g., for 'archive.tar.gz', use 'gz').
3. Generate a CSV report with the following structure:
   - extension,amount,size-mb
   - Example: pdf,99,100.00
4. Log primary actions to the console for clarity.
5. Ensure that the script only reads files and never modifies them.

## Requirements
- The script must be configurable with the following parameters at the top:
  - PATHS: A list of directories (absolute or relative) to scan.
  - OUTPUT_DIR: The directory where the CSV report will be saved (defaults to the script directory if not set).
- File extension extraction must consider only the portion after the last dot in a filename.
- The CSV report must include a timestamp in its filename, e.g., find_extensions-YYYY-MM-DD-HHMM.csv.
- The script must handle errors gracefully (e.g., if a path is invalid or a file cannot be processed).

## Process Flow
1. Read the configuration parameters (PATHS and OUTPUT_DIR).
2. For each configured directory:
   - Verify it exists and is a directory. If not, log a warning.
   - Recursively scan all subdirectories.
3. For each file found:
   - Extract the file extension using rsplit to take only the text after the last dot.
   - If no dot exists, mark the extension as 'no_extension'.
   - Accumulate the count of files and total file size (in bytes) for that extension.
4. After scanning, convert the total size of each extension from bytes to MB.
5. Write the results to a CSV file with columns: extension,amount,size-mb.
6. Print out log messages indicating the progress and final location of the CSV report.

## Output
- A CSV file named with the format: find_extensions-YYYY-MM-DD-HHMM.csv, containing columns:
  - extension
  - amount (number of files with that extension)
  - size-mb (total size of those files in MB, formatted to two decimals)

## Safety
- The script must only read files; no files or directories will be modified, deleted, or moved.
- Log key actions and warnings to inform the user of any issues during the scan.
