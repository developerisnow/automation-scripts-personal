#!/usr/bin/env zsh
# 🚂 PROJECT ALIASES - Быстрый доступ к проектам и их командам
# ============================================================

# 🎮 HypeTrain Project
# -------------------
# hdocsw = hypetrain docs watch (следит за изменениями в документации)
# Пример комментария для ADHD: что делает → где находится → зачем нужно

# Navigation to HypeTrain
alias ht='cd /Users/user/__Repositories/HypeTrain'
alias hype='cd /Users/user/__Repositories/HypeTrain'
alias hypetrain='cd /Users/user/__Repositories/HypeTrain/repositories/hypetrain-backend'

# HypeTrain commands
alias hdocsw='cd /Users/user/__Repositories/HypeTrain/repositories/hypetrain-docs && uv run mkdocs serve'
alias hdocsb='cd /Users/user/__Repositories/HypeTrain/repositories/hypetrain-docs && uv run mkdocs build && wrangler pages deploy site --project-name hypetrain-docs --branch main'
alias hgit='cd /Users/user/__Repositories/HypeTrain/repositories/hypetrain-docs && pwd && git status &&  cd ../hypetrain-backend/ && pwd && git status && cd ../hypetrain-frontend && pwd && git status && cd ../hypetrain-garden && pwd && git status && cd ../hypetrain-devops-helm && pwd && git status && cd /Users/user/__Repositories/HypeTrain/ && pwd && git status'
alias hgarden='cd /Users/user/__Repositories/HypeTrain/repositories/hypetrain-garden && pwd && git status && git branch && git log -1 && gh run list --workflow=garden.yml --repo infludb-inc/hypetrain-garden --limit=5'

# HypeTrain GitHub Actions
alias gardendev='cd /Users/user/__Repositories/HypeTrain/repositories/hypetrain-garden-fix && pwd && git status && git log -1 && gh run list --workflow=garden.yml --repo infludb-inc/hypetrain-garden --limit=3 && gh workflow run garden.yml --ref fix/garden -f backend=feat/add-script-quotas-token/us/506-2467 -f frontend=story/1029 -f env-name=debug -f env-type=dev -f force_rebuild=true'
alias gardenstage='cd /Users/user/__Repositories/HypeTrain/repositories/hypetrain-garden-fix && pwd && git status && git log -1 && gh run list --workflow=garden-dev.yml --repo infludb-inc/hypetrain-garden --limit=3 && gh workflow run garden-stage.yml --ref fix/garden -f backend=feat/add-script-quotas-token/us/506-2467 -f frontend=story/1029 -f env-name=stage-debug1 -f load_production_data=true -f clean_database=true -f pgadmin=true'
alias gardendevstage='gardendev && gardenstage'

# 🤖 AirPG Project (AI RPG)
# ------------------------
alias airpg='cd /Users/user/__Repositories/LLMs-airpg__belbix'
alias airpg-master='cd /Users/user/__Repositories/LLMs-airpg__belbix-master'
alias airpg-w6='cd /Users/user/__Repositories/LLMs-airpg__belbix-master-week6-1'

# 📋 TaskMaster
# -------------
alias tm='cd /Users/user/__Repositories/claude-task-master'
alias taskmaster='cd /Users/user/__Repositories/llm-claude-task-master__by_eyaltoledano'

# 🔮 Obsidian Projects
# --------------------
# o2p = obsidian to prompt
# o2pd = obsidian to prompt with date
# ac2p = all code to prompt (использует code2prompt)

# Navigation
alias obs-tasks='cd /Users/user/__Repositories/obsidian-tasks'
alias obs-tg='cd /Users/user/__Repositories/obsidian-telegram-sync__soberhacker'

# 🤖 LLMs Projects Quick Access
# -----------------------------
alias llms='cd /Users/user/__Repositories && ls -la | grep LLMs'  # Показать все LLMs проекты
alias aider='cd /Users/user/__Repositories/LLMs-aider'
alias cline='cd /Users/user/__Repositories/LLMs-Cline__Cline'
alias roo='cd /Users/user/__Repositories/LLMs-Roo-Cline__RooVetGit'

# 📱 Telegram Projects
# --------------------
alias tg-mcp='cd /Users/user/__Repositories/tg-mcp-assistant-telegram-crm__developerisnow'
alias tg-scrapper='cd /Users/user/__Repositories/tg-scrapper__developerisnow'
alias tgc='cd /Users/user/__Repositories/Assistant-Telegram-nestjs && pnpm start:prod'
alias tgp='cd /Users/user/__Repositories/Assistant-Telegram-nestjs && pnpm start:studio'

# 🔍 Search & Analysis Tools
# --------------------------
alias s2p='/Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/search2prompt.sh "$@"'
alias curs2p='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/CursorRulesMemorybankTasks2Prompt.sh'
alias promptextract='cd /Users/user/____Sandruk/___PKM && python3 /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/obsidian/prompts_extractor.py'

# 📊 TypeScript Mapping
# ---------------------
alias tsmap='python3 ~/bin/tsmap'

# === Migrated from old .zshrc (HypeTrain specific) ===
alias rpgdocs='cd /Users/user/__Repositories/LLMs-airpg__belbix && pwd && git branch && git status && git add docs && git commit -m \"docs\"'

# HypeTrain code2prompt commands
alias ht-backend-source='cc2p hypetrain-backend source'
alias ht-backend-libs='cc2p hypetrain-backend libs'
alias ht-backend-cqrs='cc2p hypetrain-backend cqrs'
alias ht-backend-events='cc2p hypetrain-backend integration-events'
alias ht-backend-infra='cc2p hypetrain-backend infrastructure'
alias ht-backend-quality='cc2p hypetrain-backend quality-control'
alias ht-backend-full='cc2p hypetrain-backend full'

alias ht-frontend-source='cc2p hypetrain-frontend source'
alias ht-frontend-components='cc2p hypetrain-frontend components'
alias ht-frontend-infra='cc2p hypetrain-frontend infrastructure'

# HypeTrain templates
alias ht-backend-docs='cc2p hypetrain-backend source --template=document'
alias ht-backend-security='cc2p hypetrain-backend full --template=security'
alias ht-backend-performance='cc2p hypetrain-backend source --template=performance'
alias ht-backend-refactor='cc2p hypetrain-backend libs --template=refactor'
alias ht-backend-claude='cc2p hypetrain-backend cqrs --template=claude'
alias ht-backend-cleanup='cc2p hypetrain-backend source --template=cleanup'
alias ht-backend-quality-check='cc2p hypetrain-backend quality-control --template=security'

# TaskMaster symlinks
alias tasksymlinks="python3 /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/obsidian/taskmaster_symlinks_enhanced.py"
alias tasksymlinks-watch="python3 /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/obsidian/taskmaster_symlinks_enhanced.py --watch /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/obsidian/taskmaster_projects.txt"
alias tasksymlinks-start="launchctl load ~/Library/LaunchAgents/com.user.taskmaster-symlinks.plist"
alias tasksymlinks-stop="launchctl unload ~/Library/LaunchAgents/com.user.taskmaster-symlinks.plist"
alias tasksymlinks-status="launchctl list | grep taskmaster-symlinks"
alias tasksymlinks-logs="tail -f /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/logs/taskmaster-symlinks.log"
