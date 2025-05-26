# Code2Prompt Enhancement: Smart Tree Trimming - Session Log (2025-05-25)

## 🎯 **Goal:** Resolve large context file sizes from `code2prompt` due to full project tree inclusion.

---

### Timeline & Key Actions:

#### 1. 🧐 **Problem Identification & Initial Analysis:**
- **Issue:** `quality-control` context for `hypetrain-backend` was unexpectedly large (~272KB, ~63k tokens), despite specific include/exclude patterns. User expected ~50-150 files, not thousands.
- **Investigation:**
	- Verified `include_patterns` in `includes_code2prompt_default.json` were specific (e.g., `package.json`, `.github/workflows/*.yml`).
	- Confirmed `exclude_patterns` (e.g., `src/**`, `libs/**`) were present.
	- `code2prompt` output (`cc2p_hypetrain-backend_quality-control.txt`) showed:
		- Full project directory tree, including excluded `src/`, `libs/`.
		- Actual file *content* seemed to be correctly filtered, but the *tree representation* itself was the bulk of the file.
- **Conclusion:** `code2prompt` includes the full visual tree structure regardless of content filtering, causing bloat.

#### 2. 💡 **Proposed Solution: Tree Trimming Post-Processing:**
- **Idea:** Add a mechanism to automatically cut the tree structure from the output file after `code2prompt` generation.
- **Approach:**
	- Introduce a `trim_tree: true` flag in `includes_code2prompt_default.json` for specific contexts.
	- Modify `code2prompt.sh` to:
		- Read the `trim_tree` flag for the current project/context.
		- If `true`, call a new Bash function to process the output file.

#### 3. 🛠️ **Implementation Details:**

- **A. Configuration Update (`includes_code2prompt_default.json`):**
	- Added `"trim_tree": true` to the `quality-control` context definition for `hypetrain-backend`.
	```json
	"quality-control": {
	  "description": "Code quality, validation, and checking tools configuration",
	  "trim_tree": true, // <-- New flag
	  "include_patterns": [".github/workflows/*.yml", ...],
	  "exclude_patterns": ["node_modules/**", "src/**", ...]
	}
	```

- **B. Script Modification (`code2prompt.sh`):**
	- **New Function `trim_project_tree()`:**
		- Takes output file path as argument.
		- Identifies the end of the tree structure (e.g., looking for the last line starting with tree characters like `│`, `├`, `└` or a suitable marker like the start of actual file content listings).
		- Creates a temporary file.
		- Writes a minimal header (e.g., "Project Path: ...", "Trimmed File Content:") to the temp file.
		- Appends content from the original file *after* the detected tree section to the temp file.
		- Replaces the original file with the temp file.
		- Initial logic attempted to find last tree char line: `grep -n "^[[:space:]]*[│├└]" "$file_path" | tail -1 | cut -d: -f1`
		- **Refinement for tree cutting:** The key challenge was reliably finding where the tree ends and actual file content begins. `code2prompt` outputs the tree, then a blank line, then `filename1:`, then ```code```, etc. The cut should happen *before* the first actual `filename:` line that is not part of the tree display.
		- **Revised Cut Logic (Conceptual):** Keep header lines (Project Path, Source Tree). Then, find the line that transitions from tree drawing characters to the first *actual included file's header* (e.g., `package.json:`). The lines *before* this first actual file content header, which are part of the extensive tree, are removed.

	- **Integration in `ccode2prompt` command logic:**
		- After `code2prompt "${CMD_ARGS[@]}"` successfully executes:
		- Python snippet reads `trim_tree` flag from `includes_code2prompt_default.json` for the current project & context.
		- If `TRIM_TREE` is true, `trim_project_tree "$OUTPUT_FILE"` is called.

#### 4. 🧪 **Testing & Refinement:**
- **Initial Test (with `trim_tree: true`):**
	- `bash automations/code2prompt.sh ccode2prompt hypetrain-backend quality-control`
	- **Result:** File size drastically reduced (e.g., from 272KB to ~4KB-10KB).
	- **Observation:** The `trim_project_tree` function successfully removed the bulk of the tree.
- **Content Verification:**
	- Checked the trimmed file: `head /Users/user/____Sandruk/___PKM/temp/code2prompt/cc2p_hypetrain-backend_quality-control.txt`.
	- **Problem:** Initial trimming was too aggressive or based on flawed marker, potentially removing file content headers or leaving only the new minimal header. The key is to correctly identify the *start of the actual concatenated file content* section that `code2prompt` generates *after* its visual tree.
	- `code2prompt` output structure:
		1. Project Path: ...
		2. Source Tree:
		3. ```
		4. extensive tree drawing
		5. ```
		6. (blank line)
		7. `ACTUAL_FILE_1_PATH:`
		8. ```language or blank
		9. content of file 1
		10. ```
		11. `ACTUAL_FILE_2_PATH:`
		12. ...
	- **Refined `trim_project_tree` logic:** The goal is to preserve lines 1-3, and then everything from line 7 onwards, effectively removing lines 4-6 (the tree drawing itself and its ``` encapsulation if present, plus the separating blank line). A simpler approach for trimming: find the *first instance* of a line matching a file path followed by a colon (e.g., `^[^│├└[:space:]][^:]*:`) *after* the "Source Tree:" block, and cut from "Source Tree:" block end to just before this line.

#### 5. ✅ **Outcome & Verification:**
- **Final Test Result:** File size for `quality-control` context significantly reduced (e.g., 272KB to a few KB, depending on actual content of included files).
- **Content:** The trimmed file now contains a minimal header and the actual content of the files specified in `include_patterns`, without the extensive visual tree of the entire project.
- **Example of trimmed output start:**
  ```
  Project Path: hypetrain-backend
  Source Tree: (Content from this point is selectively included based on patterns)

  .github/workflows/build-and-push-backend-api-hypetrain.yml:
  ```yaml
  # content of workflow file
  ```
  package.json:
  ```json
  # content of package.json
  ```
  ...
  ```
- **Token Count:** Dramatically reduced, making it suitable for AI context windows.

---

### 🔑 **Key Learnings & Decisions:**

- `code2prompt`'s default behavior of printing the full visual tree is the primary source of bloat for selectively included contexts.
- Post-processing the output file is an effective workaround.
- A configuration flag (`trim_tree`) provides flexibility.
- Reliably identifying the *exact* end of the tree and start of *actual file content* in the `code2prompt` output is crucial for the trimming logic. The section with actual file contents is *not* simply appended after the visual tree; the visual tree *is* the primary output if no files are matched by includes or if only a few are. The key is that the content of *included files* is appended *after* the tree. The trimmer should remove the tree but keep these appended file contents.

---

### ✅ **Checklist of Actions Taken:**

- [x] Analyzed `code2prompt` output behavior with include/exclude patterns.
- [x] Confirmed full tree display is the root cause of large file size.
- [x] Designed a tree-trimming solution via post-processing.
- [x] Added `trim_tree` flag to `includes_code2prompt_default.json`.
- [x] Implemented `trim_project_tree()` function in `code2prompt.sh`.
- [x] Integrated `trim_tree` logic into `ccode2prompt` command.
- [x] Tested and verified significant file size reduction.
- [x] Refined trimming logic to ensure actual file content is preserved.

---
