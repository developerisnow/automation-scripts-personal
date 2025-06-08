#!/usr/bin/env python3
"""
Enhanced Translation Tool with Multiple Backends

Supports multiple translation services for better quality:
- Claude 3 Haiku (recommended for quality)
- OpenAI GPT-4o-mini (good quality, cheap)
- Local Ollama (free, private)
- Google Translate (fallback)

Usage: python translation_file_enhanced.py <file_path> <direction> [--backend claude|openai|ollama|google]
Example: python translation_file_enhanced.py file.md en-ru --backend claude
"""

import os
import sys
import argparse
import time
import json
from pathlib import Path
import re
from typing import List, Tuple, Optional

# Backend-specific imports
try:
    import anthropic
    CLAUDE_AVAILABLE = True
except ImportError:
    CLAUDE_AVAILABLE = False

try:
    import openai
    OPENAI_AVAILABLE = True
except ImportError:
    OPENAI_AVAILABLE = False

try:
    import requests
    OLLAMA_AVAILABLE = True
except ImportError:
    OLLAMA_AVAILABLE = False

try:
    from googletrans import Translator
    GOOGLE_AVAILABLE = True
except ImportError:
    GOOGLE_AVAILABLE = False


class TranslationBackend:
    def __init__(self, backend_type: str):
        self.backend_type = backend_type
        self.setup_backend()
    
    def setup_backend(self):
        """Initialize the specific backend"""
        if self.backend_type == "claude":
            if not CLAUDE_AVAILABLE:
                raise ImportError("anthropic library required: pip install anthropic")
            api_key = os.getenv("ANTHROPIC_API_KEY")
            if not api_key:
                raise ValueError("ANTHROPIC_API_KEY environment variable required")
            self.client = anthropic.Anthropic(api_key=api_key)
            
        elif self.backend_type == "openai":
            if not OPENAI_AVAILABLE:
                raise ImportError("openai library required: pip install openai")
            api_key = os.getenv("OPENAI_API_KEY")
            if not api_key:
                raise ValueError("OPENAI_API_KEY environment variable required")
            self.client = openai.OpenAI(api_key=api_key)
            
        elif self.backend_type == "ollama":
            if not OLLAMA_AVAILABLE:
                raise ImportError("requests library required for Ollama")
            # Test Ollama connection
            try:
                response = requests.get("http://localhost:11434/api/tags", timeout=5)
                if response.status_code != 200:
                    raise ConnectionError("Ollama not running. Start with: ollama serve")
            except requests.exceptions.RequestException:
                raise ConnectionError("Ollama not accessible. Install: https://ollama.ai")
                
        elif self.backend_type == "google":
            if not GOOGLE_AVAILABLE:
                raise ImportError("googletrans library required: pip install googletrans==4.0.0rc1")
            self.client = Translator()
    
    def translate_chunk(self, text: str, source_lang: str, target_lang: str) -> str:
        """Translate a chunk of text using the selected backend"""
        
        if self.backend_type == "claude":
            return self._translate_claude(text, source_lang, target_lang)
        elif self.backend_type == "openai":
            return self._translate_openai(text, source_lang, target_lang)
        elif self.backend_type == "ollama":
            return self._translate_ollama(text, source_lang, target_lang)
        elif self.backend_type == "google":
            return self._translate_google(text, source_lang, target_lang)
        else:
            raise ValueError(f"Unknown backend: {self.backend_type}")
    
    def _translate_claude(self, text: str, source_lang: str, target_lang: str) -> str:
        """Translate using Claude 3 Haiku"""
        lang_names = {
            'en': 'English', 'ru': 'Russian', 'es': 'Spanish', 'fr': 'French',
            'de': 'German', 'it': 'Italian', 'pt': 'Portuguese', 'zh': 'Chinese',
            'ja': 'Japanese', 'ko': 'Korean'
        }
        
        source_name = lang_names.get(source_lang, source_lang)
        target_name = lang_names.get(target_lang, target_lang)
        
        prompt = f"""Translate this text from {source_name} to {target_name}. 

IMPORTANT INSTRUCTIONS:
- Preserve ALL technical terms, commands, and code snippets in English
- Maintain natural flow and professional tone in {target_name}
- Keep formatting, structure, and any special characters
- For technical documentation, prioritize accuracy over literal translation

Text to translate:

{text}"""

        try:
            response = self.client.messages.create(
                model="claude-3-haiku-20240307",
                max_tokens=4000,
                messages=[{"role": "user", "content": prompt}]
            )
            return response.content[0].text.strip()
        except Exception as e:
            raise RuntimeError(f"Claude translation failed: {str(e)}")
    
    def _translate_openai(self, text: str, source_lang: str, target_lang: str) -> str:
        """Translate using OpenAI GPT-4o-mini"""
        lang_names = {
            'en': 'English', 'ru': 'Russian', 'es': 'Spanish', 'fr': 'French',
            'de': 'German', 'it': 'Italian', 'pt': 'Portuguese', 'zh': 'Chinese',
            'ja': 'Japanese', 'ko': 'Korean'
        }
        
        source_name = lang_names.get(source_lang, source_lang)
        target_name = lang_names.get(target_lang, target_lang)
        
        prompt = f"""Translate this text from {source_name} to {target_name}.

IMPORTANT: Preserve all technical terms, commands, and code snippets in English. Maintain natural flow and professional tone.

{text}"""

        try:
            response = self.client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[
                    {"role": "system", "content": "You are an expert translator specializing in technical documentation."},
                    {"role": "user", "content": prompt}
                ],
                max_tokens=4000,
                temperature=0.1
            )
            return response.choices[0].message.content.strip()
        except Exception as e:
            raise RuntimeError(f"OpenAI translation failed: {str(e)}")
    
    def _translate_ollama(self, text: str, source_lang: str, target_lang: str) -> str:
        """Translate using local Ollama"""
        lang_names = {
            'en': 'English', 'ru': 'Russian', 'es': 'Spanish', 'fr': 'French',
            'de': 'German', 'it': 'Italian', 'pt': 'Portuguese', 'zh': 'Chinese',
            'ja': 'Japanese', 'ko': 'Korean'
        }
        
        source_name = lang_names.get(source_lang, source_lang)
        target_name = lang_names.get(target_lang, target_lang)
        
        prompt = f"""Translate from {source_name} to {target_name}. Preserve technical terms in English.

{text}"""

        try:
            response = requests.post("http://localhost:11434/api/generate", 
                json={
                    "model": "qwen2.5:32b",
                    "prompt": prompt,
                    "stream": False,
                    "options": {"temperature": 0.1}
                },
                timeout=120
            )
            
            if response.status_code == 200:
                return response.json()["response"].strip()
            else:
                raise RuntimeError(f"Ollama request failed: {response.status_code}")
                
        except requests.exceptions.RequestException as e:
            raise RuntimeError(f"Ollama translation failed: {str(e)}")
    
    def _translate_google(self, text: str, source_lang: str, target_lang: str) -> str:
        """Translate using Google Translate (fallback)"""
        try:
            result = self.client.translate(text, src=source_lang, dest=target_lang)
            return result.text
        except Exception as e:
            raise RuntimeError(f"Google translation failed: {str(e)}")


class EnhancedFileTranslator:
    def __init__(self, backend_type: str = "claude"):
        self.backend = TranslationBackend(backend_type)
        self.max_chunk_size = 4000 if backend_type in ["claude", "openai"] else 2000
        self.chunk_delay = 1.0 if backend_type in ["claude", "openai"] else 0.5
        
        self.supported_languages = {
            'en': 'English', 'ru': 'Russian', 'es': 'Spanish', 'fr': 'French',
            'de': 'German', 'it': 'Italian', 'pt': 'Portuguese', 'zh': 'Chinese',
            'ja': 'Japanese', 'ko': 'Korean', 'ar': 'Arabic', 'hi': 'Hindi',
            'tr': 'Turkish', 'pl': 'Polish', 'nl': 'Dutch', 'sv': 'Swedish'
        }
    
    def parse_direction(self, direction: str) -> Tuple[str, str]:
        """Parse translation direction like 'en-ru'"""
        if '-' not in direction:
            raise ValueError(f"Invalid direction: '{direction}'. Use format like 'en-ru'")
        
        source_lang, target_lang = direction.split('-', 1)
        
        if source_lang not in self.supported_languages:
            raise ValueError(f"Unsupported source language: '{source_lang}'")
        if target_lang not in self.supported_languages:
            raise ValueError(f"Unsupported target language: '{target_lang}'")
        
        return source_lang, target_lang
    
    def split_text_smart(self, text: str) -> List[str]:
        """Smart text splitting for better context preservation"""
        if len(text) <= self.max_chunk_size:
            return [text]
        
        # Try to split on double newlines (paragraphs) first
        paragraphs = text.split('\n\n')
        chunks = []
        current_chunk = ""
        
        for paragraph in paragraphs:
            if len(current_chunk) + len(paragraph) + 2 <= self.max_chunk_size:
                if current_chunk:
                    current_chunk += '\n\n' + paragraph
                else:
                    current_chunk = paragraph
            else:
                if current_chunk:
                    chunks.append(current_chunk)
                
                # Handle oversized paragraphs
                if len(paragraph) > self.max_chunk_size:
                    # Split on sentences
                    sentences = re.split(r'(?<=[.!?])\s+', paragraph)
                    temp_chunk = ""
                    for sentence in sentences:
                        if len(temp_chunk) + len(sentence) + 1 <= self.max_chunk_size:
                            if temp_chunk:
                                temp_chunk += ' ' + sentence
                            else:
                                temp_chunk = sentence
                        else:
                            if temp_chunk:
                                chunks.append(temp_chunk)
                            temp_chunk = sentence
                    if temp_chunk:
                        current_chunk = temp_chunk
                    else:
                        current_chunk = ""
                else:
                    current_chunk = paragraph
        
        if current_chunk:
            chunks.append(current_chunk)
        
        return chunks
    
    def translate_file(self, file_path: str, direction: str) -> bool:
        """Main translation function"""
        try:
            source_lang, target_lang = self.parse_direction(direction)
            input_path = Path(file_path).resolve()
            
            if not input_path.exists():
                print(f"❌ File not found: {input_path}")
                return False
            
            # Generate output path
            output_path = input_path.parent / f"{input_path.stem}_{target_lang}{input_path.suffix}"
            
            if output_path.exists():
                response = input(f"⚠️  Output exists: {output_path.name}\nOverwrite? (y/N): ")
                if response.lower() not in ['y', 'yes']:
                    return False
            
            print(f"🚀 Enhanced Translation:")
            print(f"   Backend: {self.backend.backend_type.upper()}")
            print(f"   Source: {input_path.name}")
            print(f"   Target: {output_path.name}")
            print(f"   Direction: {source_lang} → {target_lang}")
            
            # Read and translate
            with open(input_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            print(f"📖 Processing {len(content)} characters...")
            
            chunks = self.split_text_smart(content)
            print(f"📝 Split into {len(chunks)} chunks")
            
            translated_chunks = []
            for i, chunk in enumerate(chunks, 1):
                print(f"🔄 Translating chunk {i}/{len(chunks)} ({len(chunk)} chars)")
                
                translated = self.backend.translate_chunk(chunk, source_lang, target_lang)
                translated_chunks.append(translated)
                print(f"✅ Chunk {i} completed")
                
                if i < len(chunks):
                    time.sleep(self.chunk_delay)
            
            # Write result
            final_content = '\n\n'.join(translated_chunks)
            with open(output_path, 'w', encoding='utf-8') as f:
                f.write(final_content)
            
            print(f"✅ Translation completed!")
            print(f"📁 Saved: {output_path}")
            print(f"📊 {len(content)} → {len(final_content)} characters")
            
            return True
            
        except Exception as e:
            print(f"❌ Translation failed: {str(e)}")
            return False


def main():
    parser = argparse.ArgumentParser(
        description="Enhanced file translation with multiple backends",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Backend Options:
  claude    - Claude 3 Haiku (best quality, requires ANTHROPIC_API_KEY)
  openai    - GPT-4o-mini (good quality, requires OPENAI_API_KEY)  
  ollama    - Local Qwen2.5 (free, requires ollama serve)
  google    - Google Translate (free fallback)

Examples:
  python translation_file_enhanced.py file.md en-ru --backend claude
  python translation_file_enhanced.py doc.txt ru-en --backend openai
  python translation_file_enhanced.py notes.md en-es --backend ollama

Setup:
  export ANTHROPIC_API_KEY="your-key"  # For Claude
  export OPENAI_API_KEY="your-key"     # For OpenAI
  ollama pull qwen2.5:32b              # For Ollama
        """
    )
    
    parser.add_argument("file_path", help="File to translate")
    parser.add_argument("direction", help="Translation direction (e.g., en-ru)")
    parser.add_argument("--backend", 
                       choices=["claude", "openai", "ollama", "google"],
                       default="claude",
                       help="Translation backend (default: claude)")
    
    args = parser.parse_args()
    
    try:
        translator = EnhancedFileTranslator(args.backend)
        success = translator.translate_file(args.file_path, args.direction)
        sys.exit(0 if success else 1)
        
    except Exception as e:
        print(f"❌ Setup failed: {str(e)}")
        sys.exit(1)


if __name__ == "__main__":
    main() 