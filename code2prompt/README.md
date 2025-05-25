# Code2Prompt Automation System

Enhanced automation system for [code2prompt](https://code2prompt.dev/) with project-based configuration and one-click context generation.

## Features

- **Project-based Configuration**: Define projects with multiple contexts in JSON
- **Smart Filtering**: Pre-configured include/exclude patterns for different contexts
- **Template Integration**: Support for code2prompt templates
- **One-click Aliases**: Quick access to specific project contexts
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

# Generate context for a project
cc2p hypetrain-backend source

# Generate with specific template
cc2p hypetrain-backend source --template=document

# Generate with timestamp
cc2p hypetrain-backend source --timestamp
```

### Quick Project Aliases

```bash
# HypeTrain Backend
ht-backend-source      # Main source code
ht-backend-libs        # Shared libraries
ht-backend-cqrs        # CQRS library only
ht-backend-events      # Integration events
ht-backend-infra       # Infrastructure files
ht-backend-full        # Complete project

# HypeTrain Frontend
ht-frontend-source     # Frontend source
ht-frontend-components # React components
ht-frontend-infra      # Frontend config
```

### Legacy Commands (still available)

```bash
c2p <folder>           # Basic code2prompt
treec2p <folder>       # Tree structure
bc2p <file>            # Batch processing
```

## Configuration

### Project Structure

```json
{
  "projects": {
    "project-name": {
      "project_path": "/path/to/project",
      "default_template": "document-the-code.hbs",
      "contexts": {
        "context-name": {
          "description": "Context description",
          "include_patterns": ["src/**/*.ts"],
          "exclude_patterns": ["**/*.test.ts"]
        }
      }
    }
  }
}
```

### Available Contexts

#### Backend Projects
- **source**: Main source code (TypeScript files)
- **libs**: Shared libraries
- **infrastructure**: Config files, Docker, package.json
- **tests**: Test files only
- **full**: Complete project overview

#### Frontend Projects
- **source**: React/TypeScript source
- **components**: UI components
- **infrastructure**: Build configs, package.json
- **styles**: CSS/SCSS files

### Templates

Configured templates in `global_settings.templates`:
- **document**: Code documentation
- **security**: Security vulnerability analysis
- **cleanup**: Code quality improvements
- **bugs**: Bug fixing
- **performance**: Performance optimization
- **readme**: README generation

## Examples

### Real-world Usage

```bash
# Get CQRS library context for documentation
ht-backend-cqrs --template=document

# Analyze security in frontend components
cc2p hypetrain-frontend components --template=security

# Get infrastructure overview with timestamp
ht-backend-infra --timestamp

# Full backend analysis for AI agent
ht-backend-full --template=document --timestamp
```

### Output Files

Files are saved to `/Users/user/____Sandruk/___PKM/temp/code2prompt/`:
- `cc2p_hypetrain-backend_source.txt`
- `cc2p_hypetrain-backend_source_2024-01-21_14-30.txt` (with timestamp)

## Advanced Features

### Custom Contexts

Add new contexts to your project configuration:

```json
"api-only": {
  "description": "API endpoints only",
  "include_patterns": [
    "src/controllers/**/*.ts",
    "src/routes/**/*.ts",
    "src/middleware/**/*.ts"
  ],
  "exclude_patterns": ["**/*.test.ts"]
}
```

### Global Excludes

Common patterns excluded from all contexts:
- `node_modules/**`
- `.git/**`
- `*.log`
- `coverage/**`
- `.DS_Store`

### Template Customization

Reference templates by name or path:
```bash
cc2p project-name context --template=custom-template.hbs
cc2p project-name context --template=/path/to/template.hbs
```

## Integration with AI Agents

Perfect for generating context files for AI coding assistants:

1. **Quick Context**: `ht-backend-source` for current work
2. **Full Analysis**: `ht-backend-full --template=document` for comprehensive understanding
3. **Specific Focus**: `ht-backend-cqrs` for library-specific tasks
4. **Security Review**: `ht-backend-full --template=security` for security analysis

## Troubleshooting

### Common Issues

1. **Project not found**: Check project name with `c2p-projects`
2. **Context not found**: Check available contexts with `c2p-contexts project-name`
3. **Path doesn't exist**: Verify `project_path` in configuration
4. **Python errors**: Ensure Python 3 is available

### Debug Mode

Add debug output by modifying the script to include:
```bash
set -x  # Enable debug mode
```

## Contributing

To add new projects:
1. Add project configuration to `includes_code2prompt_default.json`
2. Create appropriate contexts for the project type
3. Add quick aliases to `setup_aliases.sh` if needed

## Related

- [Code2Prompt Documentation](https://code2prompt.dev/docs/)
- [Code2Prompt Templates](https://code2prompt.dev/docs/tutorials/learn_templates/)
- [Code2Prompt Filtering](https://code2prompt.dev/docs/tutorials/learn_filters/) 