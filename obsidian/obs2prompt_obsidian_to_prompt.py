import os
import re
import subprocess
from typing import Set, Dict, Optional, List, Tuple
from datetime import datetime

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
        # Initialize try_variants as an empty list
        self.try_variants = []
        # Updated pattern to properly handle links with pipe symbol
        self.link_pattern = re.compile(r'\[\[([^|\]]+)(?:\|[^\]]+)?\]\]')
        
    def _debug(self, msg: str):
        if self.debug_enabled:
            print(f"DEBUG: {msg}")

    def collect_links(self, start_file: str) -> str:
        """Start collecting from the specified file."""
        self._debug(f"Processing file: {start_file} at depth 0")
        self.start_file = start_file
        normalized_path = self._normalize_filename(start_file)
        
        if normalized_path is None:
            # Try with MOC prefix explicitly
            if not start_file.startswith("MOC-"):
                self._debug(f"Trying with MOC prefix")
                moc_filename = f"MOC-{start_file}"
                normalized_path = self._normalize_filename(moc_filename)
                
            # If still not found, do an aggressive search
            if normalized_path is None:
                self._debug(f"Trying full recursive search for: {start_file}")
                
                # Try searching with a simple recursive find
                for root, _, files in self._custom_walk(self.vault_path):
                    for file in files:
                        # Check if the base filename is contained in any file
                        base_name = start_file
                        if base_name.endswith('.md'):
                            base_name = base_name[:-3]
                            
                        # Check for partial match
                        if file.endswith('.md') and base_name.lower() in file.lower():
                            normalized_path = os.path.join(root, file)
                            self._debug(f"Found through full search: {normalized_path}")
                            break
                            
                    if normalized_path:
                        break
        
        if normalized_path:
            self._debug(f"Starting from normalized file: {normalized_path}")
            self._process_file(normalized_path, 0)
        else:
            self._debug(f"Could not find any matching file for: {start_file}")
        
        # Generate and return the output
        return self._generate_output()
    
    def _process_file(self, filename: str, current_depth: int) -> None:
        """Process a single file and follow its links."""
        # Check if we've already processed this file
        if filename in self.visited_files:
            return
            
        # Add to visited files
        self.visited_files.add(filename)
        
        # Check if file exists
        if not os.path.exists(filename):
            self._debug(f"File does not exist: {filename}")
            return
            
        # Read the file content
        try:
            with open(filename, 'r', encoding='utf-8') as f:
                content = f.read()
        except Exception as e:
            self._debug(f"Error reading file {filename}: {str(e)}")
            return
            
        # Add to collected files
        self.collected_files.append((filename, content))
        self._debug(f"Collected file: {filename}")
        
        # If we've reached the maximum depth, don't process links
        if current_depth >= self.max_depth:
            return
            
        # Extract links
        links = self.link_pattern.findall(content)
        self._debug(f"Found {len(links)} links in {filename}")
        
        # Process each link
        for link in links:
            # Clean the link (remove any trailing/leading whitespace)
            link = link.strip()
            self._debug(f"Processing link: {link}")
            
            # Normalize the filename
            normalized_path = self._normalize_filename(link)
            if normalized_path:
                self._debug(f"Link normalized to: {normalized_path}")
                self._process_file(normalized_path, current_depth + 1)
            else:
                self._debug(f"Could not normalize link: {link}")
                
                # Try to look for the file in the same directory as the current file
                current_dir = os.path.dirname(filename)
                if current_dir:
                    parent_path = os.path.join(current_dir, f"{link}.md")
                    if os.path.exists(parent_path):
                        self._debug(f"Found link in same directory: {parent_path}")
                        self._process_file(parent_path, current_depth + 1)
    
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
        """Generate the final output text."""
        output_parts = []
        
        # Add a header with information about the source
        if self.start_file:
            output_parts.append(f"# Content from {self.start_file}\n")
            output_parts.append(f"- Generated on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
            output_parts.append(f"- Depth: {self.max_depth}")
            output_parts.append(f"- Files collected: {len(self.collected_files)}\n")
        
        # Add the tree structure when we have more than one file
        if len(self.collected_files) > 1:
            tree_structure = self._generate_tree_structure()
            output_parts.append("## File Structure\n")
            output_parts.append(tree_structure)
            output_parts.append("\n")
        
        # Add each file's content with headers
        output_parts.append("## Content\n")
        
        for file_path, content in self.collected_files:
            # Get the relative path from the vault path
            try:
                relative_path = os.path.relpath(file_path, self.vault_path)
            except ValueError:
                # Handle case when file_path and self.vault_path are on different drives
                relative_path = file_path
                
            # Add a header with the file name
            file_name = os.path.basename(file_path)
            header = f"### {file_name}"
            output_parts.append(header)
            
            # Add the file path
            output_parts.append(f"Path: `{relative_path}`\n")
            
            # Add the content
            output_parts.append(content)
            
            # Add a separator
            output_parts.append("\n---\n")
            
        # Generate and append statistics
        stats = self.get_statistics()
        output_parts.append("## File Statistics\n")
        output_parts.append(f"- Total Files: {stats['file_count']}")
        output_parts.append(f"- Total Lines: {stats['total_lines']}")
        output_parts.append(f"- Total Size: {stats['total_size']}")
        output_parts.append(f"- Total Tokens: {stats['total_tokens']}")
        
        # Join all parts with newlines
        return "\n".join(output_parts)

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
        """Normalize the filename and find the actual path to the file."""
        # If the file already exists, return it
        if os.path.exists(os.path.join(self.vault_path, filename)):
            return os.path.join(self.vault_path, filename)
            
        # If the path includes .md extension, try with and without it
        base_name = filename
        if filename.endswith('.md'):
            base_name = filename[:-3]
        
        # Create a list of possible file variants
        self.try_variants = [base_name, f"{base_name}.md", f"{base_name}🌳.md", 
                      f"${base_name}.md", f"@{base_name}.md", f"={base_name}.md",
                      f"$.{base_name}.md", f"$ {base_name}.md", f"$. {base_name}.md"]
        
        self._debug(f"Trying variants: {self.try_variants}")
        
        for variant in self.try_variants:
            full_path = os.path.join(self.vault_path, variant)
            if os.path.exists(full_path):
                self._debug(f"Found in root directory: {full_path}")
                return full_path
        
        # Perform recursive search through subdirectories if not found
        self._debug(f"File not found in root. Searching subdirectories for: {filename}")
        
        # Try a more flexible search looking for the filename in subdirectories
        for root, dirs, files in self._custom_walk(self.vault_path):
            # Skip directories that start with a dot or underscore 'temp'
            dirs[:] = [d for d in dirs if not d.startswith('.') and not d == 'temp']
            
            # Try all variants in this directory
            for variant in self.try_variants:
                full_path = os.path.join(root, variant)
                if os.path.exists(full_path):
                    self._debug(f"Found file in subdirectory: {full_path}")
                    return full_path
            
            # Also check for MOC- prefix which might be missing from the search
            moc_variants = []
            if not base_name.startswith("MOC-"):
                moc_variants.append(f"MOC-{base_name}.md")
            
            for variant in moc_variants:
                full_path = os.path.join(root, variant)
                if os.path.exists(full_path):
                    self._debug(f"Found MOC file in subdirectory: {full_path}")
                    return full_path
                    
            # Also check for partial matches (file contains the base name)
            for file in files:
                if file.endswith('.md') and base_name.lower() in file.lower():
                    full_path = os.path.join(root, file)
                    self._debug(f"Found partial match in subdirectory: {full_path}")
                    return full_path
        
        self._debug(f"Could not normalize filename: {filename}")
        return None
        
    def _custom_walk(self, top):
        """A custom walk function that follows symlinks."""
        for root, dirs, files in os.walk(top, followlinks=True):
            yield root, dirs, files

    def get_statistics(self) -> dict:
        """Get statistics about processed files."""
        total_lines = sum(len(content.splitlines()) for _, content in self.collected_files)
        total_size = sum(os.path.getsize(path) for path, _ in self.collected_files)
        total_tokens = sum(self._get_token_count(path) for path, _ in self.collected_files)
        
        return {
            'file_count': len(self.collected_files),
            'total_lines': total_lines,
            'total_size': self._format_size(total_size),
            'total_tokens': total_tokens
        }

# Example usage
if __name__ == "__main__":
    import argparse
    import pyperclip
    import sys
    
    parser = argparse.ArgumentParser(description='Collect and combine Obsidian notes.')
    parser.add_argument('input_file', help='The starting note file to process')
    parser.add_argument('--depth', type=int, default=1, help='Maximum depth of links to follow (default: 1)')
    parser.add_argument('--vault', help='Path to the Obsidian vault')
    parser.add_argument('--output', help='Output file path (default: temp/aggregate_<input_filename>.txt)')
    parser.add_argument('--debug', action='store_true', help='Enable debug output')
    parser.add_argument('--verbose', action='store_true', help='Enable detailed progress messages')
    parser.add_argument('--no-clipboard', action='store_true', help='Disable copying to clipboard')
    
    args = parser.parse_args()
    
    # Enable verbose mode if debug is enabled
    if args.debug:
        args.verbose = True
    
    # Determine the vault path
    vault_path = args.vault
    if not vault_path:
        vault_path = os.environ.get('OBSIDIAN_VAULT_PATH')
        if not vault_path:
            # Default to current directory
            vault_path = os.getcwd()
            print(f"No vault path specified. Using current directory: {vault_path}")
    
    if not os.path.exists(vault_path):
        print(f"Error: Vault path does not exist: {vault_path}")
        sys.exit(1)
        
    if args.verbose:
        print(f"Using vault path: {vault_path}")
    
    # Create the collector
    collector = ObsidianLinkCollector(vault_path=vault_path, max_depth=args.depth, debug=args.debug)
    
    # Determine the output path
    output_filename = args.output
    if not output_filename:
        # Get output directory from environment or default to "./temp"
        output_dir = os.environ.get('O2P_OUTPUT_DIR', os.path.join(os.getcwd(), 'temp'))
        os.makedirs(output_dir, exist_ok=True)
        
        # Clean the input filename for use in the output filename
        clean_name = os.path.basename(args.input_file)
        if clean_name.endswith('.md'):
            clean_name = clean_name[:-3]
        
        output_filename = os.path.join(output_dir, f"aggregate_{clean_name}.txt")
    
    # Process the input file
    try:
        result = collector.collect_links(args.input_file)
        
        # Get statistics for printing
        stats = collector.get_statistics()
        print("\nFile Statistics:")
        print(f"- Total Files: {stats['file_count']}")
        print(f"- Total Lines: {stats['total_lines']}")
        print(f"- Total Size: {stats['total_size']}")
        print(f"- Total Tokens: {stats['total_tokens']}")
        
        # Save the result to the output file
        with open(output_filename, 'w', encoding='utf-8') as f:
            f.write(result)
        print(f"\nResults saved to: {output_filename}")
        
        # Copy to clipboard if enabled
        if not args.no_clipboard:
            try:
                pyperclip.copy(result)
                print("Content copied to clipboard!")
            except Exception as e:
                print(f"Could not copy to clipboard: {e}")
                
    except Exception as e:
        print(f"Error processing file: {e}")
        if args.debug:
            import traceback
            traceback.print_exc()
        sys.exit(1)