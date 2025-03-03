# Folder Comparison Specification
## Prompts
### Prompt 1
````prompt
1. I have 3 folders main "__Repositories" and 2 duplications "__Repositories0,1" as you see in "ls" output, before remove "*0,1"

2. I need to check list of all folders inside each of 3 main folders and make an compare_folders-yyyy-mm-dd-hhmm.csv with following structure `folder,created,modified,size`
2.1. don't put in csv equal folder, i need only bigger size or latest modified or which I don't have in main "__Repositories"

3. Before do script write a clear short checklist spec how to do this script  @spec__compare_folders.md . I want to configurate in the top of script source(main folder path) and all possible duplicates because I do the same with compare different folders
4. Do script @compare_folders.py 
````

## Purpose
Create a script that compares folders and identifies unique or more up-to-date content across multiple directory structures.

## Requirements

1. Compare a main folder with one or more duplicate folders
2. Generate a CSV report with the following structure:
   - `folder,created,modified,size`
3. Only include entries that are:
   - Unique to duplicate folders (not in main folder)
   - Larger in size than their counterparts in the main folder
   - More recently modified than their counterparts in the main folder
4. Configuration should be flexible to allow different source/duplicate folder paths
5. Output filename should include timestamp: `compare_folders-yyyy-mm-dd-hhmm.csv`

## Input Configuration
The script should allow configuration of:
- Main folder path (source)
- List of duplicate folder paths to compare against
- Output directory for the CSV report

## Process Flow
1. Read configuration from script parameters
2. Scan the main folder and all duplicate folders
3. Compare folders based on existence, size, and modification time
4. Generate a CSV report with only the relevant differences
5. Save the report with a timestamp in the filename

## Output
A CSV file with the following columns:
- `folder`: Path to the folder relative to its parent directory
- `created`: Creation timestamp of the folder
- `modified`: Last modification timestamp of the folder
- `size`: Total size of the folder in bytes
- `source`: Which directory this folder was found in (main or duplicate path)
