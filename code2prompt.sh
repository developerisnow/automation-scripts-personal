#!/bin/bash

# Проверяем, указана ли команда или папка
if [ -z "$1" ]; then
    echo "Ошибка: Необходимо указать команду или путь к папке."
    echo "Использование:"
    echo "  $0 <путь к папке>"
    echo "  $0 bcode2prompt <файл с путями>"
    echo "  $0 treecode2prompt <путь к папке>"
    exit 1
fi

# Сохраняем текущую директорию
CURRENT_DIR=$(pwd)
STATIC_DIR="/Users/user/____Sandruk/___PKM/temp"
echo "Текущая директория: $CURRENT_DIR"

COMMAND=$1
INPUT_FOLDER="$2"

# Check if this is a treecode2prompt command first
if [ "$COMMAND" = "treecode2prompt" ]; then
    # If no second argument provided, use current directory
    if [ -z "$INPUT_FOLDER" ]; then
        INPUT_FOLDER="."
    fi
    
    # Проверяем существование пути
    if [ ! -e "$INPUT_FOLDER" ]; then
        INPUT_FOLDER="$CURRENT_DIR/$INPUT_FOLDER"
        if [ ! -e "$INPUT_FOLDER" ]; then
            echo "Ошибка: Путь не существует: $2"
            exit 1
        fi
    fi

    # Получаем путь к папке
    if [ "$INPUT_FOLDER" = "." ]; then
        FOLDER_NAME=$(basename "$CURRENT_DIR")
    else
        FOLDER_NAME=$(basename "$INPUT_FOLDER")
    fi

    # Create both output directories
    OUTPUT_DIR="$STATIC_DIR/code2prompt/"
    DOCS_DIR="$CURRENT_DIR/docs/meta/repo-maps/"
    mkdir -p "$OUTPUT_DIR" "$DOCS_DIR"

    TIMESTAMP=$(date '+%Y-%m-%d_%H-%M')
    OUTPUT_FILE="${OUTPUT_DIR}tree_src_${TIMESTAMP}.txt"
    TREE_MD_FILE="${DOCS_DIR}TREE.md"

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
    if [ -z "$2" ]; then
        echo "Ошибка: Необходимо указать файл с путями."
        echo "Использование: $0 bcode2prompt <файл с путями>"
        exit 1
    fi

    INPUT_FILE="$2"
    # Проверяем, существует ли файл как абсолютный путь или относительный
    if [ ! -f "$INPUT_FILE" ]; then
        # Пробуем относительный путь от текущей директории
        INPUT_FILE="$CURRENT_DIR/$2"
        if [ ! -f "$INPUT_FILE" ]; then
            echo "Ошибка: Файл не найден: $2"
            exit 1
        fi
    fi

    OUTPUT_DIR="$STATIC_DIR/code2prompt/"
    mkdir -p "$OUTPUT_DIR"

    TIMESTAMP=$(date '+%Y-%m-%d_%H-%M')
    FILE_BASENAME=$(basename "$INPUT_FILE" .txt)
    OUTPUT_FILE="${OUTPUT_DIR}bcode2prompt_${FILE_BASENAME}_${TIMESTAMP}.txt"

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
    INPUT_FOLDER="$1"
    
    # Получаем путь к папке
    if [ "$INPUT_FOLDER" = "." ]; then
        FOLDER_NAME=$(basename "$CURRENT_DIR")
    else
        FOLDER_NAME=$(basename "$INPUT_FOLDER")
    fi

    OUTPUT_DIR="$STATIC_DIR/code2prompt/"
    mkdir -p "$OUTPUT_DIR"

    TIMESTAMP=$(date '+%Y-%m-%d_%H-%M')
    OUTPUT_FILE="${OUTPUT_DIR}c2p_${FOLDER_NAME}_${TIMESTAMP}.txt"

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

