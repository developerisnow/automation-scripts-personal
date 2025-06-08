#!/usr/bin/env python3
"""
TaskMaster Symlinks Manager

Creates and manages symlinks from TaskMaster task files to centralized Obsidian vault.
Converts .txt files to .md symlinks with unique naming pattern.

Usage: python taskmaster_symlinks.py <project_path>
Example: python taskmaster_symlinks.py /Users/user/__Repositories/HypeTrain/repositories/hypetrain-garden
"""

import os
import sys
import argparse
from pathlib import Path
import re


class TaskMasterSymlinkManager:
    def __init__(self, obsidian_base_path="/Users/user/____Sandruk/___PKM/_Outputs_AI/taskmaster-s"):
        self.obsidian_base_path = Path(obsidian_base_path)
        self.obsidian_base_path.mkdir(parents=True, exist_ok=True)
    
    def get_project_name(self, project_path):
        """Extract project name from the project path (root folder name)"""
        return Path(project_path).name
    
    def get_task_files(self, project_path):
        """Find all task files in the .taskmaster/tasks directory"""
        taskmaster_tasks_path = Path(project_path) / ".taskmaster" / "tasks"
        
        if not taskmaster_tasks_path.exists():
            print(f"❌ TaskMaster tasks directory not found: {taskmaster_tasks_path}")
            return []
        
        task_files = list(taskmaster_tasks_path.glob("*.txt"))
        print(f"📁 Found {len(task_files)} task files in {taskmaster_tasks_path}")
        return task_files
    
    def create_symlink_name(self, task_file, project_name):
        """
        Create unique symlink name: {task_title}_{project_name}.md
        Example: task_056.txt -> task056_hypetrain-project.md
        """
        task_title = task_file.stem  # Get filename without extension
        # Remove underscores and make it cleaner for the title part
        clean_task_title = re.sub(r'_', '', task_title)
        # Clean project name (lowercase, replace spaces/special chars with dashes)
        clean_project_name = re.sub(r'[^a-zA-Z0-9-]', '-', project_name.lower())
        clean_project_name = re.sub(r'-+', '-', clean_project_name).strip('-')
        
        symlink_name = f"{clean_task_title}_{clean_project_name}.md"
        return symlink_name
    
    def create_project_directory(self, project_name):
        """Create project directory in Obsidian vault"""
        project_dir = self.obsidian_base_path / project_name
        project_dir.mkdir(parents=True, exist_ok=True)
        return project_dir
    
    def create_symlink(self, source_file, target_file):
        """Create symlink from source to target"""
        try:
            # Remove existing symlink if it exists
            if target_file.is_symlink() or target_file.exists():
                target_file.unlink()
                print(f"🔄 Removed existing file: {target_file.name}")
            
            # Create the symlink
            target_file.symlink_to(source_file.resolve())
            print(f"✅ Created symlink: {source_file.name} -> {target_file.name}")
            return True
            
        except Exception as e:
            print(f"❌ Failed to create symlink for {source_file.name}: {str(e)}")
            return False
    
    def verify_symlink(self, symlink_path):
        """Verify that symlink is working correctly"""
        try:
            if symlink_path.is_symlink():
                target = symlink_path.readlink()
                if target.exists():
                    print(f"✓ Symlink verified: {symlink_path.name} -> {target}")
                    return True
                else:
                    print(f"⚠️  Symlink broken: {symlink_path.name} -> {target} (target not found)")
                    return False
            else:
                print(f"❌ Not a symlink: {symlink_path.name}")
                return False
        except Exception as e:
            print(f"❌ Error verifying symlink {symlink_path.name}: {str(e)}")
            return False
    
    def process_project(self, project_path):
        """Main processing function for a project"""
        project_path = Path(project_path).resolve()
        
        if not project_path.exists():
            print(f"❌ Project path does not exist: {project_path}")
            return False
        
        print(f"🚀 Processing project: {project_path}")
        
        # Get project name and task files
        project_name = self.get_project_name(project_path)
        task_files = self.get_task_files(project_path)
        
        if not task_files:
            print("❌ No task files found")
            return False
        
        # Create project directory in Obsidian vault
        project_dir = self.create_project_directory(project_name)
        print(f"📂 Project directory: {project_dir}")
        
        # Process each task file
        success_count = 0
        for task_file in task_files:
            symlink_name = self.create_symlink_name(task_file, project_name)
            target_file = project_dir / symlink_name
            
            if self.create_symlink(task_file, target_file):
                if self.verify_symlink(target_file):
                    success_count += 1
        
        print(f"\n📊 Summary:")
        print(f"   Total task files: {len(task_files)}")
        print(f"   Successful symlinks: {success_count}")
        print(f"   Target directory: {project_dir}")
        
        return success_count > 0
    
    def cleanup_broken_symlinks(self, project_name=None):
        """Remove broken symlinks from the Obsidian vault"""
        if project_name:
            search_dirs = [self.obsidian_base_path / project_name]
        else:
            search_dirs = [d for d in self.obsidian_base_path.iterdir() if d.is_dir()]
        
        removed_count = 0
        for project_dir in search_dirs:
            if not project_dir.exists():
                continue
                
            for symlink_file in project_dir.glob("*.md"):
                if symlink_file.is_symlink():
                    try:
                        # Check if target exists
                        if not symlink_file.readlink().exists():
                            symlink_file.unlink()
                            print(f"🗑️  Removed broken symlink: {symlink_file}")
                            removed_count += 1
                    except Exception as e:
                        print(f"❌ Error checking symlink {symlink_file}: {str(e)}")
        
        print(f"🧹 Cleanup complete: {removed_count} broken symlinks removed")


def main():
    parser = argparse.ArgumentParser(
        description="Create symlinks from TaskMaster task files to Obsidian vault",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python taskmaster_symlinks.py /Users/user/__Repositories/HypeTrain/repositories/hypetrain-garden
  python taskmaster_symlinks.py --cleanup
  python taskmaster_symlinks.py --cleanup --project hypetrain-garden
        """
    )
    
    parser.add_argument(
        "project_path",
        nargs="?",
        help="Path to the project containing .taskmaster/tasks directory"
    )
    
    parser.add_argument(
        "--cleanup",
        action="store_true",
        help="Remove broken symlinks"
    )
    
    parser.add_argument(
        "--project",
        help="Specific project name for cleanup (optional)"
    )
    
    args = parser.parse_args()
    
    manager = TaskMasterSymlinkManager()
    
    if args.cleanup:
        manager.cleanup_broken_symlinks(args.project)
    elif args.project_path:
        success = manager.process_project(args.project_path)
        if not success:
            sys.exit(1)
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
