#!/usr/bin/env python3

import yaml
import os
import argparse
from pathlib import Path

def create_folder_structure(data, base_path):
    """Recursively create folder structure from YAML data"""
    if not isinstance(data, dict):
        return
    
    # Process folders list
    folders = data.get('folders', [])
    for folder in folders:
        # Get folder name and path
        name = folder.get('name')
        if not name:
            continue
            
        # Create folder
        folder_path = Path(base_path) / name
        try:
            folder_path.mkdir(parents=True, exist_ok=True)
            print(f"Created: {folder_path}")
        except Exception as e:
            print(f"Error creating {folder_path}: {e}")
        
        # Process children recursively
        children = folder.get('children', [])
        if children:
            create_folder_structure({'folders': children}, folder_path)

def main():
    parser = argparse.ArgumentParser(description='Create folder structure from YAML file')
    parser.add_argument('--yaml', type=str, required=True, help='Path to YAML file')
    parser.add_argument('--path', type=str, default=os.getcwd(), 
                       help='Base path for creating folders (default: current directory)')
    
    args = parser.parse_args()
    
    # Validate YAML file exists
    yaml_path = Path(args.yaml)
    if not yaml_path.exists():
        print(f"Error: YAML file not found: {args.yaml}")
        return
    
    # Validate and create base path if needed
    base_path = Path(args.path)
    try:
        base_path.mkdir(parents=True, exist_ok=True)
    except Exception as e:
        print(f"Error creating base path {base_path}: {e}")
        return
    
    # Read YAML file
    try:
        with open(yaml_path, 'r', encoding='utf-8') as f:
            data = yaml.safe_load(f)
    except Exception as e:
        print(f"Error reading YAML file: {e}")
        return
    
    # Create folder structure
    create_folder_structure(data, base_path)
    print(f"\nFolder structure created successfully in: {base_path}")

if __name__ == "__main__":
    main()