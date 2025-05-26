#!/bin/bash

# Проверяем, указана ли команда или папка
if [ -z "$1" ]; then
    echo "Ошибка: Необходимо указать команду или путь к папке."
    echo "Использование:"
    echo "  $0 <путь к папке> [--timestamp]"
    echo "  $0 bcode2prompt <файл с путями> [--timestamp]"
    echo "  $0 treecode2prompt <путь к папке> [--timestamp]"
    echo "  $0 ccode2prompt <project_name> [context] [--timestamp] [--template=template_name]"
    echo "  $0 listprojects - показать доступные проекты"
    echo "  $0 listcontexts <project_name> - показать доступные контексты для проекта"
    echo "  $0 listtemplates - показать доступные шаблоны"
    echo "  $0 templateinfo <template_name> - информация о шаблоне"
    echo "  $0 smarttemplate <project_name> <context> <template> - умный выбор шаблона с рекомендациями"
    exit 1
fi

# Сохраняем текущую директорию
CURRENT_DIR=$(pwd)
STATIC_DIR="/Users/user/____Sandruk/___PKM/temp"
CONFIG_FILE="$CURRENT_DIR/automations/code2prompt/includes_code2prompt_default.json"
echo "Текущая директория: $CURRENT_DIR"

# Parse arguments for flags
TIMESTAMP_FLAG=false
TEMPLATE_FLAG=""
ARGS=()
for arg in "$@"; do
    if [ "$arg" = "--timestamp" ]; then
        TIMESTAMP_FLAG=true
    elif [[ "$arg" == --template=* ]]; then
        TEMPLATE_FLAG="${arg#--template=}"
    else
        ARGS+=("$arg")
    fi
done

COMMAND=${ARGS[0]}
INPUT_FOLDER="${ARGS[1]}"

# Helper: get timestamp if needed
get_output_name() {
    local base_name="$1"
    local ext="$2"
    if [ "$TIMESTAMP_FLAG" = true ]; then
        local ts=$(date '+%Y-%m-%d_%H-%M')
        echo "${base_name}_${ts}.${ext}"
    else
        echo "${base_name}.${ext}"
    fi
}

# Helper: read JSON config
read_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Ошибка: Файл конфигурации не найден: $CONFIG_FILE"
        exit 1
    fi
}

# Helper: get project path from config
get_project_path() {
    local project_name="$1"
    read_config
    python3 -c "
import json
import sys
try:
    with open('$CONFIG_FILE', 'r') as f:
        config = json.load(f)
    project_path = config['projects']['$project_name']['project_path']
    print(project_path)
except (KeyError, FileNotFoundError):
    sys.exit(1)
"
}

# Helper: get context patterns from config
get_context_patterns() {
    local project_name="$1"
    local context_name="$2"
    read_config
    python3 -c "
import json
import sys
try:
    with open('$CONFIG_FILE', 'r') as f:
        config = json.load(f)
    
    context = config['projects']['$project_name']['contexts']['$context_name']
    include_patterns = ','.join(context['include_patterns'])
    exclude_patterns = ','.join(context['exclude_patterns'])
    
    # Add global excludes
    global_excludes = config['global_settings']['default_exclude_patterns']
    all_excludes = context['exclude_patterns'] + global_excludes
    exclude_patterns = ','.join(list(set(all_excludes)))  # Remove duplicates
    
    print(f'{include_patterns}|{exclude_patterns}')
except (KeyError, FileNotFoundError):
    sys.exit(1)
"
}

# Helper: list available projects
list_projects() {
    read_config
    echo "Доступные проекты:"
    python3 -c "
import json
with open('$CONFIG_FILE', 'r') as f:
    config = json.load(f)
for project_name in config['projects']:
    print(f'  - {project_name}')
"
}

# Helper: list available contexts for a project
list_contexts() {
    local project_name="$1"
    read_config
    echo "Доступные контексты для проекта '$project_name':"
    python3 -c "
import json
import sys
try:
    with open('$CONFIG_FILE', 'r') as f:
        config = json.load(f)
    contexts = config['projects']['$project_name']['contexts']
    for context_name, context_data in contexts.items():
        description = context_data.get('description', 'No description')
        print(f'  - {context_name}: {description}')
except KeyError:
    print('Проект не найден')
    sys.exit(1)
"
}

# Helper: get template path
get_template_path() {
    local template_name="$1"
    read_config
    python3 -c "
import json
try:
    with open('$CONFIG_FILE', 'r') as f:
        config = json.load(f)
    templates = config['global_settings']['templates']
    if '$template_name' in templates:
        print(templates['$template_name'])
    else:
        print('$template_name')  # Return as-is if not found in config
except:
    print('$template_name')
"
}

# Helper: list available templates
list_templates() {
    read_config
    echo "Доступные шаблоны:"
    python3 -c "
import json
with open('$CONFIG_FILE', 'r') as f:
    config = json.load(f)
templates = config['global_settings']['templates']
template_contexts = config['global_settings'].get('template_contexts', {})
for template_name, template_file in templates.items():
    if template_name in template_contexts:
        description = template_contexts[template_name]['description']
        print(f'  - {template_name}: {description}')
    else:
        print(f'  - {template_name}: {template_file}')
"
}

# Функция для обрезки дерева проекта из файла
trim_project_tree() {
    local file_path="$1"
    local temp_file="${file_path}.tmp"
    
    # Ищем начало содержимого файлов (строка с путем к файлу, начинающаяся с `)
    local first_file_line=$(grep -n "^\`.*\`:" "$file_path" | head -1 | cut -d: -f1)
    
    if [[ -n "$first_file_line" ]]; then
        # Создаём компактное дерево только из включённых файлов
        {
            echo "Project Path: $(basename "$(dirname "$file_path")" | sed 's/cc2p_//' | sed 's/_quality-control//')"
            echo ""
            echo "Quality Control Files Tree"
            echo "========================="
            echo ""
            
            # Извлекаем пути файлов из содержимого и очищаем их
            grep "^\`.*\`:" "$file_path" | sed 's/^\`\(.*\)\`:.*$/\1/' | sed 's|/private/var/folders/.*/tmp\.[^/]*/||g' | sort | while read -r filepath; do
                echo "├── $filepath"
            done
            
            echo ""
            echo "File Contents"
            echo "============="
            echo ""
            
            # Берём всё начиная с первого файла
            tail -n +$first_file_line "$file_path"
        } > "$temp_file"
        
        # Заменяем оригинальный файл
        mv "$temp_file" "$file_path"
        
        echo "🌳 Дерево проекта заменено на компактный список включённых файлов"
    else
        echo "⚠️  Содержимое файлов не найдено - дерево не обрезано"
    fi
}

# Helper: get template info
get_template_info() {
    local template_name="$1"
    read_config
    echo "Информация о шаблоне '$template_name':"
    python3 -c "
import json
import sys
try:
    with open('$CONFIG_FILE', 'r') as f:
        config = json.load(f)
    templates = config['global_settings']['templates']
    template_contexts = config['global_settings'].get('template_contexts', {})
    
    if '$template_name' not in templates:
        print('Шаблон не найден')
        sys.exit(1)
    
    template_file = templates['$template_name']
    print(f'Файл шаблона: {template_file}')
    
    if '$template_name' in template_contexts:
        context = template_contexts['$template_name']
        print(f'Описание: {context[\"description\"]}')
        print(f'Лучше всего подходит для: {\", \".join(context[\"best_for\"])}')
        print(f'Суффикс выходного файла: {context[\"output_suffix\"]}')
    else:
        print('Дополнительная информация недоступна')
except KeyError as e:
    print(f'Ошибка конфигурации: {e}')
    sys.exit(1)
"
}

# Helper: smart template recommendation
smart_template_recommendation() {
    local project_name="$1"
    local context_name="$2"
    local template_name="$3"
    read_config
    python3 -c "
import json
import sys
try:
    with open('$CONFIG_FILE', 'r') as f:
        config = json.load(f)
    
    template_contexts = config['global_settings'].get('template_contexts', {})
    
    if '$template_name' in template_contexts:
        template_info = template_contexts['$template_name']
        best_for = template_info['best_for']
        
        if '$context_name' in best_for:
            print('✅ ОТЛИЧНЫЙ ВЫБОР: Этот шаблон идеально подходит для данного контекста')
        else:
            print('⚠️  ПРЕДУПРЕЖДЕНИЕ: Этот шаблон может не подходить для данного контекста')
            print(f'Рекомендуемые контексты: {\", \".join(best_for)}')
    else:
        print('ℹ️  Информация о совместимости недоступна')
        
except Exception as e:
    print(f'Ошибка: {e}')
"
}

if [ "$COMMAND" = "listprojects" ]; then
    list_projects
    exit 0

elif [ "$COMMAND" = "listcontexts" ]; then
    if [ -z "${ARGS[1]}" ]; then
        echo "Ошибка: Необходимо указать имя проекта."
        echo "Использование: $0 listcontexts <project_name>"
        exit 1
    fi
    list_contexts "${ARGS[1]}"
    exit 0

elif [ "$COMMAND" = "listtemplates" ]; then
    list_templates
    exit 0

elif [ "$COMMAND" = "templateinfo" ]; then
    if [ -z "${ARGS[1]}" ]; then
        echo "Ошибка: Необходимо указать имя шаблона."
        echo "Использование: $0 templateinfo <template_name>"
        echo ""
        list_templates
        exit 1
    fi
    get_template_info "${ARGS[1]}"
    exit 0

elif [ "$COMMAND" = "smarttemplate" ]; then
    if [ -z "${ARGS[1]}" ] || [ -z "${ARGS[2]}" ] || [ -z "${ARGS[3]}" ]; then
        echo "Ошибка: Необходимо указать проект, контекст и шаблон."
        echo "Использование: $0 smarttemplate <project_name> <context> <template>"
        echo ""
        echo "Доступные проекты:"
        list_projects
        echo ""
        echo "Доступные шаблоны:"
        list_templates
        exit 1
    fi
    smart_template_recommendation "${ARGS[1]}" "${ARGS[2]}" "${ARGS[3]}"
    exit 0

elif [ "$COMMAND" = "ccode2prompt" ]; then
    if [ -z "${ARGS[1]}" ]; then
        echo "Ошибка: Необходимо указать имя проекта."
        echo "Использование: $0 ccode2prompt <project_name> [context] [--timestamp] [--template=template_name]"
        echo ""
        list_projects
        exit 1
    fi

    PROJECT_NAME="${ARGS[1]}"
    CONTEXT_NAME="${ARGS[2]:-source}"  # Default to 'source' context
    
    # Get project path
    PROJECT_PATH=$(get_project_path "$PROJECT_NAME")
    if [ $? -ne 0 ]; then
        echo "Ошибка: Проект '$PROJECT_NAME' не найден в конфигурации."
        echo ""
        list_projects
        exit 1
    fi

    # Check if project path exists
    if [ ! -d "$PROJECT_PATH" ]; then
        echo "Ошибка: Путь к проекту не существует: $PROJECT_PATH"
        exit 1
    fi

    # Get context patterns
    PATTERNS=$(get_context_patterns "$PROJECT_NAME" "$CONTEXT_NAME")
    if [ $? -ne 0 ]; then
        echo "Ошибка: Контекст '$CONTEXT_NAME' не найден для проекта '$PROJECT_NAME'."
        echo ""
        list_contexts "$PROJECT_NAME"
        exit 1
    fi

    IFS='|' read -r INCLUDE_PATTERNS EXCLUDE_PATTERNS <<< "$PATTERNS"

    # Setup output with template suffix
    OUTPUT_DIR="$STATIC_DIR/code2prompt/"
    mkdir -p "$OUTPUT_DIR"
    
    # Get template suffix if using template
    TEMPLATE_SUFFIX=""
    if [ -n "$TEMPLATE_FLAG" ]; then
        TEMPLATE_SUFFIX=$(python3 -c "
import json
try:
    with open('$CONFIG_FILE', 'r') as f:
        config = json.load(f)
    template_contexts = config['global_settings'].get('template_contexts', {})
    if '$TEMPLATE_FLAG' in template_contexts:
        print(template_contexts['$TEMPLATE_FLAG']['output_suffix'])
    else:
        print('_${TEMPLATE_FLAG}')
except:
    print('_${TEMPLATE_FLAG}')
")
    fi
    
    OUTPUT_FILE="$OUTPUT_DIR$(get_output_name "cc2p_${PROJECT_NAME}_${CONTEXT_NAME}${TEMPLATE_SUFFIX}" "txt")"

    # Special handling for quality-control context
    if [ "$CONTEXT_NAME" = "quality-control" ]; then
        echo "=== СПЕЦИАЛЬНЫЙ РЕЖИМ: QUALITY CONTROL ==="
        echo "Проект: $PROJECT_NAME"
        echo "Контекст: $CONTEXT_NAME"
        echo "Путь: $PROJECT_PATH"
        
        # Add template if specified
        if [ -n "$TEMPLATE_FLAG" ]; then
            TEMPLATE_PATH=$(get_template_path "$TEMPLATE_FLAG")
            echo "Шаблон: $TEMPLATE_FLAG ($TEMPLATE_PATH)"
            
            # Show smart recommendation
            echo "=== АНАЛИЗ ШАБЛОНА ==="
            smart_template_recommendation "$PROJECT_NAME" "$CONTEXT_NAME" "$TEMPLATE_FLAG"
            echo ""
        fi
        
        # Use special quality control extractor
        EXTRACTOR_SCRIPT="$CURRENT_DIR/automations/code2prompt/quality_control_extractor.sh"
        if [ -f "$EXTRACTOR_SCRIPT" ]; then
            "$EXTRACTOR_SCRIPT" "$PROJECT_PATH" "$OUTPUT_FILE" "$CONFIG_FILE"
        else
            echo "Ошибка: Скрипт экстрактора не найден: $EXTRACTOR_SCRIPT"
            exit 1
        fi
    else
        # Build code2prompt command for other contexts
        CMD_ARGS=("$PROJECT_PATH" "--tokens" "--output" "$OUTPUT_FILE")
        
        if [ -n "$INCLUDE_PATTERNS" ]; then
            CMD_ARGS+=("--include" "$INCLUDE_PATTERNS")
        fi
        
        if [ -n "$EXCLUDE_PATTERNS" ]; then
            CMD_ARGS+=("--exclude" "$EXCLUDE_PATTERNS")
        fi

        # Add template if specified
        if [ -n "$TEMPLATE_FLAG" ]; then
            TEMPLATE_PATH=$(get_template_path "$TEMPLATE_FLAG")
            CMD_ARGS+=("--template" "$TEMPLATE_PATH")
            
            # Show smart recommendation
            echo "=== АНАЛИЗ ШАБЛОНА ==="
            smart_template_recommendation "$PROJECT_NAME" "$CONTEXT_NAME" "$TEMPLATE_FLAG"
            echo ""
        fi

        echo "Выполняется: code2prompt ${CMD_ARGS[*]}"
        echo "Проект: $PROJECT_NAME"
        echo "Контекст: $CONTEXT_NAME"
        echo "Путь: $PROJECT_PATH"
        echo "Include: $INCLUDE_PATTERNS"
        echo "Exclude: $EXCLUDE_PATTERNS"
        if [ -n "$TEMPLATE_FLAG" ]; then
            echo "Шаблон: $TEMPLATE_FLAG ($TEMPLATE_PATH)"
        fi
        
        # Execute code2prompt
        code2prompt "${CMD_ARGS[@]}"
    fi

    if [ -f "$OUTPUT_FILE" ]; then
        # Check if context has trim_tree flag
        TRIM_TREE=$(python3 -c "
import json
try:
    with open('$CONFIG_FILE', 'r') as f:
        config = json.load(f)
    projects = config['projects']
    if '$PROJECT_NAME' in projects and '$CONTEXT_NAME' in projects['$PROJECT_NAME']['contexts']:
        context = projects['$PROJECT_NAME']['contexts']['$CONTEXT_NAME']
        print(context.get('trim_tree', False))
    else:
        print(False)
except:
    print(False)
")
        
        # Trim tree if flag is set
        if [ "$TRIM_TREE" = "True" ]; then
            trim_project_tree "$OUTPUT_FILE"
        fi
        
        FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
        echo "Файл успешно сохранён: $OUTPUT_FILE"
        echo "Размер файла: $FILE_SIZE"
    else
        echo "Ошибка: Файл не был создан."
        exit 1
    fi

elif [ "$COMMAND" = "treecode2prompt" ]; then
    # If no second argument provided, use current directory
    if [ -z "$INPUT_FOLDER" ]; then
        INPUT_FOLDER="."
    fi
    
    # Проверяем существование пути
    if [ ! -e "$INPUT_FOLDER" ]; then
        INPUT_FOLDER="$CURRENT_DIR/$INPUT_FOLDER"
        if [ ! -e "$INPUT_FOLDER" ]; then
            echo "Ошибка: Путь не существует: ${ARGS[1]}"
            exit 1
        fi
    fi

    # Получаем путь к папке
    if [ "$INPUT_FOLDER" = "." ]; then
        FOLDER_NAME=$(basename "$CURRENT_DIR")
    else
        FOLDER_NAME=$(basename "$INPUT_FOLDER")
    fi

    OUTPUT_DIR="$STATIC_DIR/code2prompt/"
    DOCS_DIR="$CURRENT_DIR/docs/meta/repo-maps/"
    mkdir -p "$OUTPUT_DIR" "$DOCS_DIR"

    OUTPUT_FILE="$OUTPUT_DIR$(get_output_name "tree_src" "txt")"
    TREE_MD_FILE="$DOCS_DIR/TREE.md"

    # Generate content for both files
    TREE_CONTENT="# Repository Structure\n\nGenerated on: $(date '+%Y-%m-%d %H:%M')\n\n## File Tree\n\`\`\`\n"
    TREE_CONTENT+="$(cd "$CURRENT_DIR" && find "$INPUT_FOLDER" -type f -not -path "*/\.*" | sort | tree --fromfile)"
    TREE_CONTENT+="\n\`\`\`\n\n## Statistics\n"
    
    # Get line count
    TOTAL_LINES=$(find "$INPUT_FOLDER" -type f -not -path "*/\.*" -exec wc -l {} + | tail -n1)
    TREE_CONTENT+="\n### Line Count\n\`\`\`\n$TOTAL_LINES\n\`\`\`\n"
    
    # Get folder size
    FOLDER_SIZE=$(du -sh "$INPUT_FOLDER" | cut -f1)
    TREE_CONTENT+="\n### Repository Size\n\`\`\`\n$FOLDER_SIZE\n\`\`\`\n"

    # Save to references output
    echo "=== File Tree ===" > "$OUTPUT_FILE"
    cd "$CURRENT_DIR" && find "$INPUT_FOLDER" -type f -not -path "*/\.*" | sort | tree --fromfile >> "$OUTPUT_FILE"
    
    echo -e "\n=== Line Count Statistics ===" >> "$OUTPUT_FILE"
    echo "Total lines of code: $TOTAL_LINES" >> "$OUTPUT_FILE"
    
    echo -e "\n=== Size Statistics ===" >> "$OUTPUT_FILE"
    echo "Total folder size: $FOLDER_SIZE" >> "$OUTPUT_FILE"

    # Save to TREE.md
    echo -e "$TREE_CONTENT" > "$TREE_MD_FILE"

    if [ -f "$OUTPUT_FILE" ] && [ -f "$TREE_MD_FILE" ]; then
        FILE_SIZE=$(du -sh "$OUTPUT_FILE" | cut -f1)
        echo "Файл успешно сохранён: $OUTPUT_FILE"
        echo "Размер файла: $FILE_SIZE"
        echo "Tree documentation сохранён в: $TREE_MD_FILE"
        
        # Display the content in terminal as well
        cat "$OUTPUT_FILE"
    else
        echo "Ошибка: Один или оба файла не были созданы."
        exit 1
    fi

elif [ "$COMMAND" = "bcode2prompt" ]; then
    if [ -z "${ARGS[1]}" ]; then
        echo "Ошибка: Необходимо указать файл с путями."
        echo "Использование: $0 bcode2prompt <файл с путями> [--timestamp]"
        exit 1
    fi

    INPUT_FILE="${ARGS[1]}"
    # Проверяем, существует ли файл как абсолютный путь или относительный
    if [ ! -f "$INPUT_FILE" ]; then
        # Пробуем относительный путь от текущей директории
        INPUT_FILE="$CURRENT_DIR/${ARGS[1]}"
        if [ ! -f "$INPUT_FILE" ]; then
            echo "Ошибка: Файл не найден: ${ARGS[1]}"
            exit 1
        fi
    fi

    OUTPUT_DIR="$STATIC_DIR/code2prompt/"
    mkdir -p "$OUTPUT_DIR"

    FILE_BASENAME=$(basename "$INPUT_FILE" .txt)
    OUTPUT_FILE="$OUTPUT_DIR$(get_output_name "bcode2prompt_${FILE_BASENAME}" "txt")"

    > "$OUTPUT_FILE"  # Создаем или очищаем файл перед записью

    # Счетчик успешных операций
    SUCCESS_COUNT=0
    TOTAL_COUNT=0

    while IFS= read -r path; do
        if [ -n "$path" ]; then
            TOTAL_COUNT=$((TOTAL_COUNT + 1))
            echo "Обработка пути: $path"
            
            # Проверяем существование пути относительно текущей директории
            FULL_PATH="$CURRENT_DIR/$path"
            if [ -e "$FULL_PATH" ]; then
                echo "Найден путь: $FULL_PATH"
                # Create a temporary file for each run
                TEMP_FILE=$(mktemp)
                
                echo -e "\n### Content from: $path ###" >> "$OUTPUT_FILE"
                cd "$CURRENT_DIR" && {
                    # Run code2prompt and save output to temp file
                    code2prompt "$path" > "$TEMP_FILE"
                    # Get content from clipboard and append to output file
                    pbpaste >> "$OUTPUT_FILE"
                    # Add token count info
                    code2prompt "$path" --tokens >> "$OUTPUT_FILE"
                }
                if [ $? -eq 0 ]; then
                    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
                    echo -e "\n-------------------\n" >> "$OUTPUT_FILE"
                fi
                # Clean up temp file
                rm "$TEMP_FILE"
            else
                echo "Ошибка: Путь не существует: $FULL_PATH"
            fi
        fi
    done < "$INPUT_FILE"

    echo "Обработано путей: $TOTAL_COUNT, Успешно: $SUCCESS_COUNT"

    if [ -f "$OUTPUT_FILE" ]; then
        FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
        echo "Файл успешно сохранён: $OUTPUT_FILE"
        echo "Размер файла: $FILE_SIZE"
    else
        echo "Ошибка: Файл не был создан."
        exit 1
    fi

else
    # Regular acode2prompt functionality
    INPUT_FOLDER="${ARGS[0]}"
    
    # Получаем путь к папке
    if [ "$INPUT_FOLDER" = "." ]; then
        FOLDER_NAME=$(basename "$CURRENT_DIR")
    else
        FOLDER_NAME=$(basename "$INPUT_FOLDER")
    fi

    OUTPUT_DIR="$STATIC_DIR/code2prompt/"
    mkdir -p "$OUTPUT_DIR"

    OUTPUT_FILE="$OUTPUT_DIR$(get_output_name "c2p_${FOLDER_NAME}" "txt")"

    cd "$CURRENT_DIR" && code2prompt "$INPUT_FOLDER" --tokens --output "$OUTPUT_FILE"

    if [ -f "$OUTPUT_FILE" ]; then
        FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
        echo "Файл успешно сохранён: $OUTPUT_FILE"
        echo "Размер файла: $FILE_SIZE"
    else
        echo "Ошибка: Файл не был создан."
        exit 1
    fi
fi

