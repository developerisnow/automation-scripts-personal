#!/usr/bin/env zsh
# 🌍 ENVIRONMENT VARIABLES - Переменные окружения для приложений
# ==============================================================
# Всё что не PATH и не базовые системные переменные

# 🤖 AI/LLMs Configuration
# ------------------------
# OpenAI
export OPENAI_API_KEY=""  # Заполни своим ключом
export OPENAI_ORG_ID=""

# Anthropic Claude
export ANTHROPIC_API_KEY=""

# OpenRouter
export OPENROUTER_API_KEY=""

# Local LLMs
export OLLAMA_HOST="http://localhost:11434"
export LLAMAFILE_HOST="http://localhost:8080"

# 📝 Obsidian & PKM
# -----------------
export OBSIDIAN_VAULT_PATH="$HOME/____Sandruk/PKM"
export SECOND_BRAIN_PATH="$HOME/____Sandruk/PKM/__SecondBrain"
export DAILY_NOTES_PATH="$SECOND_BRAIN_PATH/Dailies"

# 🚂 Project-specific
# -------------------
# HypeTrain
export HYPETRAIN_HOME="$HOME/__Repositories/HypeTrain"
export HYPETRAIN_ENV="development"  # или production

# AirPG
export AIRPG_HOME="$HOME/__Repositories/LLMs-airpg__belbix-master-week6-1"

# TaskMaster
export TASKMASTER_HOME="$HOME/__Repositories/claude-task-master"

# 🐳 Docker
# ---------
export DOCKER_BUILDKIT=1  # Включить BuildKit
export COMPOSE_DOCKER_CLI_BUILD=1
export COMPOSE_HTTP_TIMEOUT=120

# 📊 Database URLs (для локальной разработки)
# -------------------------------------------
# export DATABASE_URL="postgresql://user:password@localhost:5432/mydb"
# export REDIS_URL="redis://localhost:6379"
# export MONGODB_URI="mongodb://localhost:27017/mydb"

# 🔐 Secrets & Tokens
# -------------------
# GitHub
export GITHUB_TOKEN=""
export GH_TOKEN="$GITHUB_TOKEN"  # Для gh CLI

# GitLab
export GITLAB_TOKEN=""

# Telegram
export TELEGRAM_BOT_TOKEN=""
export TELEGRAM_CHAT_ID=""

# 🌐 API Keys
# -----------
# Notion
export NOTION_API_KEY=""
export NOTION_DATABASE_ID=""

# Airtable
export AIRTABLE_API_KEY=""
export AIRTABLE_BASE_ID=""

# Todoist
export TODOIST_API_TOKEN=""

# 📱 Development Flags
# --------------------
export NODE_ENV="development"
export DEBUG="*"  # Включить все debug логи (осторожно, много вывода!)
# export DEBUG="app:*"  # Только для своего приложения

# Rust
export RUST_BACKTRACE=1  # Показывать backtrace при panic
export CARGO_HOME="$HOME/.cargo"

# Python
export PYTHONDONTWRITEBYTECODE=1  # Не создавать .pyc файлы
export PYTHONUNBUFFERED=1  # Unbuffered output
export PIPENV_VENV_IN_PROJECT=1  # Создавать venv в папке проекта

# 🎨 Terminal & UI
# ----------------
export BAT_THEME="TwoDark"  # Тема для bat (better cat)
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"

# Ripgrep
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/config"

# 📧 Email & Communication
# ------------------------
export EMAIL="your-email@example.com"
export FULL_NAME="Your Name"

# 🌍 Locale & Timezone
# --------------------
export TZ="Europe/Moscow"  # Твой часовой пояс

# 💾 Backup & Sync
# ----------------
export BACKUP_DIR="$HOME/NextCloud2/Backups"
export SYNC_DIR="$HOME/NextCloud2"

# 🔧 Build Tools
# --------------
export MAKEFLAGS="-j$(sysctl -n hw.ncpu)"  # Параллельная компиляция

# 📊 Monitoring & Logging
# -----------------------
export LOG_LEVEL="info"  # debug, info, warn, error
export LOG_DIR="$HOME/____Sandruk/logs"

# 🎮 Fun stuff
# ------------
export FORTUNE_FILE="$HOME/.config/fortune/quotes"
export COWPATH="$HOME/.config/cowsay/cows"

# 🔍 Search
# ---------
export GREP_OPTIONS="--color=auto"
export GREP_COLOR="1;32"

# 📝 Templates
# ------------
export TEMPLATE_DIR="$HOME/____Sandruk/templates"

# 🚀 Custom Functions Path
# ------------------------
export FPATH="$HOME/.config/zsh/functions:$FPATH"

# 🔧 Utility function to list all env vars
# -----------------------------------------
envlist() {
    echo "🌍 Custom Environment Variables:"
    env | grep -E "^(OPENAI|ANTHROPIC|HYPETRAIN|AIRPG|TASKMASTER|OBSIDIAN|TELEGRAM|NOTION)" | sort
}

# Check if important vars are set
checkenv() {
    local vars=("OPENAI_API_KEY" "ANTHROPIC_API_KEY" "GITHUB_TOKEN")
    echo "🔍 Checking important environment variables:"
    for var in "${vars[@]}"; do
        if [[ -n "${(P)var}" ]]; then
            echo "✅ $var is set"
        else
            echo "❌ $var is NOT set"
        fi
    done
}

# === Migrated from old .zshrc ===
export PATH="/Users/user/bin:/Users/user/.local/bin:$PATH"
export NVM_DIR="$HOME/.nvm"
export PNPM_HOME="/Users/user/Library/pnpm"
export PATH="$HOME/.pyenv/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$HOME/.local/bin:$PATH"
export OPENAI_API_KEY='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'
#export OPENAI_API_KEY='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'
#export OPENAI_API_KEY='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'
#export OPENAI_API_KEY='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'
# export OPENAI_API_KEY='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'
## alexabook key3
# export OPENAI_API_KEY='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'
## alexabook1 newApi1
# Contact@grplabs.com or jackstonedev@gmail.com api-key of Anthropic don't remember exactly
# export ANTHROPIC_API_KEY='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'
# Sergey Sadovnikov api-key of Anthropic
# export ANTHROPIC_API_KEY='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'
# Hypetrain aalexswww@hypetrain.io
# Gemini API key annakult36389@gmail.com
export GEMINI_API_KEY='AIzaSyAJ12T7aYqjuDk79QmI0Qbjw5_vYQ6C5Go'
# Gemini API key aalexswww@gmail.com
# export GEMINI_API_KEY='AIzaSyAc5p6BZ9-D9OzlxUetmtiO5k7p9FtWNSo'
export ANTHROPIC_API_KEY='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'
export DEEPSEEK_API_KEY='sk-19d4b9c3778b49248d679gi64bf9b1aa39'
export PERPLEXITY_API_KEY='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'
export HYPERBOLIC_DEEPSEEK_API_KEY='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJqYWNrc3RvbmVkZXZAZ21haWwuY29tIiwiaWF0IjoxNzM2NjA4ODM1fQ.GDWJ_7sa9dwqRBKWi241gjh8UXPkLTwSkpkOz1eqDko'
export REPLICATE_API_TOKEN='r8_36H3VUB6GAj5PzxHOMU4DTGfWrRybVI4TVLYD'
export SERPER_API_KEY='ef7e18fd3f62a1f37af0bad488aa0ad3f1ffe191'
export cookie='__cf_bm=2bpzdrBeBuB.aRac3yZ6B3tK2DZbYTO3veunI5Jmwzw-1692358287-0-AetIMxBE7zgUFvDn8BDdBVLg3o02zO6FKYIngnGpbhYBs1naexSavJ/hrqefYw4HTuOZi1ov4cWziH03Y8y73b8=; cf_clearance=Yp3Uq.A9exauy.yAwJ7ZolpKgcDPBC6YYLTIXaPsHj8-1692358288-0-1-d32615c.97def31e.5a333ebc-0.2.1692358288; sessionKey=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; intercom-device-id-lupk8zyo=e8003654-7913-4d47-869f-9d2923f832b5; intercom-session-lupk8zyo=TW1lS0ZyQkY4VXlyS05NcHJOaGwxazVheXplYytwSXk2VWhuaDROQ041RGtVcVl2bXBjdnFNK0ZjZnBlV2hiWC0tcmJ2ZEcxb3ZIRmtUaXVWdDRQWEx5dz09--672b812caf992d458ac3986a1aa1a16c38c97650'
export PATH="/Users/user/.codeium/windsurf/bin:$PATH"
export PATH="/Users/user/.codeium/windsurf/bin:$PATH"
export PATH="$PATH:/Users/user/.cache/lm-studio/bin"
export PATH=$PATH:$(go env GOPATH)/bin
export DEEPSEEK_API_KEY=sk-19d4b9c3778b49248d67964bf9b1aa39
export CRAWL4AI_API_TOKEN=your_secret_token
export O2P_OUTPUT_DIR="/Users/user/____Sandruk/___PKM/temp"
export OBSIDIAN_VAULT_PATH="/Users/user/____Sandruk/___PKM"
export PATH="/opt/homebrew/bin:$PATH"
