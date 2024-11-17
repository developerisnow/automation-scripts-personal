#!/bin/bash

echo "Checking installed JavaScript package managers..."

# Using parallel arrays
pkg_managers=(npm yarn pnpm bun volta fnm nvm)
pkg_commands=("--version" "--version" "--version" "--version" "--version" "--version" "--version")

echo "Installed package managers:"
echo "------------------------"

for i in "${!pkg_managers[@]}"; do
    manager="${pkg_managers[$i]}"
    command="${pkg_commands[$i]}"
    
    # Special case for NVM since it's a shell function
    if [[ "$manager" == "nvm" ]]; then
        if [ -n "$NVM_DIR" ] && [ -f "$NVM_DIR/nvm.sh" ]; then
            version=$(. "$NVM_DIR/nvm.sh" && nvm --version 2>/dev/null)
            if [ -n "$version" ]; then
                echo "✅ $manager (version: $version) (via $(if [[ "$(readlink "$NVM_DIR/nvm.sh")" == *"/homebrew/"* ]]; then echo "Homebrew"; else echo "curl install script"; fi))"
                continue
            fi
        fi
    elif command -v "$manager" >/dev/null 2>&1; then
        version=$($manager $command 2>/dev/null)
        
        # Check installation method
        install_method=""
        
        # Check Homebrew
        if [ -L "$(which $manager)" ] && [[ "$(readlink $(which $manager))" == *"/homebrew/"* ]]; then
            install_method="(via Homebrew)"
        # Check for NVM installation
        elif [[ "$manager" == "npm" ]] && [[ -n "$NVM_DIR" ]]; then
            install_method="(via NVM)"
        fi
        
        echo "✅ $manager (version: $version) $install_method"
    else
        echo "❌ $manager (not installed)"
    fi
done

# Additional NVM information if installed
if [ -n "$NVM_DIR" ] && [ -f "$NVM_DIR/nvm.sh" ]; then
    echo -e "\nNVM Additional Info:"
    echo "------------------------"
    echo "NVM Directory: $NVM_DIR"
    echo "Current Node: $(. "$NVM_DIR/nvm.sh" && nvm current)"
    echo "Installed Node versions:"
    . "$NVM_DIR/nvm.sh" && nvm ls --no-colors | grep -v "N/A"
fi