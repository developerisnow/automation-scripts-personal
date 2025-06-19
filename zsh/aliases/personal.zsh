#!/usr/bin/env zsh
# 🎯 PERSONAL ALIASES - Кастомные команды и скрипты
# =================================================

# 🔄 ZSH Management
# -----------------
alias uzsh='source ~/.zshrc'
alias reload='source ~/.zshrc && echo "✅ ZSH config reloaded!"'
alias zshrc='${EDITOR:-code} ~/.zshrc'
alias zshconf='cd ~/.config/zsh && ${EDITOR:-code} .'

# 🔍 Code Analysis Tools
# ----------------------
alias tokens='wc -w'
alias analysegit='python3 /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/git-files-list-commits-analyzer.py'
alias analysegit-filtered='python3 /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/git-files-list-commits-analyzer.py --typesexclude="md,json" --exclude-hidden --foldersexclude="test,logs"'
alias analysegit-last='python3 /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/git-files-list-commits-analyzer.py --lastcommits'
alias analysegit-branches='python3 /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/git-files-list-commits-analyzer.py --branches'

# 📊 File Size Analysis
# ---------------------
alias big20='fd --type f --hidden --exclude .git | xargs -I{} du -sk "{}" | sort -nr | head -20'
alias big20git='git ls-files --others --cached --exclude-standard | xargs -I{} du -sk "{}" | sort -nr | head -20'
alias big20rg='rg --files --hidden --glob "!.git/*" | xargs -I{} du -sk "{}" | sort -nr | head -20'

# 🌳 Tree Commands
# ----------------
alias treeFiles2='timestamp=$(date "+%Y-%m-%d_%H-%M") && tree -L 4 > "treeAllFiles_____Sandruk-${timestamp}.md" && tree -L 4 -if --noreport > "treeFiles_____Sandruk-${timestamp}.csv" && echo "Files saved: treeAllFiles_____Sandruk-${timestamp}.[md/csv]"'
alias treeFiles='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/treeFilesEnchanced.sh'
alias treeGitFiles='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/treeGitFilesEnchanced.sh'
alias treeFolders='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/treeProjectsAndRootFolders.sh'
alias treeStructure='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/treeFoldersStructure.sh'

# 🔐 SSH Management
# -----------------
alias sshgit='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/ssh_git.sh'
alias sshmy='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/ssh_my.sh'
alias sshandrew='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/ssh_andrew.sh'
alias rhost='sh read -p "Enter the IP address: " ip && sed -i "" "/$ip/d" /Users/user/.ssh/known_hosts'

# 📁 File Management
# ------------------
alias rmtxt='echo "Files to be deleted:" && find . -name "*.txt" -type f | head -20'
alias rmlogs='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/rmlogs.sh'
alias rmlogsXZ='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/archiveations_automations.sh rmlogsXZ'
alias rmlogsZSTD='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/archiveations_automations.sh rmlogsZSTD'
alias fixt='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/rmlogs.sh fixt'
alias renameFolders='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/rename_folders.py'

# 🎬 Media Tools
# --------------
alias a2yt="sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/media/mediactl_audio_video.sh -m cover"
alias a2m4a="sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/media/mediactl_audio_video.sh -m audio"
alias webm2mp4="sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/media/mediactl_audio_video.sh -m transcode"
alias mediactl="sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/media/mediactl_audio_video.sh"

# 🎙️ Transcription
# -----------------
alias transcribe='node /Users/user/____Sandruk/__Vaults_Databases/__Repositories/LLMs-openai-cookbook/whisper/whisper-app-nodejs/index.js'
alias replicateai='node /Users/user/____Sandruk/__Vaults_Databases/__Repositories/LLMs-openai-cookbook/whisper/whisper-app-nodejs/index.js replicateai'
alias fasterWhisper='node /Users/user/____Sandruk/__Vaults_Databases/__Repositories/LLMs-openai-cookbook/whisper/whisper-app-nodejs/index.js fasterWhisper'

# 🐍 Python Tools
# ---------------
alias pythonVersions='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/pythonReviewSoftware.sh'
alias pythonConfigsSearch='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/pythonLocalConfigsSearch.sh'
alias addContentToFiles='python3 /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/updateFilesRecursively.py'

# 📋 Templates
# ------------
alias cpgitignore='cp /Users/user/____Sandruk/___PARA/__Projects/_templates/_Template_Project0/.gitignore ./ && echo "Copied .gitignore from Template_Project0 to current directory"'

# 🌐 Network & Proxy
# ------------------
alias checkProxy='bash ~/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/check_proxy.sh'

# 🎬 YouTube Tools
# ----------------
alias ytsubs="node /Users/user/__Repositories/youtube-scrapping/youtube-captions-scraper/yt-subs.js"
alias yt='sh /Users/user/__Repositories/youtube-scrapping/youtube_channel_analyzer/scripts/alias-runner-yt-dlp.sh'

# 🕷️ Web Scraping
# ---------------
alias crawl4v0='python3 /Users/user/__Repositories/LLMs-crawl4ai__unclecode/scripts/crawl4ai_cli_v0_work.py'

# 🔒 Cursor Protection
# --------------------
alias protect-schemas='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/cursor_protect-schema-files.sh lock schemas'
alias protect-migrations='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/cursor_protect-schema-files.sh lock migrations'
alias protect-all='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/cursor_protect-schema-files.sh lock all'
alias unlock-schemas='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/cursor_protect-schema-files.sh unlock schemas'
alias unlock-migrations='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/cursor_protect-schema-files.sh unlock migrations'
alias unlock-all='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/cursor_protect-schema-files.sh unlock all'
alias verify-protected='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/cursor_protect-schema-files.sh verify'
alias monitor-protected='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/cursor_monitor-protected-files.sh'

# 💬 Chat & Development
# ---------------------
alias chatdev="bash $HOME/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/cursor/start-dev.sh"
alias chatprod="bash $HOME/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/cursor/start-prod.sh"

# 🌐 Translations
# ---------------
alias toTranslate="python3 /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/translations/translation_file.py"
alias toTranslateHQ="python3 /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/translations/translation_file_enhanced.py"

# 🗑️ Cleanup & Normalization
# ---------------------------
alias obsort='python3 /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/obsidian/obsidian_file_sorter.py --verbose'
alias chatgptnorm='python3 /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/openai/filename-normalization-script.py --verbose'

# 📝 Logging
# ----------
alias logerror='/Users/user/__Repositories/HypeTrain/scripts/logerror.sh'
alias logerror_here='logerror'

# 🎯 Backup
# ---------
alias backupairpg='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/archiveations_automations.sh backup /Users/user/__Repositories/LLMs-airpg__belbix'
