#!/usr/bin/env python3
"""
Prompts/Outputs Extractor for Markdown Files

Usage:
    prompts_extractor.py filename {prompts|outputs}
    
Examples:
    prompts_extractor.py __SecondBrain/Dailies_Notes/2025-06-08-Su.md prompts
    prompts_extractor.py __SecondBrain/Dailies_Notes/2025-06-08-Su.md outputs
    
This script extracts:
- ````prompt blocks → saves to filename.prompts.md
- ````output blocks → saves to filename.outputs.md

Author: Alex Aleksandruk
"""

import sys
import os
import re
from pathlib import Path
from typing import List, Tuple

def extract_blocks(content: str, block_type: str) -> List[str]:
    """
    Extract blocks of specified type from markdown content.
    
    Args:
        content: The markdown file content
        block_type: Either 'prompt' or 'output'
    
    Returns:
        List of extracted block contents
    """
    blocks = []
    
    # Pattern to match code blocks with specific type
    # Matches: ````prompt or ````output followed by content until ````
    pattern = rf'```{{{block_type}}}(.*?)```'
    
    # Find all matches (DOTALL flag to include newlines)
    matches = re.findall(pattern, content, re.DOTALL)
    
    for match in matches:
        # Clean up the content - remove leading/trailing whitespace
        cleaned_content = match.strip()
        if cleaned_content:
            blocks.append(cleaned_content)
    
    # Also check for standard markdown code blocks with type label
    # Pattern: ````\ntype\ncontent\n````
    alt_pattern = rf'````\s*{block_type}\s*\n(.*?)\n````'
    alt_matches = re.findall(alt_pattern, content, re.DOTALL)
    
    for match in alt_matches:
        cleaned_content = match.strip()
        if cleaned_content:
            blocks.append(cleaned_content)
    
    return blocks

def generate_output_content(blocks: List[str], block_type: str) -> str:
    """
    Generate formatted output content with numbered headers.
    
    Args:
        blocks: List of extracted blocks
        block_type: Either 'prompt' or 'output'
    
    Returns:
        Formatted content string
    """
    if not blocks:
        return f"# No {block_type}s found\n\nNo {block_type} blocks were found in the source file.\n"
    
    content_lines = [
        f"# Extracted {block_type.title()}s",
        f"",
        f"Total {block_type}s found: {len(blocks)}",
        f"",
        "---",
        ""
    ]
    
    for i, block in enumerate(blocks, 1):
        header = f"${block_type}-{i:02d}"
        content_lines.extend([
            f"## {header}",
            "",
            f"```{block_type}",
            block,
            "```",
            "",
            "---",
            ""
        ])
    
    return "\n".join(content_lines)

def main():
    """Main function to handle command line arguments and process files."""
    
    if len(sys.argv) != 3:
        print("Usage: prompts_extractor.py <filename> {prompts|outputs}")
        print("\nExamples:")
        print("  prompts_extractor.py daily.md prompts")
        print("  prompts_extractor.py daily.md outputs")
        sys.exit(1)
    
    input_file = sys.argv[1]
    extract_type = sys.argv[2].lower()
    
    # Validate extract type
    if extract_type not in ['prompts', 'outputs']:
        print(f"Error: extract type must be 'prompts' or 'outputs', got '{extract_type}'")
        sys.exit(1)
    
    # Convert to Path object for easier manipulation
    input_path = Path(input_file)
    
    # Check if input file exists
    if not input_path.exists():
        print(f"Error: Input file '{input_file}' does not exist")
        sys.exit(1)
    
    # Generate output filename
    output_filename = f"{input_path.stem}.{extract_type}{input_path.suffix}"
    output_path = input_path.parent / output_filename
    
    try:
        # Read input file
        with open(input_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Extract blocks based on type
        block_type = extract_type.rstrip('s')  # Remove 's' from 'prompts'/'outputs'
        extracted_blocks = extract_blocks(content, block_type)
        
        # Generate output content
        output_content = generate_output_content(extracted_blocks, block_type)
        
        # Write output file
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(output_content)
        
        # Print summary
        print(f"✅ Extracted {len(extracted_blocks)} {block_type}(s) from '{input_file}'")
        print(f"📄 Saved to: '{output_path}'")
        
        if extracted_blocks:
            print(f"\n📋 Found {block_type}s:")
            for i, block in enumerate(extracted_blocks, 1):
                preview = block[:100].replace('\n', ' ')
                if len(block) > 100:
                    preview += "..."
                print(f"  {i:02d}: {preview}")
    
    except FileNotFoundError:
        print(f"❌ Error: Could not read file '{input_file}'")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
