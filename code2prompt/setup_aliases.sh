#!/bin/bash

# Setup aliases for code2prompt automation
# Run this script to add aliases to your shell configuration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODE2PROMPT_SCRIPT="$SCRIPT_DIR/../code2prompt.sh"

# Detect shell
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
    SHELL_CONFIG="$HOME/.bashrc"
else
    echo "Unsupported shell: $SHELL"
    exit 1
fi

echo "Setting up code2prompt aliases in $SHELL_CONFIG"

# Create aliases
cat >> "$SHELL_CONFIG" << 'EOF'

# Code2Prompt Automation Aliases
alias c2p='bash ~/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/code2prompt.sh'
alias cc2p='bash ~/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/code2prompt.sh ccode2prompt'
alias treec2p='bash ~/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/code2prompt.sh treecode2prompt'
alias bc2p='bash ~/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/code2prompt.sh bcode2prompt'

# Quick project context aliases
alias c2p-projects='bash ~/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/code2prompt.sh listprojects'
alias c2p-contexts='bash ~/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/code2prompt.sh listcontexts'

# Quick hypetrain contexts
alias ht-backend-source='cc2p hypetrain-backend source'
alias ht-backend-libs='cc2p hypetrain-backend libs'
alias ht-backend-cqrs='cc2p hypetrain-backend cqrs'
alias ht-backend-events='cc2p hypetrain-backend integration-events'
alias ht-backend-infra='cc2p hypetrain-backend infrastructure'
alias ht-backend-full='cc2p hypetrain-backend full'

alias ht-frontend-source='cc2p hypetrain-frontend source'
alias ht-frontend-components='cc2p hypetrain-frontend components'
alias ht-frontend-infra='cc2p hypetrain-frontend infrastructure'

EOF

echo "Aliases added to $SHELL_CONFIG"
echo ""
echo "Available aliases:"
echo "  c2p <folder>                    - Basic code2prompt"
echo "  cc2p <project> [context]        - Config-based code2prompt"
echo "  treec2p <folder>                - Tree structure generation"
echo "  bc2p <file>                     - Batch processing"
echo "  c2p-projects                    - List available projects"
echo "  c2p-contexts <project>          - List contexts for project"
echo ""
echo "Quick project aliases:"
echo "  ht-backend-source               - HypeTrain backend source code"
echo "  ht-backend-libs                 - HypeTrain backend libraries"
echo "  ht-backend-cqrs                 - CQRS library only"
echo "  ht-backend-events               - Integration events only"
echo "  ht-backend-infra                - Infrastructure files"
echo "  ht-backend-full                 - Complete backend"
echo ""
echo "  ht-frontend-source              - Frontend source code"
echo "  ht-frontend-components          - React components"
echo "  ht-frontend-infra               - Frontend infrastructure"
echo ""
echo "Reload your shell or run: source $SHELL_CONFIG" 