#!/usr/bin/env zsh
# 🤖 LLMs ALIASES - AI/ML проекты и инструменты
# ============================================

# 🎯 Quick access to LLM projects
# -------------------------------
alias llms='cd /Users/user/__Repositories && ls -la | grep LLMs'
alias llm-list='ls -1 /Users/user/__Repositories | grep LLMs | sort'

# 🛠️ Popular LLM tools
# --------------------
alias aider='cd /Users/user/__Repositories/LLMs-aider'
alias cline='cd /Users/user/__Repositories/LLMs-Cline__Cline'
alias roo='cd /Users/user/__Repositories/LLMs-Roo-Cline__RooVetGit'
alias cursor='cd /Users/user/__Repositories/LLMs-cursor-memory-bank__ipenywis'
alias openhands='cd /Users/user/__Repositories/LLMs-OpenHands'

# 🧠 AI Assistants
# ----------------
alias claude='cd /Users/user/__Repositories/LLMs-Claude-API'
alias gpt='cd /Users/user/__Repositories/LLMs-Chat-GPT-Building-Systems'
alias babyagi='cd /Users/user/__Repositories/LLMs-babyagi'
alias autogpt='cd /Users/user/__Repositories/LLMs-Auto-GPT'

# 📚 Learning & Courses
# ---------------------
alias llm-course='cd /Users/user/__Repositories/LLMs-course-IndyDevDan-disler'
alias llm-cookbook='cd /Users/user/__Repositories/LLMs-openai-cookbook'
alias prompt-eng='cd /Users/user/__Repositories/LLMs-prompt-engineering'

# 🔧 Development tools
# --------------------
alias langchain='cd /Users/user/__Repositories/LLMs-Lang-Chain-for-Application-Development'
alias langflow='cd /Users/user/__Repositories/LLMs-langflow'
alias dify='cd /Users/user/__Repositories/LLMs-dify'
alias flowise='cd /Users/user/__Repositories/LLMs-flowise'

# 🎮 Specific projects
# --------------------
alias airpg='cd /Users/user/__Repositories/LLMs-airpg__belbix'
alias airpg-master='cd /Users/user/__Repositories/LLMs-airpg__belbix-master'
alias airpg-w6='cd /Users/user/__Repositories/LLMs-airpg__belbix-master-week6-1'

# 🔍 RAG & Search
# ---------------
alias rag='cd /Users/user/__Repositories/LLMs-RAG-Techniques'
alias danswer='cd /Users/user/__Repositories/LLMs-danswer'
alias crawl4ai='cd /Users/user/__Repositories/LLMs-crawl4ai__unclecode'

# 🎙️ Voice & Transcription
# -------------------------
alias whisper='cd /Users/user/__Repositories/LLMs-whisper-asr-webservice'
alias elevenlabs='cd /Users/user/__Repositories/LLMs-elevenlabs-docs'

# 📱 Telegram bots
# ----------------
alias llm-tg='cd /Users/user/__Repositories/LLMs-Assistant-Telegram-CRM-fastapi-fullstack'
alias chatgpt-tg='cd /Users/user/__Repositories/LLMs-chatgpt-telegram'

# 🔧 MCP (Model Context Protocol)
# -------------------------------
alias mcp='cd /Users/user/__Repositories/LLMs-MCP-Anthropic'
alias mcp-ref='cd /Users/user/__Repositories/LLMs-MCP-reference-servers__smithery-ai'

# 🛠️ Code tools
# -------------
alias code2prompt='cd /Users/user/__Repositories/LLMs-code2prompt__mufeedvh'
alias aicoder='cd /Users/user/__Repositories/LLMs-ai-code-translator'
alias gptmigrate='cd /Users/user/__Repositories/LLMs-gpt-migrate'

# 🌐 Web & API
# ------------
alias webai='cd /Users/user/__Repositories/LLMs-Web-AI-to-API'
alias chatui='cd /Users/user/__Repositories/LLMs-chatbot-ui'

# 📊 Local models
# ---------------
alias localai='cd /Users/user/__Repositories/LLMs-Local-AI'
alias gpt4all='cd /Users/user/__Repositories/LLMs-gpt4all'
alias privategpt='cd /Users/user/__Repositories/LLMs-private-GPT'

# 🎯 Quick functions
# ------------------
# List all LLM projects with description
llm-projects() {
    echo "🤖 LLM Projects:"
    ls -1 /Users/user/__Repositories | grep LLMs | sort | nl
}

# Quick search in LLM projects
llm-search() {
    if [ -z "$1" ]; then
        echo "Usage: llm-search <term>"
        return 1
    fi
    ls -1 /Users/user/__Repositories | grep -i "llms.*$1"
}

# Go to LLM project by partial name
llm-go() {
    if [ -z "$1" ]; then
        echo "Usage: llm-go <partial-project-name>"
        return 1
    fi
    local matches=$(ls -1 /Users/user/__Repositories | grep -i "llms.*$1")
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
