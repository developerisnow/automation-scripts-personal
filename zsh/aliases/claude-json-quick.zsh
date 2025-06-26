#!/bin/zsh
# 🚀 Quick Claude JSON Examples

# Алиасы для быстрого старта
alias claude-analyze='tmux new-session -d -s "analyze-$(date +%s)" \; send-keys "claude -p \"analyze this project\" --output-format json > analysis-$(date +%Y%m%d-%H%M%S).json" C-m && echo "✅ Analysis started in background"'

alias claude-security='tmux new-session -d -s "security-$(date +%s)" \; send-keys "claude -p \"find security vulnerabilities\" --output-format json > security-$(date +%Y%m%d-%H%M%S).json" C-m && echo "🔒 Security scan started"'

alias claude-perf='tmux new-session -d -s "perf-$(date +%s)" \; send-keys "claude -p \"analyze performance bottlenecks\" --output-format json > performance-$(date +%Y%m%d-%H%M%S).json" C-m && echo "⚡ Performance analysis started"'

# Проверка статуса всех claude сессий
claude-status() {
    echo "🤖 Active Claude Sessions:"
    tmux list-sessions 2>/dev/null | grep -E "(analyze|security|perf|claude)" || echo "No active sessions"
}

# Сбор всех JSON результатов
claude-collect() {
    echo "📊 Collecting all JSON results..."
    
    local report_dir="claude-reports-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$report_dir"
    
    # Копируем все JSON файлы
    find . -name "*.json" -mtime -1 -exec cp {} "$report_dir/" \; 2>/dev/null
    
    # Генерируем сводку
    if command -v jq &> /dev/null; then
        echo "📈 Generating summary..."
        jq -s '.' "$report_dir"/*.json > "$report_dir/summary.json" 2>/dev/null
    fi
    
    echo "✅ Reports collected in: $report_dir"
    echo "📁 Files: $(ls -1 "$report_dir"/*.json 2>/dev/null | wc -l)"
}

# Быстрый анализ всех проектов в папке
claude-batch() {
    local parent_dir="${1:-.}"
    
    echo "🚀 Starting batch analysis of: $parent_dir"
    
    for project in "$parent_dir"/*; do
        if [[ -d "$project" && -d "$project/.git" ]]; then
            local proj_name=$(basename "$project")
            echo "📂 Analyzing: $proj_name"
            
            tmux new-session -d -s "batch-$proj_name-$(date +%s)" -c "$project" \; \
                send-keys "claude -p 'analyze project structure, find issues, suggest improvements' --output-format json > ../$proj_name-analysis.json" C-m
            
            sleep 2  # Небольшая пауза между запусками
        fi
    done
    
    echo "✅ Batch analysis started. Check with: claude-status"
}

# Простой pipeline пример
claude-pipeline() {
    local input_file="${1:-README.md}"
    
    echo "🔄 Running pipeline on: $input_file"
    
    # Шаг 1: Анализ
    local analysis=$(claude -p "analyze this file: $(cat $input_file)" --output-format json)
    
    # Шаг 2: Извлекаем проблемы
    local issues=$(echo "$analysis" | jq -r '.issues[]' 2>/dev/null)
    
    # Шаг 3: Фиксим каждую проблему
    if [[ -n "$issues" ]]; then
        echo "$issues" | while read -r issue; do
            echo "🔧 Fixing: $issue"
            claude -p "fix this issue: $issue" --output-format json > "fix-$(date +%s).json"
        done
    else
        echo "✅ No issues found!"
    fi
}

echo "🚀 Claude JSON Automation loaded!"
echo ""
echo "⚡ Quick commands:"
echo "  claude-analyze    - Analyze current project in background"
echo "  claude-security   - Run security scan"
echo "  claude-perf      - Check performance"
echo "  claude-status    - Show all active sessions"
echo "  claude-collect   - Gather all JSON results"
echo "  claude-batch DIR - Analyze all projects in directory"
echo ""
echo "💡 Example: claude-analyze && claude-status"
