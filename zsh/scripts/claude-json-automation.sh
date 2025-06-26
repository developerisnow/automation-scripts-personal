#!/bin/bash
# 🚀 Claude Code JSON Automation Workflow

# 1. Анализ проекта в фоне
analyze_project() {
    local project_path="${1:-.}"
    local session_name="analyze-$(basename $project_path)-$(date +%Y%m%d-%H%M%S)"
    
    tmux new-session -d -s "$session_name" -c "$project_path" \; \
        send-keys "claude -p 'Analyze this project: architecture, security, performance, test coverage. Output detailed JSON report' --output-format json > analysis-$(date +%Y%m%d-%H%M%S).json" C-m
    
    echo "✅ Analysis started in session: $session_name"
    echo "📊 Check status: tmux attach -t $session_name"
}

# 2. Batch анализ нескольких проектов
batch_analyze() {
    for project in "$@"; do
        echo "🔍 Analyzing: $project"
        analyze_project "$project"
        sleep 2  # Небольшая задержка между запусками
    done
}

# 3. Мониторинг результатов
monitor_results() {
    echo "📊 Monitoring JSON outputs..."
    watch -n 5 'ls -la *.json 2>/dev/null | tail -10'
}

# 4. Парсинг результатов
parse_results() {
    local json_file="$1"
    
    echo "🔍 Parsing: $json_file"
    
    # Извлекаем ключевые метрики
    jq -r '{
        project: .project_name,
        security_issues: .security.vulnerabilities | length,
        performance_score: .performance.score,
        test_coverage: .quality.test_coverage,
        critical_suggestions: .suggestions | map(select(.priority == "critical"))
    }' "$json_file"
}

# 5. Генерация сводного отчета
generate_report() {
    echo "📈 Generating summary report..."
    
    # Собираем все JSON файлы
    jq -s '[.[] | {
        project: .project_name,
        date: .analysis_date,
        issues: (.security.vulnerabilities | length),
        coverage: .quality.test_coverage
    }]' analysis-*.json > summary-report.json
    
    echo "✅ Report saved to summary-report.json"
}

# 6. Pipeline для CI/CD
ci_pipeline() {
    local result=$(claude -p "Check code quality" --output-format json)
    local quality_score=$(echo "$result" | jq -r '.quality_score')
    
    if (( $(echo "$quality_score < 7" | bc -l) )); then
        echo "❌ Quality check failed: $quality_score"
        exit 1
    fi
    
    echo "✅ Quality check passed: $quality_score"
}

# Экспорт функций
export -f analyze_project
export -f batch_analyze
export -f monitor_results
export -f parse_results
export -f generate_report
export -f ci_pipeline

# Примеры использования
echo "🚀 Claude Code JSON Automation loaded!"
echo ""
echo "📋 Commands:"
echo "  analyze_project [path]     - Analyze single project"
echo "  batch_analyze path1 path2  - Analyze multiple projects"
echo "  monitor_results           - Watch for JSON outputs"
echo "  parse_results file.json   - Parse analysis results"
echo "  generate_report          - Create summary from all JSONs"
echo ""
echo "💡 Example:"
echo "  analyze_project ~/projects/hypetrain"
