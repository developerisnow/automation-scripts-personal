#!/usr/bin/env python3
import os
import sys
import argparse
import re

def normalize_keyword(keyword):
    """Normalize keyword to handle singular/plural forms"""
    keyword = keyword.lower()
    if keyword.endswith('s'):
        return [keyword[:-1], keyword]
    return [keyword, keyword + 's']

def contains_keyword(name, keyword_forms):
    """Check if name contains any form of the keyword"""
    name_lower = name.lower()
    # Check direct matches with common separators
    pattern = r'[_-]?(' + '|'.join(keyword_forms) + r')[_-]?'
    if re.search(pattern, name_lower):
        return True
    # Check camelCase matches
    camel_pattern = '|'.join(keyword_forms)
    if re.search(camel_pattern, name_lower):
        return True
    return False

def clean_name(dirname, keyword_forms):
    """Remove keyword and normalize separators"""
    # Convert camelCase to space-separated
    name = re.sub(r'([a-z])([A-Z])', r'\1 \2', dirname)
    
    # Replace separators with spaces
    name = re.sub(r'[_-]', ' ', name)
    
    # Remove keyword forms
    for form in keyword_forms:
        name = re.sub(r'\b' + form + r'\b', '', name, flags=re.IGNORECASE)
    
    # Split, clean and filter parts
    parts = [p.strip() for p in name.split()]
    parts = [p for p in parts if p and not any(
        form.lower() == p.lower() for form in keyword_forms
    )]
    
    # Join with hyphens
    return '-'.join(parts)

def rename_folders(mode, keyword):
    if not keyword:
        print("Error: Keyword is required")
        return

    keyword_forms = normalize_keyword(keyword)
    print(f"Looking for keywords: {keyword_forms}")  # Debug line
    
    for dirname in os.listdir('.'):
        if not os.path.isdir(dirname):
            continue

        print(f"\nProcessing: {dirname}")  # Debug line
        
        # Skip if already in correct format
        if mode == 'prefix' and dirname.lower().startswith(f"{keyword.lower()}-"):
            print(f"Skipping {dirname}: already has correct prefix")
            continue
        if mode == 'suffix' and dirname.lower().endswith(f"-{keyword.lower()}"):
            print(f"Skipping {dirname}: already has correct suffix")
            continue

        has_keyword = contains_keyword(dirname, keyword_forms)
        print(f"Contains keyword: {has_keyword}")  # Debug line

        # Clean the name
        clean_dirname = clean_name(dirname, keyword_forms)
        if clean_dirname:
            new_name = (f"{keyword}-{clean_dirname}" if mode == 'prefix' 
                       else f"{clean_dirname}-{keyword}")
            if new_name != dirname:
                try:
                    os.rename(dirname, new_name)
                    print(f"Renamed: {dirname} → {new_name}")
                except OSError as e:
                    print(f"Error renaming {dirname}: {e}")
        else:
            print(f"Skipping {dirname}: would result in empty name")

def main():
    parser = argparse.ArgumentParser(description='Rename folders with prefix or suffix')
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--prefix', help='Prefix to add to folder names')
    group.add_argument('--suffix', help='Suffix to add to folder names')
    
    args = parser.parse_args()
    
    if args.prefix:
        rename_folders('prefix', args.prefix)
    elif args.suffix:
        rename_folders('suffix', args.suffix)

if __name__ == "__main__":
    main()