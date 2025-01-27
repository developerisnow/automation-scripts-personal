import os
import argparse

def rename_folders(start_path, old_name, new_name):
    """
    Рекурсивно переименовывает указанные папки
    
    Args:
        start_path (str): Начальная директория для поиска
        old_name (str): Текущее имя папки для переименования
        new_name (str): Новое имя папки
    """
    # Собираем все пути для переименования
    folders_to_rename = []
    
    for root, dirs, _ in os.walk(start_path):
        for dir_name in dirs:
            if dir_name == old_name:
                old_path = os.path.join(root, old_name)
                new_path = os.path.join(root, new_name)
                folders_to_rename.append((old_path, new_path))
    
    # Переименовываем папки
    for old_path, new_path in folders_to_rename:
        try:
            os.rename(old_path, new_path)
            print(f"Переименовано: {old_path} -> {new_path}")
        except Exception as e:
            print(f"Ошибка при переименовании {old_path}: {str(e)}")

def main():
    parser = argparse.ArgumentParser(description='Переименование папок')
    parser.add_argument('path', help='Путь к корневой директории')
    parser.add_argument('old_name', help='Текущее имя папки')
    parser.add_argument('new_name', help='Новое имя папки')
    
    args = parser.parse_args()
    
    if not os.path.exists(args.path):
        print(f"Путь не существует: {args.path}")
        return
    
    print(f"Переименование папок в: {args.path}")
    print(f"От {args.old_name} к {args.new_name}")
    
    rename_folders(args.path, args.old_name, args.new_name)
    print("Завершено!")

if __name__ == "__main__":
    main() 