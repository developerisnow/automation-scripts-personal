#!/bin/bash

# Quality Control Files Extractor
# Создаёт временную папку с только нужными файлами для quality control
# Поддерживает YAML preprocessing и анализ размеров файлов

PROJECT_PATH="$1"
OUTPUT_FILE="$2"
CONFIG_FILE="$3"

if [ -z "$PROJECT_PATH" ] || [ -z "$OUTPUT_FILE" ] || [ -z "$CONFIG_FILE" ]; then
    echo "Usage: $0 <project_path> <output_file> <config_file>"
    exit 1
fi

# Получаем настройки контекста
CONTEXT_SETTINGS=$(python3 -c "
import json
import sys
try:
    with open('$CONFIG_FILE', 'r') as f:
        config = json.load(f)
    
    context = config['projects']['hypetrain-backend']['contexts']['quality-control']
    yaml_preprocessing = context.get('yaml_preprocessing', False)
    file_size_analysis = context.get('file_size_analysis', False)
    trim_tree = context.get('trim_tree', False)
    
    print(f'{yaml_preprocessing}|{file_size_analysis}|{trim_tree}')
except Exception as e:
    print('False|False|False', file=sys.stderr)
    sys.exit(1)
")

IFS='|' read -r YAML_PREPROCESSING FILE_SIZE_ANALYSIS TRIM_TREE <<< "$CONTEXT_SETTINGS"

# Создаём временную папку
TEMP_DIR=$(mktemp -d)
echo "=== QUALITY CONTROL EXTRACTOR ==="
echo "Проект: $PROJECT_PATH"
echo "Выходной файл: $OUTPUT_FILE"
echo "YAML preprocessing: $YAML_PREPROCESSING"
echo "File size analysis: $FILE_SIZE_ANALYSIS"
echo "Trim tree: $TRIM_TREE"
echo "Временная папка: $TEMP_DIR"
echo ""

# Переходим в проект
cd "$PROJECT_PATH"

# Копируем файлы из корня проекта
ROOT_FILES=$(python3 -c "
import json
import sys
try:
    with open('$CONFIG_FILE', 'r') as f:
        config = json.load(f)
    
    patterns = config['projects']['hypetrain-backend']['contexts']['quality-control']['include_patterns']
    
    # Фильтруем только корневые файлы (без слешей и звёздочек)
    root_files = []
    for pattern in patterns:
        if '/' not in pattern and '*' not in pattern and not pattern.startswith('.'):
            root_files.append(pattern)
        elif pattern.startswith('.') and '/' not in pattern and '*' not in pattern:
            root_files.append(pattern)
    
    print(' '.join(root_files))
except Exception as e:
    print('', file=sys.stderr)
    sys.exit(1)
")

# Файлы для отслеживания размеров
if [ "$FILE_SIZE_ANALYSIS" = "True" ]; then
    FILE_SIZES_LIST=$(mktemp)
    trap 'rm -f "$FILE_SIZES_LIST"' EXIT
fi

# Функция копирования с YAML preprocessing
copy_file_with_preprocessing() {
    local src_file="$1"
    local dest_file="$2"
    
    if [ "$YAML_PREPROCESSING" = "True" ] && [[ "$src_file" == *.yml || "$src_file" == *.yaml ]]; then
        # Удаляем комментарии и пустые строки из YAML
        grep -v '^[[:space:]]*#' "$src_file" | grep -v '^[[:space:]]*$' > "$dest_file"
    else
        cp "$src_file" "$dest_file"
    fi
    
    # Записываем размер файла
    if [ "$FILE_SIZE_ANALYSIS" = "True" ]; then
        file_size=$(stat -f%z "$dest_file" 2>/dev/null || stat -c%s "$dest_file" 2>/dev/null || echo "0")
        printf "%10d %s\n" "$file_size" "$src_file" >> "$FILE_SIZES_LIST"
    fi
}

# Копируем корневые файлы
echo "📁 Копирую корневые файлы..."
for file in $ROOT_FILES; do
    if [ -f "$file" ]; then
        copy_file_with_preprocessing "$file" "$TEMP_DIR/$file"
        echo "✓ $file"
    fi
done

# Обрабатываем остальные паттерны из конфигурации
echo ""
echo "📁 Обрабатываю сложные паттерны..."
python3 -c "
import json
import sys
import os
import glob
import shutil
import subprocess

def copy_with_preprocessing(src, dest):
    \"\"\"Копирует файл с учётом YAML preprocessing\"\"\"
    if '$YAML_PREPROCESSING' == 'True' and (src.endswith('.yml') or src.endswith('.yaml')):
        # Запускаем bash функцию для копирования с preprocessing
        subprocess.run(['bash', '-c', f'source $0; copy_file_with_preprocessing \"{src}\" \"{dest}\"'], 
                      cwd='$PWD', env=dict(os.environ, **{
                          'YAML_PREPROCESSING': '$YAML_PREPROCESSING',
                          'FILE_SIZE_ANALYSIS': '$FILE_SIZE_ANALYSIS',
                          'FILE_SIZES_LIST': '$FILE_SIZES_LIST'
                      }))
    else:
        os.makedirs(os.path.dirname(dest), exist_ok=True) if os.path.dirname(dest) else None
        shutil.copy2(src, dest)
        if '$FILE_SIZE_ANALYSIS' == 'True':
            file_size = os.path.getsize(dest)
            with open('$FILE_SIZES_LIST', 'a') as f:
                f.write(f'{file_size:>10} {src}\n')

try:
    with open('$CONFIG_FILE', 'r') as f:
        config = json.load(f)
    
    patterns = config['projects']['hypetrain-backend']['contexts']['quality-control']['include_patterns']
    
    for pattern in patterns:
        # Пропускаем корневые файлы (уже обработаны)
        if '/' not in pattern and '*' not in pattern:
            continue
        if pattern.startswith('.') and '/' not in pattern and '*' not in pattern:
            continue
            
        # Обрабатываем паттерны с путями
        if pattern.endswith('/**/*'):
            # Папки целиком
            dir_path = pattern.replace('/**/*', '')
            if os.path.isdir(dir_path):
                dest_path = os.path.join('$TEMP_DIR', dir_path)
                os.makedirs(os.path.dirname(dest_path), exist_ok=True)
                
                # Копируем каждый файл отдельно для preprocessing
                for root, dirs, files in os.walk(dir_path):
                    for file in files:
                        src_file = os.path.join(root, file)
                        rel_path = os.path.relpath(src_file, '.')
                        dest_file = os.path.join('$TEMP_DIR', rel_path)
                        os.makedirs(os.path.dirname(dest_file), exist_ok=True)
                        copy_with_preprocessing(src_file, dest_file)
                
                print(f'✓ {dir_path}/')
        else:
            # Файлы по паттернам
            for file_path in glob.glob(pattern, recursive=True):
                if os.path.isfile(file_path):
                    dest_file = os.path.join('$TEMP_DIR', file_path)
                    os.makedirs(os.path.dirname(dest_file), exist_ok=True)
                    copy_with_preprocessing(file_path, dest_file)
                    print(f'✓ {file_path}')

except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
"

echo ""
echo "📊 Статистика:"
echo "Временная папка: $TEMP_DIR"
echo "Количество файлов: $(find "$TEMP_DIR" -type f | wc -l)"

if [ "$FILE_SIZE_ANALYSIS" = "True" ]; then
    total_size=$(awk '{sum += $1} END {print sum}' "$FILE_SIZES_LIST")
    echo "Общий размер файлов: $((total_size / 1024)) KB"
fi

# Запускаем code2prompt на временной папке
echo ""
echo "🚀 Запускаю code2prompt..."
code2prompt "$TEMP_DIR" --tokens --output "$OUTPUT_FILE"

# Добавляем анализ размеров файлов в выходной файл
if [ "$FILE_SIZE_ANALYSIS" = "True" ] && [ -f "$OUTPUT_FILE" ]; then
    echo "" >> "$OUTPUT_FILE"
    echo "=== FILE SIZE ANALYSIS ===" >> "$OUTPUT_FILE"
    echo "Individual file sizes (after processing):" >> "$OUTPUT_FILE"
    echo "---------------------------------------" >> "$OUTPUT_FILE"
    sort -nr "$FILE_SIZES_LIST" | awk '{printf "%7.1f KB  %s\n", $1/1024, $2}' >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "Top 10 largest files:" >> "$OUTPUT_FILE"
    echo "--------------------" >> "$OUTPUT_FILE"
    sort -nr "$FILE_SIZES_LIST" | head -10 | awk '{printf "%7.1f KB  %s\n", $1/1024, $2}' >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

# Удаляем временную папку
rm -rf "$TEMP_DIR"
echo "✅ Временная папка удалена"

if [ -f "$OUTPUT_FILE" ]; then
    FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    echo "✅ Файл успешно создан: $OUTPUT_FILE"
    echo "📏 Размер файла: $FILE_SIZE"
else
    echo "❌ Ошибка: Файл не был создан"
    exit 1
fi 