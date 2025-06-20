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
# alias 'tokens file'='tokens'
lsmatch() {
       ls | grep -i "$1" | awk '{print NR, $0}'
   }

# 📊 File Size Analysis
# ---------------------
alias big20='fd --type f --hidden --exclude .git | xargs -I{} du -sk "{}" | sort -nr | head -20'
alias big20git='git ls-files --others --cached --exclude-standard | xargs -I{} du -sk "{}" | sort -nr | head -20'
alias big20rg='rg --files --hidden --glob "!.git/*" | xargs -I{} du -sk "{}" | sort -nr | head -20'


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

# 🌐 Network & Proxy
# ------------------
alias checkProxy='bash ~/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/check_proxy.sh'


# 📝 Logging
# ----------
alias logerror='/Users/user/__Repositories/HypeTrain/scripts/logerror.sh'
alias logerror_here='logerror'
