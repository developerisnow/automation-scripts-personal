#!/bin/bash

# Проверяем, указана ли команда или папка
if [ -z "$1" ]; then
    echo "Ошибка: Необходимо указать команду или путь к папке."
    echo "Использование:"
    echo "  $0 <путь к папке>"
    echo "  $0 bcode2prompt <файл с путями>"
    exit 1
fi

# Сохраняем текущую директорию
CURRENT_DIR=$(pwd)
echo "Текущая директория: $CURRENT_DIR"

COMMAND=$1

if [ "$COMMAND" = "bcode2prompt" ]; then
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

    OUTPUT_DIR="$CURRENT_DIR/.references/o1-pro/"
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
    INPUT_FOLDER="$1"
    
    # Проверяем существование пути
    if [ ! -e "$INPUT_FOLDER" ]; then
        INPUT_FOLDER="$CURRENT_DIR/$1"
        if [ ! -e "$INPUT_FOLDER" ]; then
            echo "Ошибка: Путь не существует: $1"
            exit 1
        fi
    fi

    # Получаем путь к папке
    if [ "$INPUT_FOLDER" = "." ]; then
        FOLDER_NAME=$(basename "$CURRENT_DIR")
    else
        FOLDER_NAME=$(basename "$INPUT_FOLDER")
    fi

    OUTPUT_DIR="$CURRENT_DIR/.references/o1-pro/"
    mkdir -p "$OUTPUT_DIR"

    TIMESTAMP=$(date '+%Y-%m-%d_%H-%M')
    OUTPUT_FILE="${OUTPUT_DIR}prompt_${FOLDER_NAME}_${TIMESTAMP}.txt"

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

