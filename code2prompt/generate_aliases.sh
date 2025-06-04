#!/bin/bash

# Генератор алиасов для HypeTrain Code2Prompt
# Создаёт алиасы для быстрого доступа к разным контекстам

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_SCRIPT="$SCRIPT_DIR/../code2prompt.sh"

cat << 'EOF'
# HypeTrain Code2Prompt Aliases
# Автогенерированный файл - не редактировать вручную!

# Экспорт путей
export HYPETRAIN_REPO_PATH="/Users/user/__Repositories/HypeTrain/repositories/hypetrain-backend"
export C2P_SCRIPT_PATH="/Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/code2prompt.sh"

# Основные контексты
alias hc2pSource='$C2P_SCRIPT_PATH ccode2prompt hypetrain-backend source'
alias hc2pLibs='$C2P_SCRIPT_PATH ccode2prompt hypetrain-backend libs'
alias hc2pCqrs='$C2P_SCRIPT_PATH ccode2prompt hypetrain-backend cqrs'
alias hc2pIntegrationEvents='$C2P_SCRIPT_PATH ccode2prompt hypetrain-backend integration-events'
alias hc2pTests='$C2P_SCRIPT_PATH ccode2prompt hypetrain-backend tests'
alias hc2pQualityControl='$C2P_SCRIPT_PATH ccode2prompt hypetrain-backend quality-control'
alias hc2pInfrastructure='$C2P_SCRIPT_PATH ccode2prompt hypetrain-backend infrastructure'
alias hc2pInfraDetailed='$C2P_SCRIPT_PATH ccode2prompt hypetrain-backend infra-detailed'
alias hc2pFull='$C2P_SCRIPT_PATH ccode2prompt hypetrain-backend full'

# App-specific contexts
alias hc2pApi='$C2P_SCRIPT_PATH ccode2prompt hypetrain-backend app-api'
alias hc2pBilling='$C2P_SCRIPT_PATH ccode2prompt hypetrain-backend app-billing'
alias hc2pContracting='$C2P_SCRIPT_PATH ccode2prompt hypetrain-backend app-contracting'
alias hc2pExploration='$C2P_SCRIPT_PATH ccode2prompt hypetrain-backend app-exploration'
alias hc2pExternalApi='$C2P_SCRIPT_PATH ccode2prompt hypetrain-backend app-external-api'
alias hc2pMessageProcessing='$C2P_SCRIPT_PATH ccode2prompt hypetrain-backend app-message-processing'
alias hc2pMigrationRunner='$C2P_SCRIPT_PATH ccode2prompt hypetrain-backend app-migration-runner'
alias hc2pNotification='$C2P_SCRIPT_PATH ccode2prompt hypetrain-backend app-notification'
alias hc2pScheduler='$C2P_SCRIPT_PATH ccode2prompt hypetrain-backend app-scheduler'
alias hc2pSearch='$C2P_SCRIPT_PATH ccode2prompt hypetrain-backend app-search'
alias hc2pStorage='$C2P_SCRIPT_PATH ccode2prompt hypetrain-backend app-storage'

# Library-specific contexts
alias hc2pAnalytics='$C2P_SCRIPT_PATH ccode2prompt hypetrain-backend lib-analytics'
alias hc2pLogger='$C2P_SCRIPT_PATH ccode2prompt hypetrain-backend lib-ht-logger'
alias hc2pCommon='$C2P_SCRIPT_PATH ccode2prompt hypetrain-backend lib-common'
alias hc2pShared='$C2P_SCRIPT_PATH ccode2prompt hypetrain-backend lib-shared'

# Template shortcuts (with most used templates)
alias hc2pSourceDoc='$C2P_SCRIPT_PATH ccode2prompt hypetrain-backend source --template=document'
alias hc2pSourceSecurity='$C2P_SCRIPT_PATH ccode2prompt hypetrain-backend source --template=security'
alias hc2pSourceClean='$C2P_SCRIPT_PATH ccode2prompt hypetrain-backend source --template=cleanup'
alias hc2pSourceClaude='$C2P_SCRIPT_PATH ccode2prompt hypetrain-backend source --template=claude'
alias hc2pSourcePerf='$C2P_SCRIPT_PATH ccode2prompt hypetrain-backend source --template=performance'
alias hc2pSourceRefactor='$C2P_SCRIPT_PATH ccode2prompt hypetrain-backend source --template=refactor'

alias hc2pQcSecurity='$C2P_SCRIPT_PATH ccode2prompt hypetrain-backend quality-control --template=security'
alias hc2pQcClean='$C2P_SCRIPT_PATH ccode2prompt hypetrain-backend quality-control --template=cleanup'

# Aggregate functions
hc2pAllApps() {
    echo "🚀 Генерирую все приложения..."
    for app in api billing contracting exploration external-api message-processing migration-runner notification scheduler search storage; do
        echo "📦 Обрабатываю app-$app..."
        $C2P_SCRIPT_PATH ccode2prompt hypetrain-backend "app-$app" --timestamp
    done
    echo "✅ Все приложения готовы!"
}

hc2pAllLibs() {
    echo "📚 Генерирую все библиотеки..."
    for lib in analytics cqrs ht-logger common integration-events shared; do
        echo "📚 Обрабатываю lib-$lib..."
        $C2P_SCRIPT_PATH ccode2prompt hypetrain-backend "lib-$lib" --timestamp
    done
    echo "✅ Все библиотеки готовы!"
}

hc2pEverything() {
    echo "🌟 Генерирую все контексты..."
    hc2pAllApps
    hc2pAllLibs
    echo "📋 Генерирую основные контексты..."
    hc2pSource --timestamp
    hc2pQualityControl --timestamp
    hc2pInfrastructure --timestamp
    echo "✅ Всё готово!"
}

# Utility functions
hc2pHelp() {
    echo "🔧 HypeTrain Code2Prompt Aliases:"
    echo ""
    echo "📋 Основные контексты:"
    echo "  hc2pSource           - Исходный код"
    echo "  hc2pLibs            - Все библиотеки"
    echo "  hc2pQualityControl  - Quality control файлы"
    echo "  hc2pInfrastructure  - Инфраструктура"
    echo "  hc2pInfraDetailed   - Детальная инфраструктура (с YAML preprocessing)"
    echo "  hc2pFull            - Полный проект"
    echo ""
    echo "📦 Приложения:"
    echo "  hc2pApi, hc2pBilling, hc2pContracting, hc2pExploration,"
    echo "  hc2pExternalApi, hc2pMessageProcessing, hc2pMigrationRunner,"
    echo "  hc2pNotification, hc2pScheduler, hc2pSearch, hc2pStorage"
    echo ""
    echo "📚 Библиотеки:"
    echo "  hc2pAnalytics, hc2pCqrs, hc2pLogger, hc2pCommon,"
    echo "  hc2pIntegrationEvents, hc2pShared"
    echo ""
    echo "🎯 С шаблонами:"
    echo "  hc2pSourceDoc       - С документацией"
    echo "  hc2pSourceSecurity  - Анализ безопасности"
    echo "  hc2pSourceClean     - Очистка кода"
    echo "  hc2pSourceClaude    - Формат для Claude"
    echo ""
    echo "🚀 Агрегированные:"
    echo "  hc2pAllApps         - Все приложения"
    echo "  hc2pAllLibs         - Все библиотеки"
    echo "  hc2pEverything      - Абсолютно всё"
    echo ""
    echo "ℹ️  Используйте --timestamp для добавления временной метки"
    echo "ℹ️  Все алиасы можно комбинировать с --template=template_name"
}

echo "✅ HypeTrain Code2Prompt aliases loaded. Type 'hc2pHelp' for help."
EOF 