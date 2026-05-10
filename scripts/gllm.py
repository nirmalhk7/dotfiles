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
    files: list[str]

class CommitList(BaseModel):
    commits: list[Commit]

def get_git_diff():
    # Get all changes (staged and unstaged)
    try:
        # Check if we are in a git repo
        subprocess.run(["git", "rev-parse", "--is-inside-work-tree"], check=True, capture_output=True)
        
        # Get staged changes
        staged = subprocess.run(["git", "diff", "--cached"], capture_output=True, text=True).stdout
        # Get unstaged changes
        unstaged = subprocess.run(["git", "diff"], capture_output=True, text=True).stdout
        
        return staged + "\n" + unstaged
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
        
    diff = get_git_diff()
    if not diff.strip():
        print("No changes detected.")
        return

    client = genai.Client(api_key=api_key)
    
    # Range of models to try in order
    models_to_try = [
        'gemini-2.5-flash',
        'gemini-2.0-flash', 
        'gemini-2.0-flash-lite',
        'gemini-flash-latest',
        'gemini-pro-latest'
    ]

    prompt = f"""
    Analyze the following git diff and group the changes into logical commits.
    Rules:
    - Group changes that are related to the same feature or fix.
    - Each file can only belong to one commit in this sequential packing.
    - If a file has multiple unrelated changes, just pick the most prominent one or group it with the majority.
    - Commit messages MUST be in Commitizen format: <type>(<scope>): <description>
      Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
    
    GIT DIFF:
    {diff}
    """

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
    for i, commit in enumerate(commits):
        print(f"  {i+1}. [{commit['message']}] -> {', '.join(commit['files'])}")
    
    confirm = input("\nProceed with these commits? (Y/n): ")
    if confirm.lower() == 'n':
        print("Aborted. Falling back to manual commit.")
        fallback_commit()
        return

    print("Unstaging current changes to pack sequentially...")
    subprocess.run(["git", "reset"], capture_output=True)

    for commit in commits:
        message = commit['message']
        files = commit['files']
        
        existing_files = [f for f in files if os.path.exists(f)]
        if not existing_files:
            print(f"Skipping commit '{message}' as no files were found.")
            continue

        print(f"Committing: {message}...")
        try:
            subprocess.run(["git", "add"] + existing_files, check=True)
            subprocess.run(["git", "commit", "-S", "-m", message], check=True)
        except subprocess.CalledProcessError as e:
            print(f"Error during commit: {e}")
            print("Stopping sequence.")
            break

    print("\nDone!")

if __name__ == "__main__":
    main()
