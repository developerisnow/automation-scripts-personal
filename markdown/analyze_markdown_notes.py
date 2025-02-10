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
from pathlib import Path
from collections import defaultdict
import pandas as pd

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

def get_file_stats(file_path):
    """Get statistics for a markdown file"""
    try:
        size_kb = os.path.getsize(file_path) / 1024
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = len(f.readlines())
        title = Path(file_path).stem
        return {
            'title': title,
            'size_kb': round(size_kb, 2),
            'lines': lines,
            'path': str(file_path)
        }
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        return None

def analyze_markdown_files(root_dir):
    """Analyze all markdown files in directory structure"""
    folder_stats = defaultdict(lambda: {'size': 0, 'files': 0, 'lines': 0})
    file_stats = []
    
    # Walk through directory
    for dirpath, dirnames, filenames in os.walk(root_dir):
        # Skip git directories
        if '.git' in dirpath:
            continue
            
        md_files = [f for f in filenames if f.endswith('.md')]
        
        for md_file in md_files:
            file_path = os.path.join(dirpath, md_file)
            
            # Skip symlinks
            if os.path.islink(file_path):
                continue
                
            stats = get_file_stats(file_path)
            if stats:
                # Add to file stats
                file_stats.append(stats)
                
                # Add to folder stats
                folder = dirpath
                folder_stats[folder]['size'] += stats['size_kb']
                folder_stats[folder]['files'] += 1
                folder_stats[folder]['lines'] += stats['lines']
    
    return folder_stats, file_stats

def save_folder_report(folder_stats, output_file):
    """Save folder statistics report"""
    with open(output_file, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(['folder', 'kb size md files', 'number of md files', 'number total lines of markdown files'])
        
        for folder, stats in folder_stats.items():
            writer.writerow([
                folder,
                round(stats['size'], 2),
                stats['files'],
                stats['lines']
            ])

def save_files_report(file_stats, output_file, limit=200):
    """Save top files statistics report"""
    # Convert to DataFrame for easier sorting
    df = pd.DataFrame(file_stats)
    
    # Sort by size and get top files
    top_files = df.nlargest(limit, 'size_kb')
    
    # Extract folder name from path
    top_files['folder'] = top_files['path'].apply(lambda x: os.path.basename(os.path.dirname(x)))
    
    # Save report
    top_files[['title', 'size_kb', 'lines', 'folder']].to_csv(
        output_file, 
        index=False
    )

def main():
    root_dir = '/Users/user/____Sandruk'
    
    print("Analyzing markdown files...")
    folder_stats, file_stats = analyze_markdown_files(root_dir)
    
    print("Saving folder report...")
    save_folder_report(folder_stats, 'markdown-notes-by-folders.csv')
    
    print("Saving files report...")
    save_files_report(file_stats, 'md-notes-list-top-200.csv')
    
    # Print summary
    total_files = sum(stats['files'] for stats in folder_stats.values())
    total_size = sum(stats['size'] for stats in folder_stats.values())
    total_lines = sum(stats['lines'] for stats in folder_stats.values())
    
    print("\nSummary:")
    print(f"Total markdown files: {total_files}")
    print(f"Total size: {round(total_size/1024, 2)} MB")
    print(f"Total lines: {total_lines}")

if __name__ == "__main__":
    main() 