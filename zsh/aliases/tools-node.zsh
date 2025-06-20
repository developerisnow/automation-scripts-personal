#!/usr/bin/env zsh
# 🛠️ DEVELOPMENT TOOLS - NPM, Yarn, PNPM, etc.
# ============================================

# 📦 NPM
# ------
alias ni='npm install'
alias nid='npm install --save-dev'
alias nig='npm install --global'
alias nr='npm run'
alias nrs='npm run start'
alias nrb='npm run build'
alias nrd='npm run dev'
alias nrt='npm run test'
alias nrl='npm run lint'
alias nrw='npm run watch'

# List scripts
alias nls='npm run'
alias scripts='cat package.json | jq .scripts'

# 🧶 Yarn
# -------
alias y='yarn'
alias ya='yarn add'
alias yad='yarn add --dev'
alias yr='yarn run'
alias ys='yarn start'
alias yb='yarn build'
alias yd='yarn dev'
alias yt='yarn test'
alias yl='yarn lint'

# 📦 PNPM
# -------
alias pn='pnpm'
alias pni='pnpm install'
alias pna='pnpm add'
alias pnad='pnpm add --save-dev'
alias pnr='pnpm run'
alias pns='pnpm start'
alias pnb='pnpm build'
alias pnd='pnpm dev'
alias pnt='pnpm test'


# 🎯 Task runners
# ---------------
alias j='just'  # If using just
alias t='task'  # If using go-task

# 📝 Code formatting
# ------------------
alias fmt='prettier --write .'
alias fmtcheck='prettier --check .'

# 🔍 Linting
# ----------
alias lint='eslint .'
alias lintfix='eslint . --fix'

# 🧹 Clean node_modules
# ---------------------
alias cleanmodules='find . -name "node_modules" -type d -prune -exec rm -rf {} +'
alias cleancache='npm cache clean --force && yarn cache clean'

# 📊 Package info
# ---------------
alias pkgsize='npx pkg-size'
alias bundlesize='npx bundlesize'
alias analyze='npx source-map-explorer'

# 🔧 Useful functions
# -------------------
# Check outdated packages
outdated() {
    echo "📦 NPM outdated:"
    npm outdated
    echo "\n🧶 Yarn outdated:"
    yarn outdated
}

# Quick project setup
quickstart() {
    local project_name="$1"
    if [ -z "$project_name" ]; then
        echo "Usage: quickstart <project-name>"
        return 1
    fi
    mkdir "$project_name" && cd "$project_name"
    npm init -y
    git init
    echo "node_modules/\n.env\n.DS_Store" > .gitignore
    echo "✅ Project $project_name created!"
}

# 🌐 Browser sync
# ---------------
alias serve='npx serve'
alias bs='browser-sync start --server --files "**/*"'

# 📱 React Native
# ---------------
alias rn='npx react-native'
alias rni='npx react-native run-ios'
alias rna='npx react-native run-android'
alias rnlink='npx react-native link'
