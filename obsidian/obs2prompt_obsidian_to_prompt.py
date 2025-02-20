import os
import re
import subprocess
from typing import Set, Dict, Optional, List, Tuple

class ObsidianLinkCollector:
    def __init__(self, vault_path: str = None, max_depth: int = 1, debug: bool = False):
        """Initialize the collector with vault path and options."""
        if vault_path is None:
            # Default to ./references/obsidian
            vault_path = os.path.join(os.getcwd(), 'references', 'obsidian')
            os.makedirs(vault_path, exist_ok=True)
            
        self.vault_path = os.path.abspath(vault_path)
        self.max_depth = max_depth
        self.debug_enabled = debug
        self.visited_files = set()
        self.collected_files: List[Tuple[str, str]] = []  # [(file_path, content)]
        self.start_file = None  # Store start file name
        # Match both [[link]] and [[@link]] patterns
        self.link_pattern = re.compile(r'\[\[([^\]|]+)(?:\|[^\]]+)?\]\]')
        
    def _debug(self, msg: str):
        if self.debug_enabled:
            print(f"DEBUG: {msg}")

    def collect_links(self, start_file: str) -> str:
        """Main entry point to collect content from a starting file."""
        self.start_file = start_file  # Store start file name
        self._process_file(start_file, current_depth=0)
        return self._generate_output()
    
    def _process_file(self, filename: str, current_depth: int) -> None:
        """Process a single file and its links recursively."""
        self._debug(f"Processing file: {filename} at depth {current_depth}")
        
        if current_depth > self.max_depth:
            self._debug(f"Max depth reached for {filename}")
            return
            
        # Don't strip prefixes from the original filename
        norm_filename = self._normalize_filename(filename)
        if not norm_filename:
            self._debug(f"Could not normalize filename: {filename}")
            return
            
        file_path = os.path.join(self.vault_path, norm_filename)
        self._debug(f"Full file path: {file_path}")
        
        if file_path in self.visited_files:
            self._debug(f"Already visited: {file_path}")
            return
            
        if not os.path.exists(file_path):
            self._debug(f"File does not exist: {file_path}")
            return
            
        self.visited_files.add(file_path)
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                self._debug(f"Successfully read file: {file_path}")
                self.collected_files.append((file_path, content))
            
            links = self.link_pattern.findall(content)
            self._debug(f"Found links in {filename}: {links}")
            
            if current_depth < self.max_depth:
                for link in links:
                    clean_link = link.strip('@$ =')  # Handle special prefixes
                    self._process_file(clean_link, current_depth + 1)
                    
        except Exception as e:
            self._debug(f"Error processing {filename}: {str(e)}")
    
    def _format_tree(self, paths: list[str]) -> list[str]:
        """Format paths as a tree structure."""
        if not paths:
            return []
            
        paths.sort()
        result = []
        
        for i, path in enumerate(paths):
            if i == len(paths) - 1:
                prefix = "└── "
            else:
                prefix = "├── "
            result.append(prefix + path)
            
        return result

    def _generate_output(self) -> str:
        """Generate formatted output with statistics and content."""
        if not self.collected_files:
            return "No files processed."

        # Sort files, but ensure start file is first
        start_file_path = os.path.join(self.vault_path, self._normalize_filename(self.start_file))
        self.collected_files.sort(key=lambda x: (x[0] != start_file_path, x[0]))

        # Calculate statistics
        total_lines = sum(len(content.splitlines()) for _, content in self.collected_files)
        total_size = sum(os.path.getsize(path) for path, _ in self.collected_files)
        total_tokens = sum(self._get_token_count(path) for path, _ in self.collected_files)

        # Build output sections
        sections = [
            f"Project Path: {self.vault_path}\n",
            "Source Tree:",
            "```",
            self._generate_tree_structure(),
            "```\n",
            "File Statistics:",
            f"- Total Files: {len(self.collected_files)}",
            f"- Total Lines: {total_lines}",
            f"- Total Size: {self._format_size(total_size)}",
            f"- Total Tokens: {total_tokens}\n",
            "Content:"
        ]

        # Add content section with proper error handling
        for file_path, content in self.collected_files:
            try:
                rel_path = os.path.relpath(file_path, self.vault_path)
                sections.extend([
                    f"`{rel_path}`:",
                    "```md",
                    content.strip(),
                    "```\n"
                ])
            except Exception as e:
                self._debug(f"Error processing content for {file_path}: {str(e)}")

        return "\n".join(sections)

    def _format_size(self, size_bytes: int) -> str:
        """Convert bytes to human readable format."""
        for unit in ['B', 'KB', 'MB', 'GB']:
            if size_bytes < 1024:
                return f"{size_bytes:.1f} {unit}"
            size_bytes /= 1024
        return f"{size_bytes:.1f} TB"

    def _generate_tree_structure(self) -> str:
        """Generate a tree structure of collected files."""
        tree_lines = []
        for file_path, _ in self.collected_files:
            rel_path = os.path.relpath(file_path, self.vault_path)
            tree_lines.append(rel_path)
        
        tree_lines.sort()
        return "\n".join("├── " + line for line in tree_lines[:-1]) + "\n└── " + tree_lines[-1]

    def _get_token_count(self, file_path: str) -> int:
        """Get token count using code2prompt or estimate."""
        try:
            result = subprocess.run(
                ["code2prompt", file_path, "--tokens"],
                capture_output=True,
                text=True,
                timeout=5
            )
            match = re.search(r'Token count: (\d+)', result.stdout)
            if match:
                return int(match.group(1))
        except Exception as e:
            self._debug(f"Token count error for {file_path}: {str(e)}")
        
        # Fallback: rough estimate based on words
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                return len(f.read().split())
        except Exception as e:
            self._debug(f"Fallback token count error for {file_path}: {str(e)}")
            return 0

    def _normalize_filename(self, filename: str) -> Optional[str]:
        """Convert various filename formats to actual file path."""
        filename = filename.strip()
        if not filename:
            return None
            
        # First try direct path match
        for root, _, files in os.walk(self.vault_path):
            for file in files:
                if file == filename or file == filename + '.md':
                    return os.path.relpath(os.path.join(root, file), self.vault_path)

        # Extract the base name (remove prefixes if present)
        base_name = filename
        prefixes = ['$', '@', '=', '$.', '$ ', '$. ']
        for prefix in prefixes:
            if filename.startswith(prefix):
                base_name = filename[len(prefix):].strip()
                break

        # Generate all possible variants
        variants = [
            filename,  # Original as-is
            filename + '.md',
            filename + '🌳.md',
            base_name + '.md',
            base_name + '🌳.md',
            base_name.replace(' ', '_') + '.md',
            base_name.replace(' ', '-') + '.md',
        ]
        
        # Add prefix variants
        for prefix in prefixes:
            variants.extend([
                prefix + base_name + '.md',
                prefix + base_name.replace(' ', '_') + '.md',
                prefix + base_name.replace(' ', '-') + '.md',
            ])
        
        # Remove duplicates while preserving order
        variants = list(dict.fromkeys(variants))
        
        # Search in all subdirectories
        for root, _, files in os.walk(self.vault_path):
            for variant in variants:
                if variant in files:
                    return os.path.relpath(os.path.join(root, variant), self.vault_path)
                    
        self._debug(f"No matching file found for variants: {variants}")
        return None

    def get_statistics(self) -> dict:
        """Get statistics about processed files."""
        total_lines = sum(len(content.splitlines()) for _, content in self.collected_files)
        total_size = sum(os.path.getsize(path) for path, _ in self.collected_files)
        total_tokens = sum(self._get_token_count(path) for path, _ in self.collected_files)
        
        return {
            'files': len(self.collected_files),
            'lines': total_lines,
            'size': self._format_size(total_size),
            'tokens': total_tokens
        }

# Example usage
if __name__ == "__main__":
    import argparse
    from datetime import datetime
    
    parser = argparse.ArgumentParser(description='Collect and process Obsidian links')
    parser.add_argument('start_file', help='Starting file (e.g., "$ Zettelkasten.md")')
    parser.add_argument('--vault', default=os.getcwd(), help='Path to Obsidian vault')
    parser.add_argument('--depth', type=int, default=1, help='Maximum recursion depth')
    parser.add_argument('--output', help='Output file path (default: temp/aggregate_<notes_title>.txt)')
    parser.add_argument('--debug', action='store_true', help='Enable debug logging')
    
    args = parser.parse_args()
    
    # Create default output path if not specified
    if not args.output:
        # Extract base name without extension and special characters
        base_name = os.path.splitext(os.path.basename(args.start_file))[0]
        base_name = re.sub(r'[$@= ]', '', base_name)  # Remove special characters
        os.makedirs('temp', exist_ok=True)
        args.output = f"temp/aggregate_{base_name}.txt"
    
    collector = ObsidianLinkCollector(
        vault_path=args.vault,
        max_depth=args.depth,
        debug=args.debug
    )
    
    result = collector.collect_links(args.start_file)
    
    # Save to file
    with open(args.output, 'w', encoding='utf-8') as f:
        f.write(result)
    
    # Print statistics to bash
    stats = collector.get_statistics()
    print("\nFile Statistics:")
    print(f"- Total Files: {stats['files']}")
    print(f"- Total Lines: {stats['lines']}")
    print(f"- Total Size: {stats['size']}")
    print(f"- Total Tokens: {stats['tokens']}")
    print(f"\nResults saved to: {args.output}")
    
    # Copy content to clipboard
    try:
        import pyperclip
        with open(args.output, 'r', encoding='utf-8') as f:
            content = f.read()
        pyperclip.copy(content)
        print("Content copied to clipboard!")
    except ImportError:
        print("Install 'pyperclip' package to enable clipboard functionality")
    except Exception as e:
        print(f"Failed to copy to clipboard: {str(e)}")