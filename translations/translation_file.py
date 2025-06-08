#!/usr/bin/env python3
"""
Single File Translation Tool

Translates individual files using Google Translate API with chunking and rate limiting.
Supports arbitrary file paths and creates translated versions with language suffixes.

Usage: python translation_file.py <file_path> <direction>
Example: python translation_file.py /path/to/file.md en-ru
Example: python translation_file.py /path/to/CLAUDE-jabher.md ru-en

Alias suggestion for ~/.zshrc:
alias toTranslate="python3 /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/translations/translation_file.py"
"""

import os
import sys
import argparse
import time
from pathlib import Path
import re
from typing import List, Tuple

try:
    from googletrans import Translator
    TRANSLATOR_AVAILABLE = True
except ImportError:
    TRANSLATOR_AVAILABLE = False
    print("❌ googletrans library not found. Install it with: pip install googletrans==4.0.0rc1")

# Configuration
MAX_CHUNK_SIZE = 4500  # Conservative chunk size for Google Translate API
CHUNK_DELAY_MS = 1500  # 1.5 seconds delay between chunks
MIN_DELAY_MS = 500     # Minimum delay for safety


class FileTranslator:
    def __init__(self):
        if not TRANSLATOR_AVAILABLE:
            raise ImportError("googletrans library is required. Install with: pip install googletrans==4.0.0rc1")
        
        self.translator = Translator()
        self.max_chunk_size = MAX_CHUNK_SIZE
        self.chunk_delay_ms = CHUNK_DELAY_MS
        self.supported_languages = {
            'en': 'english',
            'ru': 'russian', 
            'es': 'spanish',
            'fr': 'french',
            'de': 'german',
            'it': 'italian',
            'pt': 'portuguese',
            'zh': 'chinese',
            'ja': 'japanese',
            'ko': 'korean',
            'ar': 'arabic',
            'hi': 'hindi',
            'tr': 'turkish',
            'pl': 'polish',
            'nl': 'dutch',
            'sv': 'swedish',
            'da': 'danish',
            'no': 'norwegian',
            'fi': 'finnish'
        }
    
    def parse_direction(self, direction: str) -> Tuple[str, str]:
        """Parse translation direction like 'en-ru' or 'ru-en'"""
        if '-' not in direction:
            raise ValueError(f"Invalid direction format: '{direction}'. Use format like 'en-ru' or 'ru-en'")
        
        source_lang, target_lang = direction.split('-', 1)
        
        if source_lang not in self.supported_languages:
            raise ValueError(f"Unsupported source language: '{source_lang}'")
        if target_lang not in self.supported_languages:
            raise ValueError(f"Unsupported target language: '{target_lang}'")
        
        return source_lang, target_lang
    
    def split_text_into_chunks(self, text: str, chunk_size: int = None) -> List[str]:
        """Split text into chunks, trying to break at sentence boundaries"""
        if chunk_size is None:
            chunk_size = self.max_chunk_size
        
        if len(text) <= chunk_size:
            return [text]
        
        chunks = []
        remaining_text = text
        
        while remaining_text:
            if len(remaining_text) <= chunk_size:
                chunks.append(remaining_text)
                break
            
            # Try to break at sentence boundaries near the chunk size
            break_point = chunk_size
            
            # Look for sentence endings within the last 20% of the chunk
            search_start = max(0, int(chunk_size * 0.8))
            sentence_end_pattern = r'[.!?]\s+'
            
            matches = list(re.finditer(sentence_end_pattern, remaining_text[search_start:break_point]))
            if matches:
                # Use the last sentence ending found
                last_match = matches[-1]
                break_point = search_start + last_match.end()
            else:
                # Look for word boundaries if no sentence endings found
                while break_point > search_start and remaining_text[break_point] not in ' \t\n':
                    break_point -= 1
                
                if break_point <= search_start:
                    break_point = chunk_size  # Fall back to hard cut
            
            chunks.append(remaining_text[:break_point])
            remaining_text = remaining_text[break_point:].lstrip()
        
        return chunks
    
    def translate_chunk(self, chunk: str, target_lang: str, source_lang: str = 'auto') -> str:
        """Translate a single chunk of text"""
        try:
            result = self.translator.translate(chunk, src=source_lang, dest=target_lang)
            return result.text
        except Exception as e:
            print(f"❌ Error translating chunk: {str(e)}")
            raise
    
    def translate_text_in_chunks(self, text: str, target_lang: str, source_lang: str = 'auto') -> str:
        """Translate text by breaking it into chunks with rate limiting"""
        chunks = self.split_text_into_chunks(text)
        translated_chunks = []
        
        print(f"📝 Text split into {len(chunks)} chunks")
        
        for i, chunk in enumerate(chunks, 1):
            print(f"🔄 Translating chunk {i}/{len(chunks)} ({len(chunk)} chars)")
            
            try:
                translated_chunk = self.translate_chunk(chunk, target_lang, source_lang)
                translated_chunks.append(translated_chunk)
                print(f"✅ Chunk {i} translated successfully")
                
                # Rate limiting between chunks
                if i < len(chunks):
                    delay = self.chunk_delay_ms / 1000.0
                    print(f"⏱️  Waiting {delay:.1f}s before next chunk...")
                    time.sleep(delay)
                    
            except Exception as e:
                print(f"❌ Failed to translate chunk {i}: {str(e)}")
                print(f"Chunk content preview: {chunk[:100]}...")
                raise
        
        return ''.join(translated_chunks)
    
    def get_output_path(self, input_path: Path, target_lang: str) -> Path:
        """Generate output file path with language suffix"""
        # Get the file parts
        directory = input_path.parent
        stem = input_path.stem
        suffix = input_path.suffix
        
        # Create new filename with language suffix
        new_filename = f"{stem}_{target_lang}{suffix}"
        return directory / new_filename
    
    def translate_file(self, file_path: str, direction: str) -> bool:
        """Main translation function"""
        try:
            # Parse arguments
            source_lang, target_lang = self.parse_direction(direction)
            input_path = Path(file_path).resolve()
            
            # Validate input file
            if not input_path.exists():
                print(f"❌ Input file not found: {input_path}")
                return False
            
            if not input_path.is_file():
                print(f"❌ Path is not a file: {input_path}")
                return False
            
            # Generate output path
            output_path = self.get_output_path(input_path, target_lang)
            
            # Check if output already exists
            if output_path.exists():
                response = input(f"⚠️  Output file already exists: {output_path.name}\nOverwrite? (y/N): ")
                if response.lower() not in ['y', 'yes']:
                    print("❌ Translation cancelled")
                    return False
            
            print(f"🚀 Starting translation:")
            print(f"   Source: {input_path}")
            print(f"   Target: {output_path}")
            print(f"   Direction: {source_lang} → {target_lang}")
            print(f"   Languages: {self.supported_languages[source_lang]} → {self.supported_languages[target_lang]}")
            
            # Read input file
            try:
                with open(input_path, 'r', encoding='utf-8') as file:
                    content = file.read()
            except UnicodeDecodeError:
                # Try with different encoding
                with open(input_path, 'r', encoding='latin-1') as file:
                    content = file.read()
            
            if not content.strip():
                print("❌ Input file is empty")
                return False
            
            print(f"📖 Read {len(content)} characters from input file")
            
            # Translate content
            print(f"🌍 Translating from {source_lang} to {target_lang}...")
            translated_content = self.translate_text_in_chunks(content, target_lang, source_lang)
            
            # Write output file
            with open(output_path, 'w', encoding='utf-8') as file:
                file.write(translated_content)
            
            print(f"✅ Translation completed successfully!")
            print(f"📁 Output saved to: {output_path}")
            print(f"📊 Translated {len(content)} → {len(translated_content)} characters")
            
            return True
            
        except Exception as e:
            print(f"❌ Translation failed: {str(e)}")
            return False


def main():
    parser = argparse.ArgumentParser(
        description="Translate individual files using Google Translate API",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python translation_file.py /path/to/file.md en-ru
  python translation_file.py /Users/user/Documents/notes.txt ru-en
  python translation_file.py ./CLAUDE-jabher.md en-ru

Supported languages:
  en (english), ru (russian), es (spanish), fr (french), de (german),
  it (italian), pt (portuguese), zh (chinese), ja (japanese), ko (korean),
  ar (arabic), hi (hindi), tr (turkish), pl (polish), nl (dutch),
  sv (swedish), da (danish), no (norwegian), fi (finnish)

Alias suggestion for ~/.zshrc:
  alias toTranslate="python3 {}"
        """.format(__file__)
    )
    
    parser.add_argument(
        "file_path",
        help="Path to the file to translate"
    )
    
    parser.add_argument(
        "direction", 
        help="Translation direction (e.g., 'en-ru', 'ru-en')"
    )
    
    parser.add_argument(
        "--chunk-size",
        type=int,
        default=MAX_CHUNK_SIZE,
        help=f"Maximum chunk size for translation (default: {MAX_CHUNK_SIZE})"
    )
    
    args = parser.parse_args()
    
    if not TRANSLATOR_AVAILABLE:
        print("❌ Required dependency missing!")
        print("Install with: pip install googletrans==4.0.0rc1")
        sys.exit(1)
    
    # Create translator and process file
    translator = FileTranslator()
    
    # Update chunk size if specified
    translator.max_chunk_size = args.chunk_size
    
    success = translator.translate_file(args.file_path, args.direction)
    
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
