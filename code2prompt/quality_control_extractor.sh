#!/bin/bash

# Quality Control Files Extractor
# Создаёт временную папку с только нужными файлами для quality control

PROJECT_PATH="$1"
OUTPUT_DIR="$2"
CONFIG_FILE="$3"

if [ -z "$PROJECT_PATH" ] || [ -z "$OUTPUT_DIR" ] || [ -z "$CONFIG_FILE" ]; then
    echo "Usage: $0 <project_path> <output_dir> <config_file>"
    exit 1
fi

# Создаём временную папку
TEMP_DIR=$(mktemp -d)
echo "Создаю временную папку: $TEMP_DIR"

# Копируем файлы из корня проекта
cd "$PROJECT_PATH"

# Получаем список корневых файлов из конфигурации
ROOT_FILES=$(python3 -c "
import json
import sys
try:
    with open('$CONFIG_FILE', 'r') as f:
        config = json.load(f)
    
    # Получаем include_patterns для quality-control
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

# Копируем корневые файлы
for file in $ROOT_FILES; do
    if [ -f "$file" ]; then
        cp "$file" "$TEMP_DIR/"
        echo "✓ $file"
    fi
done

# .lefthook папка
if [ -d ".lefthook" ]; then
    cp -r ".lefthook" "$TEMP_DIR/"
    echo "✓ .lefthook/"
fi

# .github папка (только yml/yaml файлы)
if [ -d ".github" ]; then
    mkdir -p "$TEMP_DIR/.github"
    find ".github" -name "*.yml" -o -name "*.yaml" | while read -r file; do
        mkdir -p "$TEMP_DIR/$(dirname "$file")"
        cp "$file" "$TEMP_DIR/$file"
        echo "✓ $file"
    done
fi

# Обрабатываем остальные паттерны из конфигурации
python3 -c "
import json
import sys
import os
import glob
import shutil

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
                shutil.copytree(dir_path, dest_path, dirs_exist_ok=True)
                print(f'✓ {dir_path}/')
        else:
            # Файлы по паттернам
            for file_path in glob.glob(pattern, recursive=True):
                if os.path.isfile(file_path):
                    dest_file = os.path.join('$TEMP_DIR', file_path)
                    os.makedirs(os.path.dirname(dest_file), exist_ok=True)
                    shutil.copy2(file_path, dest_file)
                    print(f'✓ {file_path}')

except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
"

echo ""
echo "Файлы скопированы в: $TEMP_DIR"
echo "Количество файлов: $(find "$TEMP_DIR" -type f | wc -l)"

# Запускаем code2prompt на временной папке
echo ""
echo "Запускаю code2prompt..."
code2prompt "$TEMP_DIR" --tokens --output "$OUTPUT_DIR"

# Удаляем временную папку
rm -rf "$TEMP_DIR"
echo "Временная папка удалена" 