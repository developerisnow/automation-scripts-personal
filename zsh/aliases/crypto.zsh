#!/usr/bin/env zsh
# 🔐 CRYPTO ALIASES - Blockchain и криптовалютные проекты
# =======================================================

# 🎯 Quick access to crypto projects
# ----------------------------------
alias crypto='cd /Users/user/__Repositories && ls -la | grep crypto'
alias crypto-list='ls -1 /Users/user/__Repositories | grep crypto | sort'

# ⛓️ Blockchain networks
# ----------------------
alias eth='cd /Users/user/__Repositories/crypto-ethereum'
alias btc='cd /Users/user/__Repositories/crypto-bitcoin'
alias sol='cd /Users/user/__Repositories/crypto-solana'
alias apt='cd /Users/user/__Repositories/crypto-aptos'
alias sui='cd /Users/user/__Repositories/crypto-sui'
alias arb='cd /Users/user/__Repositories/crypto-arbitrum'
alias opt='cd /Users/user/__Repositories/crypto-optimism'
alias base='cd /Users/user/__Repositories/crypto-base'
alias zksync='cd /Users/user/__Repositories/crypto-zksync'
alias stark='cd /Users/user/__Repositories/crypto-starknet'
alias scroll='cd /Users/user/__Repositories/crypto-scroll'

# 🏦 CEX (Centralized Exchanges)
# ------------------------------
alias cex='cd /Users/user/__Repositories && ls -la | grep "crypto-exchange-cex"'
alias binance='cd /Users/user/__Repositories/crypto-exchange-cex-Binance-multiwallet-withdrawal'
alias bybit='cd /Users/user/__Repositories/crypto-exchange-cex-Bybit-bulk-withdrawal'
alias okx='cd /Users/user/__Repositories/crypto-exchange-cex-okx-withdrawal2'
alias huobi='cd /Users/user/__Repositories/crypto-exchange-cex-huobi-REST-Node.js-demo'

# 🔧 Tools & Utilities
# --------------------
alias wallets='cd /Users/user/__Repositories && ls -la | grep "crypto-wallets"'
alias checker='cd /Users/user/__Repositories/crypto-wallets-checker-balances'
alias debank='cd /Users/user/__Repositories/crypto-wallets-debank-checker'
alias multisender='cd /Users/user/__Repositories/crypto-wallets-multisender'
alias warm='cd /Users/user/__Repositories/crypto-wallets-warm-up'

# 🎮 Specific projects
# --------------------
alias aleo='cd /Users/user/__Repositories/crypto-aleo'
alias blur='cd /Users/user/__Repositories/crypto-blur'
alias galxe='cd /Users/user/__Repositories/crypto-galxe-claimer'
alias lens='cd /Users/user/__Repositories/crypto-lens'
alias safe='cd /Users/user/__Repositories/crypto-safe'
alias worldcoin='cd /Users/user/__Repositories/crypto-worldcoin'
alias zora='cd /Users/user/__Repositories/crypto-zora'

# 📱 Social & Messaging
# ---------------------
alias farcaster='cd /Users/user/__Repositories/crypto-farcaster-GUI-electron_developerisnow'
alias farcaster-api='cd /Users/user/__Repositories/crypto-farcaster-api_Andrey-and-developerisnow'
alias discord-tools='cd /Users/user/__Repositories && ls -la | grep "crypto-discord"'
alias twitter-tools='cd /Users/user/__Repositories && ls -la | grep "crypto-twitter"'
alias tg-crypto='cd /Users/user/__Repositories/crypto-telegram-multi-actions'

# 🏗️ Hackathons
# -------------
alias hackathons='cd /Users/user/__Repositories && ls -la | grep "crypto-hackathons"'
alias ethglobal='cd /Users/user/__Repositories && ls -la | grep "crypto-hackathons-eth-Global"'

# 🔍 Analytics & Checkers
# -----------------------
alias drop-check='cd /Users/user/__Repositories/crypto-drop-checkers'
alias gas-check='cd /Users/user/__Repositories/crypto-defi-check-gas-spended'
alias ethscan='cd /Users/user/__Repositories/crypto-etherscan'

# 🤖 Automation & Bots
# --------------------
alias crypto-bot='cd /Users/user/__Repositories/crypto-all-in-one-v2'
alias dex-swap='cd /Users/user/__Repositories/crypto-defi-dex-swapper'
alias voting='cd /Users/user/__Repositories/crypto-Voting-snapshot'

# 🎯 Quick functions
# ------------------
# List all crypto projects
crypto-projects() {
    echo "🔐 Crypto Projects:"
    ls -1 /Users/user/__Repositories | grep crypto | sort | nl
}

# Quick search in crypto projects
crypto-search() {
    if [ -z "$1" ]; then
        echo "Usage: crypto-search <term>"
        return 1
    fi
    ls -1 /Users/user/__Repositories | grep -i "crypto.*$1"
}

# Go to crypto project by partial name
crypto-go() {
    if [ -z "$1" ]; then
        echo "Usage: crypto-go <partial-project-name>"
        return 1
    fi
    local matches=$(ls -1 /Users/user/__Repositories | grep -i "crypto.*$1")
    local count=$(echo "$matches" | wc -l)
    
    if [ $count -eq 1 ]; then
        cd "/Users/user/__Repositories/$matches"
        pwd
    elif [ $count -eq 0 ]; then
        echo "❌ No matches found for: $1"
    else
        echo "🔍 Multiple matches found:"
        echo "$matches" | nl
        echo "Please be more specific."
    fi
}

# Check balances (if script exists)
check-balances() {
    local checker="/Users/user/__Repositories/crypto-wallets-checker-balances/check.py"
    if [ -f "$checker" ]; then
        python3 "$checker" "$@"
    else
        echo "❌ Balance checker not found at: $checker"
    fi
}
