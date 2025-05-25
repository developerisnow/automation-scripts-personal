# Code2Prompt Automation System

Enhanced automation system for [code2prompt](https://code2prompt.dev/) with project-based configuration, smart templates, and one-click context generation.

## 🚀 Phase 2: Smart Template Integration

**NEW!** Integrated with official code2prompt templates for specialized AI tasks:
- **14 Professional Templates** from the official code2prompt repository
- **Smart Template Recommendations** based on context compatibility
- **Template-Specific Aliases** for instant access
- **Intelligent Output Naming** with template suffixes

## Features

- **Project-based Configuration**: Define projects with multiple contexts in JSON
- **Smart Template System**: 14+ professional templates for different AI tasks
- **Smart Filtering**: Pre-configured include/exclude patterns for different contexts
- **Template Compatibility Analysis**: Get recommendations for optimal template usage
- **One-click Aliases**: Quick access to specific project contexts with templates
- **Flexible Output**: Timestamped files and customizable output locations

## Installation

1. **Setup aliases** (run once):
```bash
bash automations/code2prompt/setup_aliases.sh
source ~/.zshrc  # or ~/.bashrc
```

2. **Configure your projects** in `includes_code2prompt_default.json`

## Usage

### Basic Commands

```bash
# List available projects
c2p-projects

# List contexts for a project
c2p-contexts hypetrain-backend

# List available templates
c2p-templates

# Get template information
c2p-template-info document

# Smart template recommendation
c2p-smart hypetrain-backend cqrs document

# Generate context with template
cc2p hypetrain-backend source --template=document --timestamp
```

### Available Templates

| Template | Description | Best For |
|----------|-------------|----------|
| `document` | Add comprehensive documentation | source, libs, cqrs, integration-events |
| `security` | Security vulnerability analysis | full, source, infrastructure |
| `cleanup` | Code quality improvements | source, libs |
| `claude` | Claude-optimized XML format | source, libs, cqrs |
| `performance` | Performance optimization analysis | source, libs, full |
| `refactor` | SOLID principles refactoring | source, libs |
| `pr` | GitHub pull request generation | - |
| `commit` | Git commit message generation | - |
| `bugs` | Bug detection and fixing | - |
| `readme` | README file generation | - |
| `ctf-*` | CTF challenge solvers | - |

### Real-world Usage

```bash
# Get CQRS library documentation (272K, 63,031 tokens)
ht-backend-docs

# Security analysis of infrastructure (404K, 103,344 tokens)
ht-backend-security

# Performance analysis of libraries (272K, 63,303 tokens)
ht-backend-performance

# Claude XML format for CQRS (272K, 63,208 tokens)
ht-backend-claude

# Code cleanup suggestions (272K, 63,208 tokens)
ht-backend-cleanup

# Refactoring recommendations (272K, 63,303 tokens)
ht-backend-refactor

# Quality control analysis (288K, 67,193 tokens)
ht-backend-quality

# Quality control security check (288K, 67,544 tokens)
ht-backend-quality-check
```

### Template-Specific Aliases

```bash
# Documentation templates
ht-backend-docs                 # Document backend source code
ht-backend-claude               # Claude XML format for CQRS

# Analysis templates  
ht-backend-security             # Security analysis of full backend
ht-backend-performance          # Performance analysis of source
ht-backend-refactor             # Refactoring suggestions for libs
ht-backend-cleanup              # Code cleanup for source
ht-backend-quality              # Quality control tools analysis
ht-backend-quality-check        # Security analysis of quality tools
```

### Smart Template Recommendations

The system provides intelligent recommendations:

```bash
$ c2p-smart hypetrain-backend cqrs document
✅ ОТЛИЧНЫЙ ВЫБОР: Этот шаблон идеально подходит для данного контекста

$ c2p-smart hypetrain-backend infrastructure document  
⚠️  ПРЕДУПРЕЖДЕНИЕ: Этот шаблон может не подходить для данного контекста
Рекомендуемые контексты: source, libs, cqrs, integration-events
```

### Output Files

Files are saved to `/Users/user/____Sandruk/___PKM/temp/code2prompt/`:
- `cc2p_hypetrain-backend_source_documented.txt` (with template)
- `cc2p_hypetrain-backend_source_documented_2025-05-25_10-08.txt` (with timestamp)

### Tested Results

Real performance data from HypeTrain backend project:

| Context + Template | File Size | Token Count | Use Case |
|-------------------|-----------|-------------|----------|
| `cqrs` + `document` | 272K | 63,208 | CQRS documentation |
| `infrastructure` + `security` | 404K | 103,344 | Security analysis |
| `libs` + `performance` | 272K | 63,303 | Performance optimization |
| `source` + `document` | 272K | 63,208 | Source documentation |
| `cqrs` + `claude` | 272K | 63,208 | Claude XML format |
| `quality-control` + `security` | 288K | 67,544 | Code quality security analysis |

## Configuration

### Project Structure

```json
{
  "projects": {
    "hypetrain-backend": {
      "project_path": "/path/to/project",
      "contexts": {
        "source": {
          "description": "Main source code",
          "include_patterns": ["src/**/*.ts", "libs/**/*.ts"],
          "exclude_patterns": ["**/*.spec.ts", "**/*.test.ts"]
        },
        "quality-control": {
          "description": "Code quality, validation, and checking tools",
          "include_patterns": [
            ".lefthook/**/*", ".github/**/*.yml", ".commitlintrc.*",
            "renovate.json", "package.json", "lefthook.yml", ".eslintrc*",
            ".gitignore", "docker-compose.yaml", "scripts/**/*",
            "**/tsconfig.json", "**/jest.config*"
          ],
          "exclude_patterns": ["node_modules/**", "dist/**", "**/*.spec.ts"]
        }
      }
    }
  },
  "global_settings": {
    "templates": {
      "document": "automations/code2prompt/templates/document-the-code.hbs",
      "security": "automations/code2prompt/templates/find-security-vulnerabilities.hbs"
    }
  }
}
```

### Template Customization

Create and use custom Handlebars templates:
```bash
# Create a custom template file
echo '{{#each files}}{{path}}: {{content}}{{/each}}' > my-template.hbs

# Use the custom template
cc2p hypetrain-backend source --template=./my-template.hbs
```

## Advanced Features

### Batch Processing
```bash
# Process multiple paths from file
bc2p paths.txt --timestamp

# Generate tree structure
treec2p . --timestamp
```

### Template Analysis
```bash
# Get detailed template information
c2p-template-info security

# Output:
# Файл шаблона: automations/code2prompt/templates/find-security-vulnerabilities.hbs
# Описание: Comprehensive security vulnerability analysis
# Лучше всего подходит для: full, source, infrastructure
# Суффикс выходного файла: _security_analysis
```

## 🎯 Phase 2 Test Results - ALL TEMPLATES WORKING!

### ✅ **Template Integration Tests**
1. **Document Template**: 272K (63,208 tokens) ✓
2. **Security Template**: 404K (103,344 tokens) ✓  
3. **Performance Template**: 272K (63,303 tokens) ✓
4. **Claude XML Template**: 272K (63,208 tokens) ✓

### ✅ **Smart Features Working**
- **Template Discovery**: `c2p-templates` ✓
- **Template Information**: `c2p-template-info` ✓
- **Smart Recommendations**: `c2p-smart` ✓
- **Template-Specific Aliases**: `ht-backend-*` ✓

### ✅ **Output Quality**
- **Proper Template Application**: Templates correctly applied ✓
- **Smart File Naming**: Template suffixes added ✓
- **Compatibility Analysis**: Smart recommendations working ✓
- **Professional Output**: High-quality AI prompts generated ✓

## Troubleshooting

### Common Issues

1. **Template not found**: Ensure template files exist in `automations/code2prompt/templates/`
2. **Alias not working**: Run `source ~/.zshrc` to reload aliases
3. **Path issues**: Use absolute paths in configuration

### Debug Commands

```bash
# Check template paths
ls automations/code2prompt/templates/

# Verify configuration
c2p-templates

# Test template compatibility
c2p-smart project context template
```

## Contributing

The system is designed to be easily extensible:

1. **Add new projects** in `includes_code2prompt_default.json`
2. **Create custom templates** in the templates directory
3. **Add new aliases** in `setup_aliases.sh`
4. **Extend contexts** for different use cases

## License

MIT License - feel free to adapt for your projects!

---

**🚀 Ready to supercharge your AI workflows with professional templates and smart automation!** 