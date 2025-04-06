#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
ObsidianToPrompt - Process Obsidian vault links and extract content.
"""

import re
import os
import sys
import argparse
import subprocess
from typing import List, Tuple, Optional, Dict, Set
from datetime import datetime
import pyperclip

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
        # Updated pattern to properly handle links with pipe symbol AND heading links
        self.link_pattern = re.compile(r'(?:\[\[|\!)?\[\[(.*?)(?:#(.*?))?\]\](?:\]\])?')
        self.file_content_map = {}  # Track file content by file path
        
    def _debug(self, msg: str):
        if self.debug_enabled:
            print(f"DEBUG: {msg}")

    def process(self, start_path: str) -> str:
        """Process the Obsidian vault starting from a specific file."""
        self.start_file = start_path
        normalized_path = self._normalize_filename(start_path)
        
        if not normalized_path:
            self._debug(f"Could not find file: {start_path}")
            return f"File not found: {start_path}"
            
        self._debug(f"Starting from normalized file: {normalized_path}")
        
        # Process the start file
        self._process_file(normalized_path, 0)
        
        return self._generate_output()

    def _process_file(self, filename: str, current_depth: int = 0, specific_heading: Optional[str] = None) -> None:
        """Process a file and extract its content and links."""
        self._debug(f"Processing file: {filename} at depth {current_depth}")
            
        # Check if we've already processed this exact file+heading combination
        file_heading_key = f"{filename}#{specific_heading or ''}"
        if file_heading_key in self.visited_files:
            self._debug(f"Skipping already processed file+heading: {file_heading_key}")
            return
            
        # Add to visited files to prevent duplicates
        self.visited_files.add(file_heading_key)
        
        # Check if file exists
        if not os.path.exists(filename):
            self._debug(f"File does not exist: {filename}")
            return
            
        # Read the file content
        try:
            with open(filename, 'r', encoding='utf-8') as f:
                full_content = f.read()
        except Exception as e:
            self._debug(f"Error reading file {filename}: {str(e)}")
            return
            
        # Determine the content to add (full file or specific section)
        content_to_add = full_content # Default to full content
        
        # If a specific heading is requested, extract that section
        if specific_heading:
            self._debug(f"Looking for heading '{specific_heading}' in {filename}")
            extracted_section = self._extract_section(full_content, specific_heading)
            if extracted_section:
                content_to_add = extracted_section
                self._debug(f"Extracted section under heading '{specific_heading}'")
            else:
                self._debug(f"Heading '{specific_heading}' not found. Adding full file content instead.")
        
        # Store file to content mapping
        self.file_content_map[file_heading_key] = content_to_add
        
        # Add to collected files
        self.collected_files.append((filename, content_to_add))
        self._debug(f"Collected content from: {filename} (Heading: {specific_heading or 'None'})")
        
        # If we've reached the maximum depth, don't process links
        if current_depth >= self.max_depth:
            return
        
        # Extract all links and organize them by target file
        raw_links = self.link_pattern.findall(full_content)
        self._debug(f"Found {len(raw_links)} potential links in {filename}")
        
        # Group links by target file
        link_groups = {}
        for match in raw_links:
            link_target = match[0].strip()
            heading_target = match[1].strip() if len(match) > 1 and match[1] else None
            
            if link_target not in link_groups:
                link_groups[link_target] = []
            link_groups[link_target].append(heading_target)
        
        # Process each target file exactly once, prioritizing general links
        for link_target, headings in link_groups.items():
            normalized_path = self._normalize_filename(link_target)
            if not normalized_path:
                self._debug(f"Could not normalize link target: {link_target}")
                continue
                
            self._debug(f"Link target '{link_target}' normalized to: {normalized_path}")
            
            # Check if there's a general link (None heading)
            if None in headings:
                # Process the general link and skip all heading-specific links
                self._debug(f"Found general link for {link_target}, skipping all heading-specific links")
                self._process_file(normalized_path, current_depth + 1)
            else:
                # Process each unique heading-specific link
                unique_headings = list(set(headings))
                for heading in unique_headings:
                    if heading:  # Skip empty headings
                        self._debug(f"Processing heading-specific link: {link_target}#{heading}")
                        self._process_file(normalized_path, current_depth + 1, specific_heading=heading)

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
        for i, (file_path, content) in enumerate(self.collected_files):
            # Get the relative path
            rel_path = os.path.relpath(file_path, self.vault_path)
            
            # Find which heading (if any) this file+content was collected with
            heading = None
            for file_heading_key, stored_content in self.file_content_map.items():
                if file_path in file_heading_key and stored_content == content:
                    # Extract heading from the key (format: filepath#heading)
                    if '#' in file_heading_key:
                        heading = file_heading_key.split('#', 1)[1]
                    break
            
            # Add heading information if available
            if heading:
                rel_path = f"{rel_path} (heading: {heading})"
            
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
        
        # Calculate size based on the actual collected content, not original file sizes
        total_content_size = sum(len(content.encode('utf-8')) for _, content in self.collected_files)
        
        # Calculate token count based on the actual content
        total_tokens = 0
        for _, content in self.collected_files:
            # Estimate tokens: roughly 4 characters per token
            total_tokens += len(content.split())
        
        return {
            'file_count': len(self.collected_files),
            'total_lines': total_lines,
            'total_size': self._format_size(total_content_size),
            'total_tokens': total_tokens
        }

    def _extract_section(self, content: str, heading: str) -> Optional[str]:
        """Extracts the content under a specific markdown heading."""
        # Normalize heading for matching (case-insensitive, strip whitespace)
        normalized_heading = heading.strip().lower()
        # Replace some common punctuation/formatting with spaces for better matching
        normalized_heading = re.sub(r'[:_\-]', ' ', normalized_heading)
        # Remove extra spaces
        normalized_heading = re.sub(r'\s+', ' ', normalized_heading).strip()
        
        self._debug(f"Looking for normalized heading: '{normalized_heading}'")
        
        lines = content.splitlines()
        start_line = -1
        heading_level = -1
        
        # Find the heading line and its level
        for i, line in enumerate(lines):
            stripped_line = line.strip()
            if stripped_line.startswith('#'):
                level = stripped_line.count('#', 0, 6) # Max heading level 6
                # Extract heading text after the # symbols and removing any trailing #s (for markdown style)
                heading_text = stripped_line[level:].strip().lower()
                heading_text = heading_text.rstrip('#').strip()  # Handle ### Header ### style
                
                # Normalize the found heading text in the same way as the target
                heading_text = re.sub(r'[:_\-]', ' ', heading_text)
                heading_text = re.sub(r'\s+', ' ', heading_text).strip()
                
                self._debug(f"Checking heading at line {i+1}: '{heading_text}' (level {level}) against '{normalized_heading}'")
                
                if heading_text == normalized_heading:
                    start_line = i
                    heading_level = level
                    self._debug(f"Found matching heading '{heading}' at line {i+1}, level {level}")
                    break
                    
        if start_line == -1:
            self._debug(f"Heading '{heading}' not found in content")
            return None # Heading not found
            
        # Find the end of the section (next heading of same or lower level, or EOF)
        end_line = len(lines)
        for i in range(start_line + 1, len(lines)):
            stripped_line = lines[i].strip()
            if stripped_line.startswith('#'):
                level = stripped_line.count('#', 0, 6)
                if level <= heading_level:
                    end_line = i
                    self._debug(f"End of section found at line {i+1} (next heading of level {level})")
                    break
                    
        # Extract the lines for the section (including the heading line itself)
        section_lines = lines[start_line:end_line]
        section_content = "\n".join(section_lines)
        self._debug(f"Extracted section with {len(section_lines)} lines")
        return section_content

def main():
    parser = argparse.ArgumentParser(description='Process Obsidian vault links.')
    parser.add_argument('input_file', help='The starting Obsidian note')
    parser.add_argument('--depth', type=int, default=5, help='Maximum depth to follow links')
    parser.add_argument('--output', help='Output file path')
    parser.add_argument('--vault-path', help='Path to the Obsidian vault')
    parser.add_argument('--debug', action='store_true', help='Enable debug output')
    parser.add_argument('--clipboard', action='store_true', help='Copy result to clipboard')
    parser.add_argument('--version', action='version', version='%(prog)s 1.3.0')
    args = parser.parse_args()
    
    # Determine vault path
    vault_path = args.vault_path
    if not vault_path:
        vault_path = os.environ.get('OBSIDIAN_VAULT_PATH')
        if not vault_path:
            # Default to the user's home directory
            vault_path = os.path.expanduser('~')
    
    print(f"Using vault path: {vault_path}")
    
    # Create collector instance
    collector = ObsidianLinkCollector(vault_path, args.depth, args.debug)
    
    # Process the input file
    try:
        result = collector.process(args.input_file)
        
        # Get statistics for printing
        stats = collector.get_statistics()
        
        # Determine where to save
        if args.output:
            output_path = args.output
        else:
            temp_dir = os.path.join(vault_path, 'temp')
            os.makedirs(temp_dir, exist_ok=True)
            base_name = os.path.basename(args.input_file).replace('.md', '')
            output_path = os.path.join(temp_dir, f"aggregate_{base_name}.txt")
        
        # Write to file
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(result)
        
        # Display summary
        print("\nFile Statistics:")
        print(f"- Total Files: {stats['file_count']}")
        print(f"- Total Lines: {stats['total_lines']}")
        print(f"- Total Size: {stats['total_size']}")
        print(f"- Total Tokens: {stats['total_tokens']}")
        print(f"\nResults saved to: {output_path}")
        
        # Copy to clipboard if requested
        if args.clipboard:
            try:
                pyperclip.copy(result)
                print("Content copied to clipboard!")
            except Exception as e:
                print(f"Error copying to clipboard: {str(e)}")
        
    except Exception as e:
        print(f"Error processing file: {str(e)}")
        if args.debug:
            import traceback
            traceback.print_exc()
        return 1
        
    return 0

if __name__ == "__main__":
    sys.exit(main())