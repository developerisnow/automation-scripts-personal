#!/usr/bin/env python3
"""
Скрипт для анализа Markdown заметок в каталоге /Users/user/____Sandruk

Генерирует два CSV отчёта:
1. markdown-notes-by-folders.csv: для каждой папки (с учётом игнорирования каталогов из .scanignore,
   скрытых папок, .obsidian, node_modules, симлинков и указанных в EXCLUDE_DIRS):
     - folder, kb size md files, number of md files, number total lines of markdown files
2. md-notes-list-top-200.csv: топ 200 заметок (по размеру) со столбцами:
   - title, size kb, lines, folder path(only last)

Прочие варианты отчётов можно добавить позже.
"""

import os
import csv

# Задайте корневой путь
ROOT_PATH = "/Users/user/____Sandruk"

# Список подстрок для исключения (старый список)
EXCLUDE_DIRS = {"__Repositories", "__Vaults_Databases", "__Templates", "renamed", "symlink"}

def load_scanignore(root):
    """
    Загружает паттерны игнорирования из файла .scanignore.
    Если файла нет – создаёт его с дефолтными значениями.
    """
    scanignore_file = os.path.join(root, ".scanignore")
    defaults = {".obsidian", "node_modules"}
    patterns = set()
    if os.path.exists(scanignore_file):
        with open(scanignore_file, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#"):
                    patterns.add(line)
    else:
        # Файл отсутствует – создаём с дефолтными значениями
        patterns = defaults.copy()
        with open(scanignore_file, "w", encoding="utf-8") as f:
            for pattern in defaults:
                f.write(pattern + "\n")
        print(f"Создан дефолтный файл {scanignore_file}")
    return patterns

def should_skip_dir(dirpath, ignore_set):
    """Проверяет, следует ли пропустить каталог.

    Критерии:
    - если базовое имя начинается с точки (скрытый каталог);
    - если хотя бы один сегмент пути точно совпадает с элементом ignore_set;
    """
    base = os.path.basename(dirpath)
    if base.startswith('.') and base != '.':
        return True
    # Разбиваем путь и проверяем каждую его часть
    parts = os.path.normpath(dirpath).split(os.sep)
    for part in parts:
        if part in ignore_set:
            return True
    return False

def get_markdown_stats(root):
    # Загружаем паттерны из .scanignore и объединяем с EXCLUDE_DIRS
    ignore_set = load_scanignore(root).union(EXCLUDE_DIRS)

    folder_stats = {}  # ключ = относительный путь папки, значение = {'kb': ..., 'count': ..., 'lines': ...}
    file_stats = []    # список статистики по отдельным файлам

    for dirpath, dirnames, filenames in os.walk(root):
        # Фильтруем подкаталоги: удаляем из списка те, что надо пропустить
        dirnames[:] = [d for d in dirnames if not should_skip_dir(os.path.join(dirpath, d), ignore_set)]
        # Если сам текущий каталог нужно пропустить – переход к следующему
        if should_skip_dir(dirpath, ignore_set):
            continue

        # Обрабатываем только .md файлы и пропускаем симлинки
        md_files = [f for f in filenames if f.endswith(".md") and not os.path.islink(os.path.join(dirpath, f))]
        if not md_files:
            continue

        rel_folder = os.path.relpath(dirpath, root)
        total_kb = 0.0
        total_lines = 0
        count_files = 0

        for f in md_files:
            full_path = os.path.join(dirpath, f)
            try:
                size_bytes = os.path.getsize(full_path)
                kb = size_bytes / 1024.0
            except Exception as e:
                kb = 0.0
            num_lines = 0
            try:
                with open(full_path, "r", encoding="utf-8") as file:
                    lines = file.readlines()
                    num_lines = len(lines)
            except Exception as e:
                pass

            total_kb += kb
            total_lines += num_lines
            count_files += 1

            # Для списка файлов — берем имя файла, размер, количество строк и последнее имя папки
            last_folder = os.path.basename(dirpath)
            file_stats.append({
                "title": f,
                "size_kb": kb,
                "lines": num_lines,
                "folder": last_folder
            })

        folder_stats[rel_folder] = {
            "kb": total_kb,
            "count": count_files,
            "lines": total_lines
        }

    return folder_stats, file_stats

def write_folder_report(folder_stats, filename="markdown-notes-by-folders.csv"):
    with open(filename, "w", newline="", encoding="utf-8") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(["folder", "kb size md files", "number of md files", "number total lines of markdown files"])
        for folder, stats in sorted(folder_stats.items()):
            writer.writerow([folder, f"{stats['kb']:.2f}", stats['count'], stats['lines']])
    print(f"Файл {filename} записан.")

def write_top_files_report(file_stats, filename="md-notes-list-top-200.csv", top_n=200):
    # Сортируем файлы по размеру (от большего к меньшему)
    file_stats_sorted = sorted(file_stats, key=lambda x: x["size_kb"], reverse=True)
    top_files = file_stats_sorted[:top_n]

    with open(filename, "w", newline="", encoding="utf-8") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(["title", "size kb", "lines", "folder path(only last)"])
        for f in top_files:
            writer.writerow([f["title"], f"{f['size_kb']:.2f}", f["lines"], f["folder"]])
    print(f"Файл {filename} записан.")

if __name__ == "__main__":
    folders, files = get_markdown_stats(ROOT_PATH)
    write_folder_report(folders)
    write_top_files_report(files) 