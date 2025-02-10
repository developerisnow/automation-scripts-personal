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
        # Match both [[link]] and [[@link]] patterns
        self.link_pattern = re.compile(r'\[\[([^\]|]+)(?:\|[^\]]+)?\]\]')
        
    def _debug(self, msg: str):
        if self.debug_enabled:
            print(f"DEBUG: {msg}")

    def collect_links(self, start_file: str) -> str:
        """Main entry point to collect content from a starting file."""
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
    
    def _generate_output(self) -> str:
        """Generate formatted output similar to code2prompt style."""
        if not self.collected_files:
            return "No files processed."

        # Calculate statistics first
        total_tokens = 0
        total_lines = 0
        total_size = 0
        total_files = len(self.collected_files)

        # Sort files by path for consistent output
        self.collected_files.sort(key=lambda x: x[0])

        # Generate content section with all files
        content_parts = []
        for file_path, file_content in self.collected_files:
            rel_path = os.path.relpath(file_path, self.vault_path)
            total_lines += len(file_content.splitlines())
            total_size += os.path.getsize(file_path)
            try:
                tokens = self._get_token_count(file_path)
                total_tokens += tokens
            except Exception as e:
                self._debug(f"Error getting token count for {file_path}: {str(e)}")

            content_parts.append(f"`{rel_path}`:\n```md\n{file_content}\n```\n")

        # Format statistics
        stats = [
            "File Statistics:",
            f"- Total Files: {total_files}",
            f"- Total Lines: {total_lines}",
            f"- Total Size: {self._format_size(total_size)}",
            f"- Total Tokens: {total_tokens}"
        ]

        # Generate source tree
        tree = "Source Tree:\n```\n"
        tree += self._generate_tree_structure()
        tree += "\n```"

        # Combine all sections
        result = [
            f"Project Path: {self.vault_path}",
            "",
            tree,
            "",
            "\n".join(stats),  # Add statistics section
            "",
            "Content:",
            "\n".join(content_parts)  # Add all content parts
        ]
        
        return "\n".join(result)

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
        """Get token count using code2prompt."""
        try:
            result = subprocess.run(
                ["code2prompt", file_path, "--tokens"], 
                capture_output=True, 
                text=True
            )
            # Extract token count from output
            match = re.search(r'Token count: (\d+)', result.stdout)
            return int(match.group(1)) if match else 0
        except Exception:
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

# Example usage
if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='Collect and process Obsidian links')
    parser.add_argument('start_file', help='Starting file (e.g., "$ Zettelkasten.md")')
    parser.add_argument('--vault', default=os.getcwd(), help='Path to Obsidian vault')
    parser.add_argument('--depth', type=int, default=2, help='Maximum recursion depth')
    parser.add_argument('--output', help='Output file path')
    parser.add_argument('--debug', action='store_true', help='Enable debug logging')
    
    args = parser.parse_args()
    
    collector = ObsidianLinkCollector(
        vault_path=args.vault,
        max_depth=args.depth,
        debug=args.debug
    )
    
    result = collector.collect_links(args.start_file)
    
    if args.output:
        with open(args.output, 'w', encoding='utf-8') as f:
            f.write(result)
        print(f"Results saved to {args.output}")
    else:
        print(result)
    
    print(f"Processed {len(collector.visited_files)} files.")