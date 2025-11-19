#!/usr/bin/env python3

"""
Automatic Version Bumper

This script is designed to be run in a GitHub Action.
It compares the PR branch with its base branch, finds modified
container image directories, and bumps their 'VERSION' file
based on conventional commit messages.

It respects manual bumps: if a user manually bumps a version
(or creates a new one), the script skips automation for that file.

Requires 'semver' library: pip install semver
"""

import os
import re
import subprocess
import sys
from pathlib import Path
from enum import IntEnum

# --- Constants ---

# Conventional Commit regex patterns
# We look for the scope matching the directory name
MAJOR_REGEX = r"(feat|fix)\((.+)\)!:"
BREAKING_REGEX = r"BREAKING CHANGE"
MINOR_REGEX = r"feat\((.+)\):"
PATCH_REGEX = r"fix\((.+)\):"

# --- Enums for Bump Logic ---

class BumpLevel(IntEnum):
    NONE = 0
    PATCH = 1
    MINOR = 2
    MAJOR = 3

    def __gt__(self, other):
        if self.__class__ is other.__class__:
            return self.value > other.value
        return NotImplemented


# --- Git Helper Functions ---

def run_git_command(cmd: list[str], allow_error: bool = False) -> str:
    """Runs a git command and returns its stdout."""
    try:
        result = subprocess.run(
            ["git"] + cmd,
            capture_output=True,
            text=True,
            check=True,
            encoding="utf-8",
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        if allow_error:
            raise e
        print(f"Error running git command: {' '.join(cmd)}", file=sys.stderr)
        print(f"STDERR: {e.stderr}", file=sys.stderr)
        sys.exit(1)


def get_changed_files(base_ref: str, head_ref: str, directory: Path) -> list[str]:
    """Get a list of non-documentation files changed in a directory."""
    cmd = ["diff", "--name-only", base_ref, head_ref, "--", str(directory)]
    all_files = run_git_command(cmd).splitlines()
    
    # Filter out documentation files
    return [
        f for f in all_files 
        if not (f.endswith(".md") or f.endswith("README.md"))
    ]


def get_commit_logs(base_ref: str, head_ref: str, directory: Path) -> str:
    """Get all commit messages that touched a given directory."""
    delimiter = "----COMMIT-DELIMITER----"
    cmd = [
        "log",
        f"{base_ref}..{head_ref}",
        f"--pretty=format:%B%n%n{delimiter}",
        "--",
        str(directory),
    ]
    return run_git_command(cmd)

def get_base_version(base_ref: str, version_file: Path) -> str:
    """Get the version from the base branch.
    If the file doesn't exist, return '0.0.0'.
    """
    try:
        # We pass allow_error=True so the script doesn't sys.exit(1)
        # if the file doesn't exist on the base branch.
        return run_git_command(["show", f"{base_ref}:{version_file}"], allow_error=True)
    except subprocess.CalledProcessError:
        # This will happen if the file is new in this PR
        print(f"File {version_file} not found on base branch. Assuming 0.0.0")
        return "0.0.0"

# --- Main Logic ---

def main():
    try:
        import semver
    except ImportError:
        print("Error: 'semver' library not found.", file=sys.stderr)
        print("Please install it: pip install semver", file=sys.stderr)
        sys.exit(1)

    base_ref = os.environ.get("BASE_REF")
    head_ref = os.environ.get("HEAD_REF")

    if not base_ref or not head_ref:
        print("Error: BASE_REF and HEAD_REF env variables are required.", file=sys.stderr)
        sys.exit(1)

    print(f"Checking for bumps between {base_ref} and {head_ref}...\n")
    
    root = Path(".")
    image_dirs = [
        p.parent
        for p in root.glob("*/VERSION")
        if (p.parent / "Containerfile").exists()
    ]
    
    commit_made = False

    for directory in image_dirs:
        scope = directory.name
        version_file = directory / "VERSION"
        print(f"--- Processing: {scope} ---")

        changed_files = get_changed_files(base_ref, head_ref, directory)

        # CRITICAL FIX: Check for manual version changes first
        # changed_files contains paths relative to root (e.g. "dir/VERSION")
        if str(version_file) in changed_files:
            print(f"Manual change to {version_file} detected. Skipping autobump.")
            continue

        if not changed_files:
            print("No non-documentation changes found. Skipping.")
            continue

        print(f"Found {len(changed_files)} changed file(s): {changed_files[0]}...")

        # 2. Find the highest bump level from commits
        highest_bump = BumpLevel.NONE
        raw_logs = get_commit_logs(base_ref, head_ref, directory)
        commits = raw_logs.split("----COMMIT-DELIMITER----")

        for commit_msg in commits:
            if not commit_msg:
                continue

            if (
                re.search(MAJOR_REGEX, commit_msg, re.M)
                or re.search(BREAKING_REGEX, commit_msg, re.M)
            ):
                if re.search(f"(feat|fix)\({scope}\)!:", commit_msg) or re.search(BREAKING_REGEX, commit_msg, re.M):
                   highest_bump = BumpLevel.MAJOR
                
            if highest_bump < BumpLevel.MAJOR:
                if re.search(f"feat\({scope}\):", commit_msg):
                    highest_bump = max(highest_bump, BumpLevel.MINOR)
            
            if highest_bump < BumpLevel.MINOR:
                if re.search(f"fix\({scope}\):", commit_msg):
                    highest_bump = max(highest_bump, BumpLevel.PATCH)

        if highest_bump == BumpLevel.NONE:
            print("No conventional commits found. Skipping.")
            continue

        print(f"Found highest bump type: {highest_bump.name}")

        # 3. Get versions
        try:
            base_version_str = get_base_version(base_ref, version_file)
            base_v = semver.VersionInfo.parse(base_version_str)
            
            pr_version_str = version_file.read_text().strip()
            pr_v = semver.VersionInfo.parse(pr_version_str)
        except (ValueError, FileNotFoundError) as e:
            print(f"Error parsing version for {scope}: {e}", file=sys.stderr)
            continue
        
        # 4. Calculate target version
        if highest_bump == BumpLevel.MAJOR:
            target_v = base_v.bump_major()
        elif highest_bump == BumpLevel.MINOR:
            target_v = base_v.bump_minor()
        else: 
            target_v = base_v.bump_patch()

        print(f"Base: {base_v} | PR: {pr_v} | Target: {target_v}")

        # 5. Compare and write file
        if pr_v < target_v:
            print(f"Bumping {scope}: {pr_v} -> {target_v}")
            version_file.write_text(f"{target_v}\n")
            commit_made = True
        elif pr_v > target_v:
            print(f"Respecting manual bump: PR version {pr_v} > target {target_v}")
        else:
            print(f"Version {pr_v} is already correct.")

    print("---")
    
    if "GITHUB_OUTPUT" in os.environ:
        with open(os.environ["GITHUB_OUTPUT"], "a") as f:
            f.write(f"commit_made={str(commit_made).lower()}\n")
    print(f"Commit made: {commit_made}")


if __name__ == "__main__":
    main()
