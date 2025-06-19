#!/usr/bin/env zsh
# 🔄 ZSH CONFIG MIGRATION HELPER
# ==============================
# Помогает мигрировать с монолитного .zshrc на модульную структуру
# ADHD-friendly: автоматически категоризирует алиасы!

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Проверка аргументов
if [ $# -eq 0 ]; then
    echo "Usage: $0 <path-to-your-zshrc>"
    echo "Example: $0 /Users/user/Downloads/zshrc_backup.txt"
    exit 1
fi

ZSHRC_PATH="$1"
CONFIG_DIR="$HOME/.config/zsh"

# Проверка существования файла
if [ ! -f "$ZSHRC_PATH" ]; then
    echo -e "${RED}❌ File not found: $ZSHRC_PATH${NC}"
    exit 1
fi

echo -e "${BLUE}🔄 Starting ZSH Config Migration...${NC}"
echo -e "${BLUE}📁 Config directory: $CONFIG_DIR${NC}"

# Создание временных файлов для категорий
TMP_DIR="/tmp/zsh_migration_$$"
mkdir -p "$TMP_DIR"

# Файлы для категорий
GIT_FILE="$TMP_DIR/git.zsh"
DOCKER_FILE="$TMP_DIR/docker.zsh"
NPM_FILE="$TMP_DIR/npm.zsh"
SYSTEM_FILE="$TMP_DIR/system.zsh"
NAV_FILE="$TMP_DIR/navigation.zsh"
PROJECT_FILE="$TMP_DIR/projects.zsh"
OBSIDIAN_FILE="$TMP_DIR/obsidian.zsh"
CRYPTO_FILE="$TMP_DIR/crypto.zsh"
LLMS_FILE="$TMP_DIR/llms.zsh"
FUNCTION_FILE="$TMP_DIR/functions.zsh"
ENV_FILE="$TMP_DIR/env.zsh"
OTHER_FILE="$TMP_DIR/other.zsh"

# Счетчики
declare -A counters
counters[git]=0
counters[docker]=0
counters[npm]=0
counters[system]=0
counters[nav]=0
counters[project]=0
counters[obsidian]=0
counters[crypto]=0
counters[llms]=0
counters[function]=0
counters[env]=0
counters[other]=0

# Функция для определения категории
categorize_line() {
    local line="$1"
    
    # Git aliases
    if [[ "$line" =~ ^alias[[:space:]]+(g[a-z]*=|git) ]]; then
        echo "$line" >> "$GIT_FILE"
        ((counters[git]++))
    # Docker
    elif [[ "$line" =~ ^alias[[:space:]]+(d[a-z]*=|docker|dc=|dps=) ]]; then
        echo "$line" >> "$DOCKER_FILE"
        ((counters[docker]++))
    # NPM/Node
    elif [[ "$line" =~ ^alias[[:space:]]+(npm|yarn|pnpm|node|n[a-z]*=) ]]; then
        echo "$line" >> "$NPM_FILE"
        ((counters[npm]++))
    # System commands
    elif [[ "$line" =~ ^alias[[:space:]]+(ls|ll|la|cat|grep|find|du|df|ps|top|htop|btop) ]]; then
        echo "$line" >> "$SYSTEM_FILE"
        ((counters[system]++))
    # Navigation
    elif [[ "$line" =~ ^alias[[:space:]]+(\.\.|cd|z=|j=|repos|rep|sand|pkm|brain|dl|downloads|tmp|temp) ]]; then
        echo "$line" >> "$NAV_FILE"
        ((counters[nav]++))
    # Projects
    elif [[ "$line" =~ (hypetrain|airpg|taskmaster|tm=|ht=|hype=) ]]; then
        echo "$line" >> "$PROJECT_FILE"
        ((counters[project]++))
    # Obsidian
    elif [[ "$line" =~ (o2p|o2pd|ac2p|c2p|obs-|obsidian) ]]; then
        echo "$line" >> "$OBSIDIAN_FILE"
        ((counters[obsidian]++))
    # Crypto
    elif [[ "$line" =~ ^alias[[:space:]]+.*crypto- ]] || [[ "$line" =~ (eth-|wallet|defi|web3|blockchain) ]]; then
        echo "$line" >> "$CRYPTO_FILE"
        ((counters[crypto]++))
    # LLMs
    elif [[ "$line" =~ ^alias[[:space:]]+.*(LLMs-|llm|aider|claude|gpt|openai) ]]; then
        echo "$line" >> "$LLMS_FILE"
        ((counters[llms]++))
    # Functions
    elif [[ "$line" =~ ^[[:space:]]*function[[:space:]]+ ]] || [[ "$line" =~ ^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*\(\)[[:space:]]*\{ ]]; then
        echo "$line" >> "$FUNCTION_FILE"
        ((counters[function]++))
    # Environment variables
    elif [[ "$line" =~ ^[[:space:]]*export[[:space:]]+ ]]; then
        echo "$line" >> "$ENV_FILE"
        ((counters[env]++))
    # Other aliases
    elif [[ "$line" =~ ^alias[[:space:]]+ ]]; then
        echo "$line" >> "$OTHER_FILE"
        ((counters[other]++))
    fi
}

# Обработка файла
echo -e "${YELLOW}📖 Reading $ZSHRC_PATH...${NC}"
while IFS= read -r line; do
    # Пропускаем пустые строки и комментарии
    if [[ -n "$line" ]] && [[ ! "$line" =~ ^[[:space:]]*# ]]; then
        categorize_line "$line"
    fi
done < "$ZSHRC_PATH"

# Показать статистику
echo -e "\n${GREEN}📊 Migration Statistics:${NC}"
echo -e "${BLUE}Git aliases:${NC} ${counters[git]}"
echo -e "${BLUE}Docker aliases:${NC} ${counters[docker]}"
echo -e "${BLUE}NPM/Node aliases:${NC} ${counters[npm]}"
echo -e "${BLUE}System aliases:${NC} ${counters[system]}"
echo -e "${BLUE}Navigation aliases:${NC} ${counters[nav]}"
echo -e "${BLUE}Project aliases:${NC} ${counters[project]}"
echo -e "${BLUE}Obsidian aliases:${NC} ${counters[obsidian]}"
echo -e "${BLUE}Crypto aliases:${NC} ${counters[crypto]}"
echo -e "${BLUE}LLMs aliases:${NC} ${counters[llms]}"
echo -e "${BLUE}Functions:${NC} ${counters[function]}"
echo -e "${BLUE}Environment vars:${NC} ${counters[env]}"
echo -e "${BLUE}Other aliases:${NC} ${counters[other]}"

# Копировать категоризированные файлы
echo -e "\n${YELLOW}📁 Copying categorized files to $CONFIG_DIR/aliases/...${NC}"

# Navigation aliases
if [ -s "$NAV_FILE" ]; then
    echo -e "\n# === Migrated from old .zshrc ===" >> "$CONFIG_DIR/aliases/navigation.zsh"
    cat "$NAV_FILE" >> "$CONFIG_DIR/aliases/navigation.zsh"
    echo -e "${GREEN}✅ Added ${counters[nav]} navigation aliases${NC}"
fi

# System aliases
if [ -s "$SYSTEM_FILE" ]; then
    echo -e "\n# === Migrated from old .zshrc ===" >> "$CONFIG_DIR/aliases/system.zsh"
    cat "$SYSTEM_FILE" >> "$CONFIG_DIR/aliases/system.zsh"
    echo -e "${GREEN}✅ Added ${counters[system]} system aliases${NC}"
fi

# NPM/Tools aliases
if [ -s "$NPM_FILE" ]; then
    [ ! -f "$CONFIG_DIR/aliases/tools.zsh" ] && echo "#!/usr/bin/env zsh\n# 🛠️ DEVELOPMENT TOOLS\n" > "$CONFIG_DIR/aliases/tools.zsh"
    echo -e "\n# === Migrated from old .zshrc ===" >> "$CONFIG_DIR/aliases/tools.zsh"
    cat "$NPM_FILE" >> "$CONFIG_DIR/aliases/tools.zsh"
    echo -e "${GREEN}✅ Added ${counters[npm]} npm/tools aliases${NC}"
fi

# Добавляем в существующие файлы
if [ -s "$GIT_FILE" ]; then
    echo -e "\n# === Migrated from old .zshrc ===" >> "$CONFIG_DIR/aliases/git.zsh"
    cat "$GIT_FILE" >> "$CONFIG_DIR/aliases/git.zsh"
    echo -e "${GREEN}✅ Added ${counters[git]} git aliases${NC}"
fi

if [ -s "$DOCKER_FILE" ]; then
    [ ! -f "$CONFIG_DIR/aliases/docker.zsh" ] && echo "#!/usr/bin/env zsh\n# 🐳 DOCKER ALIASES\n" > "$CONFIG_DIR/aliases/docker.zsh"
    echo -e "\n# === Migrated from old .zshrc ===" >> "$CONFIG_DIR/aliases/docker.zsh"
    cat "$DOCKER_FILE" >> "$CONFIG_DIR/aliases/docker.zsh"
    echo -e "${GREEN}✅ Added ${counters[docker]} docker aliases${NC}"
fi

if [ -s "$PROJECT_FILE" ]; then
    echo -e "\n# === Migrated from old .zshrc ===" >> "$CONFIG_DIR/aliases/projects.zsh"
    cat "$PROJECT_FILE" >> "$CONFIG_DIR/aliases/projects.zsh"
    echo -e "${GREEN}✅ Added ${counters[project]} project aliases${NC}"
fi

if [ -s "$OBSIDIAN_FILE" ]; then
    echo -e "\n# === Migrated from old .zshrc ===" >> "$CONFIG_DIR/aliases/obsidian.zsh"
    cat "$OBSIDIAN_FILE" >> "$CONFIG_DIR/aliases/obsidian.zsh"
    echo -e "${GREEN}✅ Added ${counters[obsidian]} obsidian aliases${NC}"
fi

if [ -s "$CRYPTO_FILE" ]; then
    [ ! -f "$CONFIG_DIR/aliases/crypto.zsh" ] && echo "#!/usr/bin/env zsh\n# 🔐 CRYPTO ALIASES\n" > "$CONFIG_DIR/aliases/crypto.zsh"
    echo -e "\n# === Migrated from old .zshrc ===" >> "$CONFIG_DIR/aliases/crypto.zsh"
    cat "$CRYPTO_FILE" >> "$CONFIG_DIR/aliases/crypto.zsh"
    echo -e "${GREEN}✅ Added ${counters[crypto]} crypto aliases${NC}"
fi

if [ -s "$LLMS_FILE" ]; then
    [ ! -f "$CONFIG_DIR/aliases/llms.zsh" ] && echo "#!/usr/bin/env zsh\n# 🤖 LLMs ALIASES\n" > "$CONFIG_DIR/aliases/llms.zsh"
    echo -e "\n# === Migrated from old .zshrc ===" >> "$CONFIG_DIR/aliases/llms.zsh"
    cat "$LLMS_FILE" >> "$CONFIG_DIR/aliases/llms.zsh"
    echo -e "${GREEN}✅ Added ${counters[llms]} LLMs aliases${NC}"
fi

if [ -s "$FUNCTION_FILE" ]; then
    [ ! -f "$CONFIG_DIR/functions/helpers.zsh" ] && echo "#!/usr/bin/env zsh\n# 🛠️ HELPER FUNCTIONS\n" > "$CONFIG_DIR/functions/helpers.zsh"
    echo -e "\n# === Migrated from old .zshrc ===" >> "$CONFIG_DIR/functions/helpers.zsh"
    cat "$FUNCTION_FILE" >> "$CONFIG_DIR/functions/helpers.zsh"
    echo -e "${GREEN}✅ Added ${counters[function]} functions${NC}"
fi

if [ -s "$ENV_FILE" ]; then
    echo -e "\n# === Migrated from old .zshrc ===" >> "$CONFIG_DIR/env/vars.zsh"
    cat "$ENV_FILE" >> "$CONFIG_DIR/env/vars.zsh"
    echo -e "${GREEN}✅ Added ${counters[env]} environment variables${NC}"
fi

if [ -s "$OTHER_FILE" ]; then
    [ ! -f "$CONFIG_DIR/aliases/personal.zsh" ] && echo "#!/usr/bin/env zsh\n# 🎯 PERSONAL ALIASES\n" > "$CONFIG_DIR/aliases/personal.zsh"
    echo -e "\n# === Uncategorized aliases from old .zshrc ===" >> "$CONFIG_DIR/aliases/personal.zsh"
    cat "$OTHER_FILE" >> "$CONFIG_DIR/aliases/personal.zsh"
    echo -e "${GREEN}✅ Added ${counters[other]} uncategorized aliases to personal.zsh${NC}"
fi

# Очистка
rm -rf "$TMP_DIR"

echo -e "\n${GREEN}✅ Migration complete!${NC}"
echo -e "${PURPLE}📝 Next steps:${NC}"
echo "1. Review the migrated files in $CONFIG_DIR"
echo "2. Copy the new .zshrc template:"
echo "   cp $CONFIG_DIR/zshrc_new_template ~/.zshrc"
echo "3. Source the new config:"
echo "   source ~/.zshrc"
echo "4. Test your aliases!"

echo -e "\n${YELLOW}💡 TIP: Check uncategorized aliases in personal.zsh and move them to appropriate files${NC}"
