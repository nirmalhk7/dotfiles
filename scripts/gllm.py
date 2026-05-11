#!/usr/bin/env python3
import os
import subprocess
import json
import sys
from pathlib import Path

# Try to import dependencies
try:
    from google import genai
    from dotenv import load_dotenv
    from pydantic import BaseModel
except ImportError:
    print("Error: Missing dependencies. Please run:")
    print("pip install google-genai python-dotenv pydantic")
    sys.exit(1)

class Commit(BaseModel):
    message: str
    hunk_ids: list[int]

class CommitList(BaseModel):
    commits: list[Commit]

class Hunk:
    def __init__(self, id, file_header, hunk_header, hunk_content, filename):
        self.id = id
        self.file_header = file_header
        self.hunk_header = hunk_header
        self.hunk_content = hunk_content
        self.filename = filename

    def to_patch(self):
        return f"{self.file_header}\n{self.hunk_header}\n{self.hunk_content}\n"

import re

def parse_diff(diff_text):
    hunks = []
    current_file_header = []
    current_filename = None
    hunk_id = 1
    
    lines = diff_text.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.startswith("diff --git"):
            current_file_header = [line]
            # Match the filename in b/path/to/file
            match = re.search(r" b/(.*)", line)
            current_filename = match.group(1) if match else "unknown"
            i += 1
            while i < len(lines) and not lines[i].startswith("@@"):
                # Collect headers like --- and +++
                current_file_header.append(lines[i])
                i += 1
            continue
        
        if line.startswith("@@"):
            hunk_header = line
            hunk_content = []
            i += 1
            while i < len(lines) and not lines[i].startswith("@@") and not lines[i].startswith("diff --git"):
                hunk_content.append(lines[i])
                i += 1
            
            hunks.append(Hunk(
                id=hunk_id,
                file_header="\n".join(current_file_header),
                hunk_header=hunk_header,
                hunk_content="\n".join(hunk_content),
                filename=current_filename
            ))
            hunk_id += 1
            continue
        
        i += 1
    return hunks

def get_git_diff():
    # Get all changes (staged and unstaged) relative to HEAD
    try:
        # Check if we are in a git repo
        subprocess.run(["git", "rev-parse", "--is-inside-work-tree"], check=True, capture_output=True)
        
        # git diff HEAD includes both staged and unstaged changes of tracked files
        diff = subprocess.run(["git", "diff", "HEAD"], capture_output=True, text=True).stdout
        return diff
    except subprocess.CalledProcessError:
        print("Error: Not a git repository.")
        sys.exit(1)

def fallback_commit():
    print("\nAI analysis failed for all models. Falling back to manual commit (git commit -as)...")
    try:
        # Use git commit -as as requested
        subprocess.run(["git", "commit", "-as"], check=False)
    except Exception as e:
        print(f"Manual commit failed: {e}")

def main():
    # Load .env from the script's directory (dotfiles root)
    script_path = Path(__file__).resolve()
    dotfiles_root = script_path.parent.parent
    env_path = dotfiles_root / ".env"
    
    load_dotenv(env_path)
    
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        print(f"Error: GEMINI_API_KEY not found in {env_path}")
        sys.exit(1)
        
    diff_text = get_git_diff()
    if not diff_text.strip():
        print("No changes detected.")
        return

    hunks = parse_diff(diff_text)
    if not hunks:
        print("No parseable hunks found.")
        return

    client = genai.Client(api_key=api_key)
    
    # Format hunks for the prompt
    hunks_formatted = ""
    for h in hunks:
        hunks_formatted += f"--- HUNK {h.id} (File: {h.filename}) ---\n{h.hunk_header}\n{h.hunk_content}\n\n"

    prompt = f"""
    Analyze the following git diff hunks and group them into logical commits.
    Rules:
    - Group hunks that are related to the same feature or fix.
    - Each hunk ID MUST belong to exactly one commit.
    - Commit messages MUST be in Commitizen format: <type>(<scope>): <description>
      Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
    
    GIT DIFF HUNKS:
    {hunks_formatted}
    """

    # Range of models to try in order
    models_to_try = [
        'gemini-2.5-flash',
        'gemini-2.0-flash', 
        'gemini-2.0-flash-lite',
        'gemini-flash-latest',
        'gemini-pro-latest'
    ]

    commits = None
    for model_name in models_to_try:
        print(f"Trying model: {model_name}...")
        try:
            response = client.models.generate_content(
                model=model_name,
                contents=prompt,
                config={
                    "response_mime_type": "application/json",
                    "response_schema": CommitList,
                }
            )
            # The new SDK parses the JSON automatically if schema is provided
            # and returns it in a structured way if possible, or we can use .text
            if response.text:
                data = json.loads(response.text)
                if 'commits' in data:
                    commits = data['commits']
                    break
        except Exception as e:
            # Check for 404 (model not found) or Quota issues
            error_msg = str(e)
            if "404" in error_msg or "not found" in error_msg.lower():
                print(f"  Model {model_name} not available.")
            elif "429" in error_msg or "quota" in error_msg.lower():
                print(f"  Quota exceeded for {model_name}.")
            else:
                print(f"  Error with {model_name}: {error_msg}")
            continue

    if not commits:
        fallback_commit()
        return

    print(f"\nProposed {len(commits)} commits:")
    hunk_map = {h.id: h for h in hunks}
    for i, commit in enumerate(commits):
        affected_files = sorted(list(set(hunk_map[hid].filename for hid in commit['hunk_ids'] if hid in hunk_map)))
        print(f"  {i+1}. [{commit['message']}] -> hunks: {commit['hunk_ids']} ({', '.join(affected_files)})")
    
    confirm = input("\nProceed with these commits? (Y/n): ")
    if confirm.lower() == 'n':
        print("Aborted. Falling back to manual commit.")
        fallback_commit()
        return

    print("Unstaging current changes to pack sequentially...")
    subprocess.run(["git", "reset"], capture_output=True)

    for commit in commits:
        message = commit['message']
        hunk_ids = commit['hunk_ids']
        
        selected_hunks = [hunk_map[hid] for hid in hunk_ids if hid in hunk_map]
        if not selected_hunks:
            print(f"Skipping commit '{message}' as no valid hunks were found.")
            continue

        print(f"Committing: {message}...")
        
        # Create patch text
        patch_text = "".join(h.to_patch() for h in selected_hunks)
        
        try:
            # Apply patch to index
            process = subprocess.Popen(["git", "apply", "--cached", "-"], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            stdout, stderr = process.communicate(input=patch_text)
            
            if process.returncode != 0:
                print(f"Error: Failed to apply patch for hunk(s) {hunk_ids}")
                print(stderr)
                # Try to apply with --recount or --3way if available? For now, just fail.
                print("Stopping sequence.")
                break
                
            subprocess.run(["git", "commit", "-s", "-m", message], check=True)
        except subprocess.CalledProcessError as e:
            print(f"Error during commit: {e}")
            print("Stopping sequence.")
            break

    print("\nDone!")

if __name__ == "__main__":
    main()
