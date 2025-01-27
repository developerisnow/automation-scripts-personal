import subprocess
import os
import sys
import argparse
from collections import defaultdict
from datetime import datetime

def validate_git_repo():
    if not os.path.exists('.git'):
        print("Error: Not a git repository")
        sys.exit(1)

def run_git_command(command):
    try:
        result = subprocess.run(command, shell=True, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"Error executing command: {command}")
            print(f"Error: {result.stderr}")
            sys.exit(1)
        return result.stdout.strip()
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

def should_exclude_file(filepath, excluded_extensions, excluded_folders, exclude_hidden):
    # Check for hidden files
    if exclude_hidden and os.path.basename(filepath).startswith('.'):
        return True
        
    # Check file extension
    if excluded_extensions:
        file_ext = os.path.splitext(filepath)[1].lower().lstrip('.')
        if file_ext in excluded_extensions:
            return True
            
    # Check folders recursively
    if excluded_folders:
        path_parts = filepath.split('/')
        for part in path_parts:
            if part in excluded_folders:
                return True
                
    return False

def get_file_changes(commit1, commit2, types_changes='AMRCD', excluded_extensions=None, 
                    excluded_folders=None, exclude_hidden=False):
    cmd = f'git diff --name-status --diff-filter={types_changes} {commit1}..{commit2}'
    output = run_git_command(cmd)
    
    changes = defaultdict(list)
    excluded_extensions = set(ext.strip().lower() for ext in (excluded_extensions or []))
    excluded_folders = set(folder.strip() for folder in (excluded_folders or []))
    
    for line in output.splitlines():
        if not line.strip():
            continue
        status, filepath = line.split(maxsplit=1)
        
        if should_exclude_file(filepath, excluded_extensions, excluded_folders, exclude_hidden):
            continue
                
        changes[status].append(filepath)
    
    return changes

def get_commit_count(commit1, commit2):
    return run_git_command(f'git rev-list --count {commit1}..{commit2}')

def generate_report(commit1, commit2, types_changes, excluded_extensions, 
                   excluded_folders, exclude_hidden):
    changes = get_file_changes(commit1, commit2, types_changes, excluded_extensions,
                             excluded_folders, exclude_hidden)
    commit_count = get_commit_count(commit1, commit2)
    commit_log = run_git_command(f'git log --oneline {commit1}..{commit2}')

    cmd_explanation = """
## Command Line Options Used
- `--typeschanges={types_changes}`: Filter changes by type (A=Added, M=Modified, R=Renamed, C=Copied, D=Deleted)
{exclusion_text}
{folders_text}
{hidden_text}
""".format(
        types_changes=types_changes,
        exclusion_text=f"- `--typesexclude={','.join(excluded_extensions)}`: Ignore files with these extensions" if excluded_extensions else "",
        folders_text=f"- `--foldersexclude={','.join(excluded_folders)}`: Ignore files in these folders" if excluded_folders else "",
        hidden_text="- `--exclude-hidden`: Ignore hidden files (starting with '.')" if exclude_hidden else ""
    )

    report = f"""# Git Changes Analysis Report
Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## Analysis Summary
- From commit: `{commit1}`
- To commit: `{commit2}`
- Total commits: {commit_count}
- Total files changed: {sum(len(files) for files in changes.values())}

{cmd_explanation}

## Commands Used
```bash
git diff --name-status --diff-filter={types_changes} {commit1}..{commit2}
git log --oneline {commit1}..{commit2}
```

## Changes by Type\n"""

    status_map = {
        'M': ('Modified', '\033[33m'),
        'A': ('Added', '\033[32m'),
        'D': ('Deleted', '\033[31m'),
        'R': ('Renamed', '\033[36m'),
        'C': ('Copied', '\033[35m')
    }

    for status, files in sorted(changes.items()):
        if files:
            desc, color = status_map.get(status, (status, ''))
            report += f"\n### {desc} Files ({len(files)})\n"
            for file in sorted(files):
                report += f"- {file}\n"

    report += "\n## Commit History\n```\n"
    report += commit_log
    report += "\n```"

    return report

def get_commit_range(args):
    """Get commit range based on input type: branches, commits, or last N commits"""
    if args.branches:
        branch1, branch2 = args.branches.split(',')
        # Get the common ancestor of two branches
        merge_base = run_git_command(f'git merge-base {branch1} {branch2}')
        return merge_base, run_git_command(f'git rev-parse {branch2}')
        
    if args.lastcommits:
        head = run_git_command('git rev-parse HEAD')
        old_commit = run_git_command(f'git rev-parse HEAD~{args.lastcommits}')
        return old_commit, head
        
    return args.commits

def get_current_branch():
    return run_git_command('git rev-parse --abbrev-ref HEAD')

def get_short_hash(commit_hash):
    """Convert full commit hash to short version (first 7 chars)"""
    return commit_hash[:7] if len(commit_hash) > 7 else commit_hash

def get_output_filename(commit1, commit2):
    """Generate filename with timestamp and short commit hashes"""
    timestamp = datetime.now().strftime('%Y-%m-%d-%H%M')
    short_commit1 = get_short_hash(commit1)
    short_commit2 = get_short_hash(commit2)
    return f"git-commits-analysis-{short_commit1}-{short_commit2}-{timestamp}.md"

if __name__ == "__main__":
    validate_git_repo()
    
    parser = argparse.ArgumentParser(description='Analyze git repository changes between commits.')
    
    # Create mutually exclusive group for different analysis modes
    mode_group = parser.add_mutually_exclusive_group(required=True)
    mode_group.add_argument('--branches', 
                          help='Compare two branches (format: branch1,branch2)')
    mode_group.add_argument('--lastcommits', type=int,
                          help='Analyze last N commits')
    mode_group.add_argument('commits', nargs='*',
                          help='Two commit hashes to compare', default=[])
    
    # Add filtering options
    parser.add_argument('--typesexclude', default='', 
                       help='Comma-separated list of file extensions to exclude (e.g., "md,csv,log,json,yaml")')
    parser.add_argument('--typeschanges', default='AMRCD', 
                       help='Git diff filter types (default: AMRCD)')
    parser.add_argument('--foldersexclude', default='',
                       help='Comma-separated list of folders to exclude (e.g., "logs,test")')
    parser.add_argument('--exclude-hidden', action='store_true',
                       help='Exclude hidden files (starting with ".")')
    
    args = parser.parse_args()
    
    # Get commit range based on input mode
    if args.branches:
        commit1, commit2 = get_commit_range(args)
    elif args.lastcommits:
        commit1, commit2 = get_commit_range(args)
    else:
        if len(args.commits) != 2:
            parser.error("Please provide either --branches, --lastcommits N, or two commit hashes")
        commit1, commit2 = args.commits
    
    excluded_extensions = [ext.strip() for ext in args.typesexclude.split(',')] if args.typesexclude else None
    excluded_folders = [folder.strip() for folder in args.foldersexclude.split(',')] if args.foldersexclude else None
    
    report = generate_report(commit1, commit2, args.typeschanges, 
                           excluded_extensions, excluded_folders, args.exclude_hidden)
    
    output_dir = "docs/meta"
    output_file = f"{output_dir}/{get_output_filename(commit1, commit2)}"
    
    os.makedirs(output_dir, exist_ok=True)
    with open(output_file, 'w') as f:
        f.write(report)
    
    print(f"Report generated successfully at: {output_file}")