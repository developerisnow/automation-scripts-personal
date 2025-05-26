# Code2Prompt Automation: System Overview & Feature Reference

**Version:** 2.1.0 (Enhanced with Tree Trimming)
**Last Updated:** May 25, 2025
**Purpose:** This document outlines the features, configuration, and usage of the enhanced `code2prompt` automation scripts.

---

## 🚀 Core Functionality

The system provides a powerful wrapper around the `code2prompt` utility to generate AI-ready context files from codebases. Key enhancements include:

- **Project-Based Configuration:** Manage multiple projects and their specific context generation rules from a central JSON file (`includes_code2prompt_default.json`).
- **Targeted Contexts:** Define multiple "contexts" per project (e.g., `source`, `infrastructure`, `quality-control`, `full-codebase`) with specific `include_patterns` and `exclude_patterns`.
- **Smart Tree Trimming:** For contexts where the full project tree is excessive (like `quality-control`), a `trim_tree: true` flag in the configuration will automatically remove the visual tree structure, leaving only the content of included files. This drastically reduces file size and token count.
- **Professional Templates:** Integrates with a library of pre-defined `code2prompt` templates (e.g., for documentation, security analysis, refactoring). The system provides template listing, info, and smart recommendations for compatibility with project contexts.
- **CLI & Aliases:** Offers a command-line interface (`code2prompt.sh`) with commands like `ccode2prompt <project> [context]` and convenient shell aliases (`setup_aliases.sh`) for quick, one-click context generation (e.g., `ht-backend-quality`).

---

## ✨ Key Features (v2.1.0)

1.  **Multi-Project Management (`includes_code2prompt_default.json`):**
    *   Define multiple projects with their root paths.
    *   Example: `hypetrain-backend`, `hypetrain-frontend`.

2.  **Context Definitions (per project):**
    *   Each project can have multiple named contexts (e.g., `source`, `libs`, `cqrs`, `infrastructure`, `tests`, `quality-control`, `full`).
    *   Each context specifies:
        *   `description`: Human-readable purpose.
        *   `include_patterns`: Comma-separated list of glob patterns for files/directories to *include*.
        *   `exclude_patterns`: Comma-separated list of glob patterns to *exclude*.
        *   `trim_tree` (boolean, optional): If `true`, the visual project tree is removed from the output. Defaults to `false`.

3.  **Smart Tree Trimming (`trim_tree: true`):**
    *   Reduces output file size significantly by removing the visual directory tree.
    *   Preserves only the concatenated content of the files matched by `include_patterns`.
    *   **Impact:** `quality-control` context for `hypetrain-backend` reduced from ~272KB to ~4-10KB.

4.  **Template Integration:**
    *   Uses templates defined in `global_settings.templates` and `global_settings.template_contexts` in the JSON config.
    *   Supports ~14 professional templates (documentation, security, performance, etc.).
    *   Commands: `listtemplates`, `templateinfo <template>`, `smarttemplate <project> <context> <template>`.
    *   `ccode2prompt` accepts `--template=<template_name>`.

5.  **CLI (`code2prompt.sh`):**
    *   `ccode2prompt <project_name> [context_name] [--timestamp] [--template=<template_name>]`:
        *   Generates context for the specified project and context.
        *   `context_name` defaults to `source` if not provided.
        *   `--timestamp` adds a timestamp to the output filename.
        *   `--template` applies a specified `code2prompt` template.
    *   `listprojects`: Lists all configured projects.
    *   `listcontexts <project_name>`: Lists available contexts for a project.
    *   Other helper commands (see script source or help output).

6.  **Shell Aliases (`setup_aliases.sh`):**
    *   Provides quick shortcuts, e.g.:
        *   `ht-backend-source` (generates `source` context for `hypetrain-backend`)
        *   `ht-backend-quality` (generates `quality-control` context, trimmed)
        *   `ht-backend-security` (generates `infrastructure` context with `security-vulnerabilities` template)
        *   `c2p-projects`, `c2p-contexts ht-backend`, `c2p-templates` for discovery.

7.  **Specialized `quality-control` Context:**
    *   Designed to capture configuration files for linters, formatters, CI/CD workflows, `package.json`, Dockerfiles, etc.
    *   `trim_tree: true` is typically enabled for this context to keep it concise.

---

## ⚙️ Configuration (`includes_code2prompt_default.json` Structure)

```json
{
  "global_settings": {
    "static_dir": "/path/to/your/static/output/directory", // Base for c2p outputs
    "templates": {
      "document-the-code": "path/to/templates/document-the-code.md",
      // ... other template name to file path mappings
    },
    "template_contexts": {
      "document-the-code": {
        "description": "Generates detailed code documentation.",
        "best_for": ["source", "full-codebase", "libs"],
        "output_suffix": "_docs"
      },
      // ... other template metadata
    }
  },
  "projects": {
    "hypetrain-backend": {
      "path": "/Users/user/__Repositories/HypeTrain/repositories/hypetrain-backend",
      "contexts": {
        "source": {
          "description": "Core application source code (excluding tests, libs)",
          "include_patterns": ["apps/hypetrain-api/src/**/*"],
          "exclude_patterns": ["**/__tests__/**", "**/*.spec.ts", "**/*.test.ts"]
        },
        "quality-control": {
          "description": "Code quality, validation, and checking tools configuration",
          "trim_tree": true,
          "include_patterns": [
            ".github/workflows/*.yml", ".github/workflows/*.yaml", "renovate.json", 
            "package.json", "README.md", "lefthook.yml", ".eslintrc.js", ".gitignore",
            "docker-compose.yaml", "Dockerfile", "tsconfig.base.json", "jest.config.js"
          ],
          "exclude_patterns": ["node_modules/**", "dist/**", "src/**", "libs/**", "apps/**"]
        },
        // ... other contexts like 'infrastructure', 'full-codebase', 'libs'
      }
    },
    // ... other projects
  }
}
```

---

## 🛠️ Usage Examples (CLI & Aliases)

**Using `ccode2prompt` command:**

1.  **Generate default (`source`) context for `hypetrain-backend`:**
    `bash automations/code2prompt.sh ccode2prompt hypetrain-backend`

2.  **Generate `quality-control` context (trimmed) for `hypetrain-backend`:**
    `bash automations/code2prompt.sh ccode2prompt hypetrain-backend quality-control`

3.  **Generate `infrastructure` context for `hypetrain-backend` with the `security-vulnerabilities` template:**
    `bash automations/code2prompt.sh ccode2prompt hypetrain-backend infrastructure --template=security-vulnerabilities`

**Using Aliases (after sourcing `setup_aliases.sh`):**

1.  `ht-backend-source`
2.  `ht-backend-quality`
3.  `ht-backend-security`
4.  `c2p-projects` (list projects)
5.  `c2p-contexts ht-backend` (list contexts for `hypetrain-backend`)
6.  `c2p-templates` (list available templates)

---

## 📜 Script Components

-   **`code2prompt.sh`**: Main script handling logic, command parsing, and `code2prompt` execution.
-   **`includes_code2prompt_default.json`**: Central configuration file for projects, contexts, and global settings.
-   **`setup_aliases.sh`**: Script to define convenient shell aliases for common operations.
-   **`templates/` directory**: Contains the Markdown template files for `code2prompt`.

---

## 📈 Future Considerations / Potential Enhancements

- **Content Validation Post-Trim:** Verify that essential content isn't accidentally removed by trimming.
- **More Granular Trimming:** Options for what to trim (e.g., keep a shallow tree).
- **Dynamic Exclude Based on `.gitignore`:** Automatically incorporate project's `.gitignore`.
- **Interactive Mode:** CLI prompts for project/context/template selection.

--- 