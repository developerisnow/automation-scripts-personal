#!/usr/bin/env python3
"""
Enhanced TaskMaster Symlinks Manager

Creates and manages symlinks from TaskMaster task files to centralized Obsidian vault.
Uses informative naming: task012-Implement-AI-System_project-name__done.md

Features:
- Informative symlink names with title and status
- Auto-update mode with 5-minute intervals
- Smart change detection to avoid unnecessary updates
- Cross-platform daemon support

Usage: 
  python taskmaster_symlinks_enhanced.py <project_path>                    # One-time sync
  python taskmaster_symlinks_enhanced.py --watch [projects.txt]           # Auto-update mode
  python taskmaster_symlinks_enhanced.py --daemon [projects.txt]          # Background daemon
  
Examples:
  python taskmaster_symlinks_enhanced.py /Users/user/__Repositories/HypeTrain/repositories/hypetrain-garden
  python taskmaster_symlinks_enhanced.py --watch ~/taskmaster_projects.txt
  python taskmaster_symlinks_enhanced.py --daemon
"""

import os
import sys
import argparse
import time
import hashlib
import json
import signal
import subprocess
from pathlib import Path
import re
from datetime import datetime
from typing import List, Dict, Optional, Tuple


class TaskInfo:
    def __init__(self, task_id: str, title: str, status: str, file_path: Path):
        self.task_id = task_id
        self.title = title  
        self.status = status
        self.file_path = file_path
        self.original_filename = file_path.name
    
    def __str__(self):
        return f"Task {self.task_id}: {self.title} [{self.status}]"


class EnhancedTaskMasterSymlinkManager:
    def __init__(self, obsidian_base_path="/Users/user/____Sandruk/___PKM/_Outputs_AI/taskmaster-s"):
        self.obsidian_base_path = Path(obsidian_base_path)
        self.obsidian_base_path.mkdir(parents=True, exist_ok=True)
        
        # Cache for change detection
        self.cache_file = self.obsidian_base_path / ".symlink_cache.json"
        self.file_hashes = self.load_cache()
        
        # Control flags for daemon mode
        self.running = True
        self.setup_signal_handlers()
    
    def setup_signal_handlers(self):
        """Setup signal handlers for graceful daemon shutdown"""
        def signal_handler(signum, frame):
            print(f"\n🛑 Received signal {signum}, shutting down gracefully...")
            self.running = False
        
        signal.signal(signal.SIGINT, signal_handler)
        signal.signal(signal.SIGTERM, signal_handler)
    
    def load_cache(self) -> Dict[str, str]:
        """Load file hash cache for change detection"""
        try:
            if self.cache_file.exists():
                with open(self.cache_file, 'r') as f:
                    return json.load(f)
        except Exception as e:
            print(f"⚠️  Could not load cache: {e}")
        return {}
    
    def save_cache(self):
        """Save file hash cache"""
        try:
            with open(self.cache_file, 'w') as f:
                json.dump(self.file_hashes, f, indent=2)
        except Exception as e:
            print(f"⚠️  Could not save cache: {e}")
    
    def get_file_hash(self, file_path: Path) -> str:
        """Calculate file hash for change detection"""
        try:
            with open(file_path, 'rb') as f:
                return hashlib.md5(f.read()).hexdigest()
        except Exception:
            return ""
    
    def parse_task_info(self, task_file: Path) -> Optional[TaskInfo]:
        """Parse task file to extract ID, title, and status"""
        try:
            with open(task_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Extract task info using regex
            task_id_match = re.search(r'^# Task ID:\s*(\d+)', content, re.MULTILINE)
            title_match = re.search(r'^# Title:\s*(.+)', content, re.MULTILINE)  
            status_match = re.search(r'^# Status:\s*([a-zA-Z-]+)', content, re.MULTILINE)
            
            if not all([task_id_match, title_match, status_match]):
                print(f"⚠️  Could not parse task info from {task_file.name}")
                return None
            
            task_id = task_id_match.group(1).zfill(3)  # Pad with zeros: 012
            title = title_match.group(1).strip()
            status = status_match.group(1).strip()
            
            return TaskInfo(task_id, title, status, task_file)
            
        except Exception as e:
            print(f"❌ Error parsing {task_file.name}: {e}")
            return None
    
    def clean_title_for_filename(self, title: str) -> str:
        """Clean title to be filesystem-safe"""
        # Remove/replace problematic characters
        cleaned = re.sub(r'[^\w\s-]', '', title)
        # Replace spaces with dashes and collapse multiple dashes
        cleaned = re.sub(r'\s+', '-', cleaned)
        cleaned = re.sub(r'-+', '-', cleaned)
        # Limit length to avoid filesystem issues  
        if len(cleaned) > 40:
            cleaned = cleaned[:40].rstrip('-')
        return cleaned
    
    def create_informative_symlink_name(self, task_info: TaskInfo, project_name: str) -> str:
        """
        Create informative symlink name: task012-Implement-AI-System_project-name__done.md
        """
        clean_title = self.clean_title_for_filename(task_info.title)
        clean_project = re.sub(r'[^a-zA-Z0-9-]', '-', project_name.lower())
        clean_project = re.sub(r'-+', '-', clean_project).strip('-')
        
        symlink_name = f"task{task_info.task_id}-{clean_title}_{clean_project}__{task_info.status}.md"
        return symlink_name
    
    def get_project_name(self, project_path: Path) -> str:
        """Extract project name from path"""
        return project_path.name
    
    def get_task_files(self, project_path: Path) -> List[Path]:
        """Find all task files in .taskmaster/tasks directory"""
        taskmaster_tasks_path = project_path / ".taskmaster" / "tasks"
        
        if not taskmaster_tasks_path.exists():
            return []
        
        return list(taskmaster_tasks_path.glob("*.txt"))
    
    def has_project_changed(self, project_path: Path) -> bool:
        """Check if any task files in project have changed"""
        task_files = self.get_task_files(project_path)
        
        for task_file in task_files:
            file_key = str(task_file)
            current_hash = self.get_file_hash(task_file)
            
            if file_key not in self.file_hashes or self.file_hashes[file_key] != current_hash:
                return True
        
        return False
    
    def update_project_hashes(self, project_path: Path):
        """Update cached hashes for project files"""
        task_files = self.get_task_files(project_path)
        
        for task_file in task_files:
            file_key = str(task_file)
            self.file_hashes[file_key] = self.get_file_hash(task_file)
    
    def process_project(self, project_path: Path, force: bool = False) -> bool:
        """Process a single project"""
        project_path = Path(project_path).resolve()
        
        if not project_path.exists():
            print(f"❌ Project path does not exist: {project_path}")
            return False
        
        # Check for changes unless forced
        if not force and not self.has_project_changed(project_path):
            return True  # No changes, but not an error
        
        print(f"🚀 Processing project: {project_path.name}")
        
        project_name = self.get_project_name(project_path)
        task_files = self.get_task_files(project_path)
        
        if not task_files:
            return True  # No tasks, but not an error
        
        # Create project directory
        project_dir = self.obsidian_base_path / project_name
        project_dir.mkdir(parents=True, exist_ok=True)
        
        # Remove existing symlinks for this project to handle renames/deletions
        for existing_symlink in project_dir.glob("*.md"):
            if existing_symlink.is_symlink():
                existing_symlink.unlink()
        
        # Create new symlinks
        success_count = 0
        for task_file in task_files:
            task_info = self.parse_task_info(task_file)
            if not task_info:
                continue
            
            symlink_name = self.create_informative_symlink_name(task_info, project_name)
            target_file = project_dir / symlink_name
            
            try:
                target_file.symlink_to(task_file.resolve())
                print(f"✅ {task_file.name} -> {symlink_name}")
                success_count += 1
            except Exception as e:
                print(f"❌ Failed to create symlink for {task_file.name}: {e}")
        
        # Update cache
        self.update_project_hashes(project_path)
        
        print(f"📊 {project_name}: {success_count}/{len(task_files)} symlinks created")
        return success_count > 0
    
    def load_projects_list(self, projects_file: Optional[Path] = None) -> List[Path]:
        """Load list of projects to monitor"""
        projects = []
        
        if projects_file and projects_file.exists():
            try:
                with open(projects_file, 'r') as f:
                    for line in f:
                        line = line.strip()
                        if line and not line.startswith('#'):
                            projects.append(Path(line))
            except Exception as e:
                print(f"❌ Error reading projects file: {e}")
        
        return projects
    
    def auto_discover_projects(self) -> List[Path]:
        """Auto-discover TaskMaster projects"""
        common_roots = [
            Path.home() / "__Repositories",
            Path.home() / "Repositories", 
            Path.home() / "Projects",
            Path("/Users/user/__Repositories")
        ]
        
        projects = []
        for root in common_roots:
            if root.exists():
                for item in root.rglob(".taskmaster"):
                    if item.is_dir() and (item / "tasks").exists():
                        projects.append(item.parent)
        
        return list(set(projects))  # Remove duplicates
    
    def watch_mode(self, projects_file: Optional[Path] = None):
        """Continuous monitoring mode with 5-minute intervals"""
        print("🔄 Starting TaskMaster symlinks watcher (5-minute intervals)")
        print("Press Ctrl+C to stop")
        
        # Load projects list
        if projects_file:
            projects = self.load_projects_list(projects_file)
            print(f"📁 Monitoring {len(projects)} projects from {projects_file}")
        else:
            projects = self.auto_discover_projects()
            print(f"📁 Auto-discovered {len(projects)} projects")
        
        if not projects:
            print("❌ No projects found to monitor")
            return
        
        iteration = 0
        while self.running:
            iteration += 1
            timestamp = datetime.now().strftime("%H:%M:%S")
            print(f"\n⏰ [{timestamp}] Scan #{iteration}")
            
            changes_detected = False
            for project_path in projects:
                try:
                    if self.has_project_changed(project_path):
                        print(f"📝 Changes detected in {project_path.name}")
                        self.process_project(project_path)
                        changes_detected = True
                except Exception as e:
                    print(f"❌ Error processing {project_path}: {e}")
            
            if changes_detected:
                self.save_cache()
                print("💾 Cache updated")
            else:
                print("✨ No changes detected")
            
            # Wait for 5 minutes (300 seconds)
            for i in range(300):
                if not self.running:
                    break
                time.sleep(1)
        
        print("\n🛑 Watcher stopped")
    
    def create_launchd_plist(self, projects_file: Optional[Path] = None) -> Path:
        """Create macOS launchd plist for daemon mode"""
        script_path = Path(__file__).resolve()
        plist_path = Path.home() / "Library/LaunchAgents/com.taskmaster.symlinks.plist"
        
        cmd_args = [sys.executable, str(script_path), "--watch"]
        if projects_file:
            cmd_args.append(str(projects_file))
        
        plist_content = f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.taskmaster.symlinks</string>
    <key>ProgramArguments</key>
    <array>
        {''.join(f'<string>{arg}</string>' for arg in cmd_args)}
    </array>
    <key>StartInterval</key>
    <integer>300</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>"""
        
        plist_path.parent.mkdir(parents=True, exist_ok=True)
        with open(plist_path, 'w') as f:
            f.write(plist_content)
        
        return plist_path


def main():
    parser = argparse.ArgumentParser(
        description="Enhanced TaskMaster symlinks manager with auto-update",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # One-time sync
  python taskmaster_symlinks_enhanced.py /path/to/project
  
  # Watch mode (5-minute intervals)
  python taskmaster_symlinks_enhanced.py --watch
  python taskmaster_symlinks_enhanced.py --watch ~/projects.txt
  
  # Install as macOS daemon
  python taskmaster_symlinks_enhanced.py --install-daemon
  
  # Control daemon
  python taskmaster_symlinks_enhanced.py --start-daemon
  python taskmaster_symlinks_enhanced.py --stop-daemon
        """
    )
    
    parser.add_argument(
        "project_path",
        nargs="?",
        help="Path to project with .taskmaster/tasks directory"
    )
    
    parser.add_argument(
        "--watch",
        nargs="?",
        const=True,
        help="Watch mode with optional projects file"
    )
    
    parser.add_argument(
        "--install-daemon",
        action="store_true",
        help="Install as macOS launchd daemon"
    )
    
    parser.add_argument(
        "--start-daemon",
        action="store_true",
        help="Start the daemon"
    )
    
    parser.add_argument(
        "--stop-daemon", 
        action="store_true",
        help="Stop the daemon"
    )
    
    parser.add_argument(
        "--force",
        action="store_true",
        help="Force update even if no changes detected"
    )
    
    args = parser.parse_args()
    
    manager = EnhancedTaskMasterSymlinkManager()
    
    if args.install_daemon:
        projects_file = Path(args.watch) if isinstance(args.watch, str) else None
        plist_path = manager.create_launchd_plist(projects_file)
        print(f"✅ Daemon plist created: {plist_path}")
        print("Run with --start-daemon to activate")
        
    elif args.start_daemon:
        result = subprocess.run(["launchctl", "load", str(Path.home() / "Library/LaunchAgents/com.taskmaster.symlinks.plist")])
        if result.returncode == 0:
            print("✅ Daemon started")
        else:
            print("❌ Failed to start daemon")
            
    elif args.stop_daemon:
        result = subprocess.run(["launchctl", "unload", str(Path.home() / "Library/LaunchAgents/com.taskmaster.symlinks.plist")])
        if result.returncode == 0:
            print("✅ Daemon stopped")
        else:
            print("❌ Failed to stop daemon")
            
    elif args.watch:
        projects_file = Path(args.watch) if isinstance(args.watch, str) else None
        manager.watch_mode(projects_file)
        
    elif args.project_path:
        success = manager.process_project(Path(args.project_path), args.force)
        manager.save_cache()
        if not success:
            sys.exit(1)
    else:
        parser.print_help()


if __name__ == "__main__":
    main() 