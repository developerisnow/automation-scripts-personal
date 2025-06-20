#!/usr/bin/env zsh
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
# alias devgardenGem='cd /Users/user/__Repositories/HypeTrain/repositories/hypetrain-garden && gh workflow run garden.yml --ref fix/garden -f backend=feat/add-script-quotas-token/us/506-2467 -f frontend=story/1029 -f env-name=debug'
# alias stagegardenGem='cd /Users/user/__Repositories/HypeTrain/repositories/hypetrain-garden && gh workflow run garden-stage.yml --ref stage -f backend=feat/add-script-quotas-token/us/506-2467 -f frontend=story/1029 -f env-name=stage-debug1 -f load_production_data=true -f clean_database=true'

# 📋 Templates
# ------------
alias cpgitignore='cp /Users/user/____Sandruk/___PARA/__Projects/_templates/_Template_Project0/.gitignore ./ && echo "Copied .gitignore from Template_Project0 to current directory"'


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

# Source HypeTrain specific aliases and functions
HT_PROMPT_SCRIPT="/Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/HypeTrain2Promp.sh"
if [ -f "$HT_PROMPT_SCRIPT" ]; then
  source "$HT_PROMPT_SCRIPT"
else
  echo "Warning: HypeTrain prompt script not found: $HT_PROMPT_SCRIPT" >&2
fi