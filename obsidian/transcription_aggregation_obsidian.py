import json
import os
import sys
from datetime import datetime, timedelta
import re

OBSIDIAN_VAULT_BASE_PATH = "/Users/user/____Sandruk/___PKM/__SecondBrain/Dailies_Transcriptions/"

def format_duration_minutes(duration_ms):
    if duration_ms is None:
        return 0
    return round(duration_ms / 60000)

def get_day_abbreviation(dt_obj):
    return dt_obj.strftime('%a')[:2] # Mo, Tu, We, Th, Fr, Sa, Su

def parse_meta_json(meta_json_path):
    with open(meta_json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    details = {}
    dt_str = data.get("datetime")
    if not dt_str:
        print(f"Error: 'datetime' field missing in {meta_json_path}")
        return None
    
    dt_obj = datetime.fromisoformat(dt_str.replace('Z', '')) # Handle potential Zulu time

    details['datetime_obj'] = dt_obj
    details['yyyymmdd'] = dt_obj.strftime('%Y%m%d')
    details['yyyy_mm'] = dt_obj.strftime('%Y-%m')
    details['hhmm'] = dt_obj.strftime('%H%M')
    details['day_abbr'] = get_day_abbreviation(dt_obj)

    details['rawResult'] = data.get('rawResult', '')
    details['llmResult'] = data.get('llmResult', '') # Might be empty or not present
    details['duration_ms'] = data.get('duration') # In milliseconds
    details['duration_min'] = format_duration_minutes(details['duration_ms'])
    
    details['modeName'] = data.get('modeName', 'UnknownMode')
    details['modelKey'] = data.get('modelKey', 'UnknownModel')
    
    # Determine if prompt was used: llmResult exists and is not just an analysis placeholder
    details['prompt_used'] = bool(details['llmResult'] and not details['llmResult'].strip().startswith("1. <анализ_транскрипции>"))


    # Try to get the original audio filename if available (e.g. from Superwhisper's 'audioFile' field if it adds it)
    # For now, we'll use the meta.json parent directory name as a unique ID for the recording segment.
    details['recording_session_id'] = os.path.basename(os.path.dirname(meta_json_path))


    return details

def create_obsidian_content(details):
    if not details:
        return None, None

    # Header for the log entry
    # Using recording_session_id as part of the header for better uniqueness
    log_header = f"### {details['yyyymmdd']}-{details['hhmm']}_{details['recording_session_id']}_{details['duration_min']}m__{{prompt:{str(details['prompt_used']).upper()}}}__{{{details['modeName']}}}__{{{details['modelKey']}}}"
    
    content_blocks = [log_header]
    content_blocks.append("````transcription")
    content_blocks.append(details['rawResult'].strip())
    content_blocks.append("````")

    if details['prompt_used'] and details['llmResult']:
        # Extract only the <улучшенная_транскрипция> part if llmResult is structured
        improved_transcription_match = re.search(r"2\.\s*<улучшенная_транскрипция>(.*?)</улучшенная_транскрипция>", details['llmResult'], re.DOTALL | re.IGNORECASE)
        llm_text_to_insert = details['llmResult'].strip()
        if improved_transcription_match:
            llm_text_to_insert = improved_transcription_match.group(1).strip()
        
        content_blocks.append("{if $prompt=TRUE}") # Literal string as requested
        content_blocks.append("````transcription-prompted")
        content_blocks.append(llm_text_to_insert)
        content_blocks.append("````")
        content_blocks.append("{/if}") # Literal string as requested
        
    return "\n".join(content_blocks), log_header


def update_obsidian_file(details, obsidian_file_path, new_content_block, log_entry_header):
    os.makedirs(os.path.dirname(obsidian_file_path), exist_ok=True)

    today_yyyymmdd = details['datetime_obj'].strftime('%Y-%m-%d') # For YAML

    if not os.path.exists(obsidian_file_path):
        yaml_frontmatter = f"""---
type: transcriptions
created: {today_yyyymmdd}
updated: {today_yyyymmdd}
---
"""
        initial_headings = """# Timeline
## Summary

## Log
"""
        with open(obsidian_file_path, 'w', encoding='utf-8') as f:
            f.write(yaml_frontmatter)
            f.write(initial_headings)
            f.write(new_content_block + "\n")
        print(f"Created new Obsidian note and added entry: {obsidian_file_path}")
    else:
        with open(obsidian_file_path, 'r+', encoding='utf-8') as f:
            content = f.read()
            
            # Update 'updated' date in YAML
            new_yaml_updated_date = f"updated: {today_yyyymmdd}"
            content = re.sub(r"updated: \d{4}-\d{2}-\d{2}", new_yaml_updated_date, content, 1)

            # Idempotency check: Check if the specific log_entry_header (or a very similar one) already exists
            # This check is based on the unique recording_session_id in the header
            if log_entry_header in content:
                print(f"Log entry for {details['recording_session_id']} already exists in {obsidian_file_path}. Skipping.")
                return

            log_section_marker = "## Log"
            log_section_index = content.find(log_section_marker)

            if log_section_index != -1:
                # Find the end of the Log section (start of next H2 or end of file)
                end_of_log_section_match = re.search(r"(^##\s+\w+)", content[log_section_index + len(log_section_marker):], re.MULTILINE)
                if end_of_log_section_match:
                    insert_index = log_section_index + len(log_section_marker) + end_of_log_section_match.start()
                else:
                    insert_index = len(content) # Append to end if no other H2 follows

                # Ensure there's a newline before the new block if inserting not at the immediate start of section
                prefix = "\n" if content[insert_index-1:insert_index] != "\n" and insert_index > log_section_index + len(log_section_marker) else ""
                if insert_index == log_section_index + len(log_section_marker) and not content[insert_index-1:].startswith("\n"): # If inserting right after "## Log"
                     prefix = "\n"


                updated_content = content[:insert_index] + prefix + new_content_block + "\n" + content[insert_index:]
            else: # Should not happen if file is created by this script or follows format
                print(f"Warning: '{log_section_marker}' not found in {obsidian_file_path}. Appending to end.")
                updated_content = content + "\n" + new_content_block + "\n"

            f.seek(0)
            f.write(updated_content)
            f.truncate()
        print(f"Updated Obsidian note: {obsidian_file_path}")

def main():
    if len(sys.argv) < 2:
        print("Usage: python transcription_aggregation_obsidian.py <path_to_meta.json>")
        sys.exit(1)

    meta_json_path = sys.argv[1]
    if not os.path.exists(meta_json_path):
        print(f"Error: meta.json file not found at {meta_json_path}")
        sys.exit(1)

    transcription_details = parse_meta_json(meta_json_path)
    if not transcription_details:
        sys.exit(1)

    obsidian_filename = f"{transcription_details['yyyymmdd']}-{transcription_details['day_abbr']}-transcriptions.md"
    obsidian_file_path = os.path.join(OBSIDIAN_VAULT_BASE_PATH, transcription_details['yyyy_mm'], obsidian_filename)

    new_content_block, log_entry_header = create_obsidian_content(transcription_details)
    if new_content_block and log_entry_header:
        update_obsidian_file(transcription_details, obsidian_file_path, new_content_block, log_entry_header)
    else:
        print("Failed to generate content block.")

if __name__ == "__main__":
    main()
