#!/usr/bin/env python3
import os
import subprocess
from datetime import datetime
import sys
import logging

def run_git_commands(repo_path):
    """Run git commands in specified repository and return output"""
    commands = [
        ['git', 'pull'],
        ['git', 'branch', '-a'],
        ['git', 'log', '-2']
    ]
    
    results = []
    for cmd in commands:
        try:
            output = subprocess.check_output(cmd, 
                                          cwd=repo_path,
                                          stderr=subprocess.STDOUT,
                                          universal_newlines=True)
            results.append(f"Command: {' '.join(cmd)}\n{output}")
        except subprocess.CalledProcessError as e:
            results.append(f"Error in {' '.join(cmd)}: {e.output}")
    
    return '\n'.join(results)

def process_directories(base_path):
    """Process all directories containing .git folder"""
    timestamp = datetime.now().strftime('%Y-%m-%d_%H%M')
    log_dir = os.path.expanduser('~/git_logs')
    log_file = f'git_run-{timestamp}.log'
    
    # Create logs directory if it doesn't exist
    os.makedirs(log_dir, exist_ok=True)
    
    # Setup logging
    logging.basicConfig(
        filename=os.path.join(log_dir, log_file),
        level=logging.INFO,
        format='%(asctime)s - %(message)s'
    )

    # Walk only one level deep if no specific path provided
    depth = 1
    for root, dirs, files in os.walk(base_path):
        if os.path.abspath(root) != os.path.abspath(base_path):
            if depth == 0:
                continue
        
        if '.git' in dirs:
            logging.info(f"\n{'='*50}")
            logging.info(f"Processing repository: {root}")
            logging.info(f"{'='*50}\n")
            
            output = run_git_commands(root)
            logging.info(output)
        
        depth -= 1

def main():
    if len(sys.argv) > 1:
        base_path = os.path.abspath(sys.argv[1])
    else:
        base_path = os.getcwd()
    
    if not os.path.exists(base_path):
        print(f"Error: Path {base_path} does not exist")
        sys.exit(1)
    
    process_directories(base_path)
    print(f"Git operations completed. Check logs in ~/git_logs/")

if __name__ == "__main__":
    main()