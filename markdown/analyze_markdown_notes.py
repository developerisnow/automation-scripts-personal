#!/usr/bin/env python3
"""
Скрипт для анализа Markdown заметок в каталоге /Users/user/____Sandruk

Генерирует два CSV отчёта:
1. markdown-notes-by-folders.csv: для каждой папки:
   - folder, kb size md files, number of md files, number total lines of markdown files
2. md-notes-list-top-200.csv: топ 200 заметок (по размеру) со столбцами:
   - title, size kb, lines, folder path(only last)

При необходимости можно исключать определённые каталоги (например, __Repositories, __Vaults_Databases, __Templates, и т.п.) и симлинки.
"""

import os
import csv

# Задайте корневой путь
ROOT_PATH = "/Users/user/____Sandruk"

# Список подстрок для исключения (если папка содержит один из указанных идентификаторов, её можно пропустить)
EXCLUDE_DIRS = {"__Repositories", "__Vaults_Databases", "__Templates", "renamed", "symlink"}

def should_skip_dir(dirpath):
    """Проверяет, содержит ли dirpath любую из исключаемых подстрок."""
    for ex in EXCLUDE_DIRS:
        if ex in dirpath:
            return True
    return False

def get_markdown_stats(root):
    folder_stats = {}  # ключ = относительный путь папки, значение = {'kb': ..., 'count': ..., 'lines': ...}
    file_stats = []    # список статистики по отдельным файлам

    for dirpath, dirnames, filenames in os.walk(root):
        if should_skip_dir(dirpath):
            continue  # пропускаем папки, которые не нужны
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
                    # используем readlines для подсчёта количества строк
                    lines = file.readlines()
                    num_lines = len(lines)
            except Exception as e:
                pass

            total_kb += kb
            total_lines += num_lines
            count_files += 1

            # Для списка файлов — возьмем имя файла, размер и кол-во строк, а также последнее имя папки
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