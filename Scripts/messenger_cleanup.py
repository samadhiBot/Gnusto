#!/usr/bin/env python3
"""
Messenger Cleanup Script

This script analyzes StandardMessenger.swift to:
1. Find unused functions across the entire codebase
2. Optionally remove unused functions
3. Alphabetize remaining functions
4. Maintain proper Swift formatting and documentation

Usage:
    python messenger_cleanup.py [--remove-unused] [--dry-run]
"""

import os
import re
import sys
import argparse
from pathlib import Path
from typing import List, Dict, Tuple, Set
import subprocess

class MessengerAnalyzer:
    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.messenger_file = project_root / "Sources/GnustoEngine/Messenger/StandardMessenger.swift"
        self.functions: Dict[str, Dict] = {}
        self.unused_functions: Set[str] = set()

    def extract_functions(self) -> Dict[str, Dict]:
        """Extract all function definitions from StandardMessenger.swift"""
        if not self.messenger_file.exists():
            raise FileNotFoundError(f"StandardMessenger.swift not found at {self.messenger_file}")

        with open(self.messenger_file, 'r', encoding='utf-8') as f:
            content = f.read()

        functions = {}
        lines = content.split('\n')
        i = 0

        while i < len(lines):
            # Look for function definitions (handle access modifiers)
            func_match = re.match(r'\s*(?:open\s+|public\s+|private\s+|internal\s+)?func\s+(\w+)\s*\(', lines[i])
            if func_match:
                func_name = func_match.group(1)

                # Look for documentation comments above the function
                doc_start = i
                while doc_start > 0 and lines[doc_start - 1].strip().startswith('///'):
                    doc_start -= 1

                # Collect function lines starting from documentation
                func_lines = []
                for doc_idx in range(doc_start, i):
                    func_lines.append(lines[doc_idx])

                # Add the function signature and body
                j = i
                brace_count = 0
                function_started = False

                while j < len(lines):
                    current_line = lines[j]
                    func_lines.append(current_line)

                    # Track braces
                    if '{' in current_line:
                        function_started = True
                        brace_count += current_line.count('{')

                    if function_started:
                        brace_count -= current_line.count('}')

                        # Function complete when braces are balanced
                        if brace_count == 0:
                            break

                    j += 1

                    # Safety check
                    if j - i > 50:
                        break

                functions[func_name] = {
                    'name': func_name,
                    'lines': func_lines,
                    'start_line': doc_start + 1,
                    'end_line': j + 1,
                    'content': '\n'.join(func_lines)
                }

                i = j + 1
            else:
                i += 1

        self.functions = functions
        return functions

    def find_function_usage(self, func_name: str) -> List[str]:
        """Find all usages of a function across the codebase"""
        usage_locations = []

        # Search patterns - function could be called as:
        # - messenger.funcName(
        # - context.msg.funcName(
        # - .funcName(
        # - funcName(
        patterns = [
            rf'\.\s*{func_name}\s*\(',
            rf'\b{func_name}\s*\(',
            rf'messenger\s*\.\s*{func_name}\s*\(',
            rf'msg\s*\.\s*{func_name}\s*\('
        ]

        # Directories to search
        search_dirs = [
            self.project_root / "Sources",
            self.project_root / "Tests",
            self.project_root / "Executables"
        ]

        for search_dir in search_dirs:
            if not search_dir.exists():
                continue

            for swift_file in search_dir.rglob("*.swift"):
                # Skip the StandardMessenger.swift file itself
                if swift_file.name == "StandardMessenger.swift":
                    continue

                try:
                    with open(swift_file, 'r', encoding='utf-8') as f:
                        content = f.read()

                    for pattern in patterns:
                        matches = re.finditer(pattern, content, re.MULTILINE)
                        for match in matches:
                            # Get line number
                            line_num = content[:match.start()].count('\n') + 1
                            usage_locations.append(f"{swift_file.relative_to(self.project_root)}:{line_num}")

                except Exception as e:
                    print(f"Error reading {swift_file}: {e}")

        return usage_locations

    def find_unused_functions(self) -> Set[str]:
        """Find functions that are never called"""
        unused = set()

        print("Analyzing function usage...")
        for func_name in self.functions:
            print(f"  Checking {func_name}...", end='')
            usages = self.find_function_usage(func_name)
            if not usages:
                unused.add(func_name)
                print(" UNUSED")
            else:
                print(f" used in {len(usages)} location(s)")

        self.unused_functions = unused
        return unused

    def generate_cleaned_file(self, remove_unused: bool = False) -> str:
        """Generate the cleaned up StandardMessenger.swift content"""
        if not self.functions:
            self.extract_functions()

        # Read the original file to get the class header and other content
        with open(self.messenger_file, 'r', encoding='utf-8') as f:
            original_content = f.read()

        # Extract the class header (everything before the first function)
        lines = original_content.split('\n')
        header_lines = []

        for i, line in enumerate(lines):
            if re.match(r'\s*(?:open\s+|public\s+|private\s+|internal\s+)?func\s+\w+\s*\(', line):
                break
            header_lines.append(line)

        # Get functions to keep
        functions_to_keep = {}
        for func_name, func_data in self.functions.items():
            if not remove_unused or func_name not in self.unused_functions:
                functions_to_keep[func_name] = func_data

        # Sort functions alphabetically by name
        sorted_function_names = sorted(functions_to_keep.keys())

        # Build the new file content
        result_lines = header_lines.copy()

        # Add sorted functions
        for i, func_name in enumerate(sorted_function_names):
            func_data = functions_to_keep[func_name]

            # Add a blank line before each function (except the first)
            if i > 0:
                result_lines.append('')

            result_lines.extend(func_data['lines'])

        # Find and add the closing brace from the original file
        for line in reversed(lines):
            if line.strip() == '}' and not re.match(r'\s*(?:open\s+|public\s+|private\s+|internal\s+)?func\s+', line):
                result_lines.append('')  # Add blank line before closing brace
                result_lines.append(line)
                break

        return '\n'.join(result_lines)

    def print_summary(self):
        """Print analysis summary"""
        total_functions = len(self.functions)
        unused_count = len(self.unused_functions)
        used_count = total_functions - unused_count

        print(f"\n📊 ANALYSIS SUMMARY")
        print(f"{'='*50}")
        print(f"Total functions: {total_functions}")
        print(f"Used functions: {used_count}")
        print(f"Unused functions: {unused_count}")

        if self.unused_functions:
            print(f"\n🗑️  UNUSED FUNCTIONS:")
            for func_name in sorted(self.unused_functions):
                print(f"  - {func_name}")

    def backup_file(self) -> Path:
        """Create a backup of the original file"""
        backup_path = self.messenger_file.with_suffix('.swift.backup')
        import shutil
        shutil.copy2(self.messenger_file, backup_path)
        return backup_path

def main():
    parser = argparse.ArgumentParser(description='Clean up StandardMessenger.swift')
    parser.add_argument('--remove-unused', action='store_true',
                       help='Remove unused functions (default: keep all functions)')
    parser.add_argument('--dry-run', action='store_true',
                       help='Show what would be done without making changes')
    parser.add_argument('--project-root', type=Path,
                       help='Path to project root (default: auto-detect)')

    args = parser.parse_args()

    # Find project root
    if args.project_root:
        project_root = args.project_root
    else:
        # Auto-detect by finding Package.swift
        current_dir = Path.cwd()
        while current_dir != current_dir.parent:
            if (current_dir / "Package.swift").exists():
                project_root = current_dir
                break
            current_dir = current_dir.parent
        else:
            print("❌ Could not find project root (Package.swift not found)")
            sys.exit(1)

    print(f"🔍 Project root: {project_root}")

    try:
        analyzer = MessengerAnalyzer(project_root)

        # Extract functions
        print("📖 Extracting functions from StandardMessenger.swift...")
        analyzer.extract_functions()
        print(f"   Found {len(analyzer.functions)} functions")

        # Find unused functions
        unused_functions = analyzer.find_unused_functions()

        # Print summary
        analyzer.print_summary()

        # Generate cleaned content
        print("\n🔧 Generating cleaned file...")
        cleaned_content = analyzer.generate_cleaned_file(remove_unused=args.remove_unused)

        if args.dry_run:
            print("\n🔍 DRY RUN - No changes made")
            print("📝 Cleaned file would contain:")
            remaining_functions = [name for name in analyzer.functions.keys()
                                 if not args.remove_unused or name not in unused_functions]
            print(f"   {len(remaining_functions)} functions (alphabetically sorted)")
            if args.remove_unused and unused_functions:
                print(f"   {len(unused_functions)} unused functions would be removed")
        else:
            # Create backup
            backup_path = analyzer.backup_file()
            print(f"💾 Backup created: {backup_path}")

            # Write cleaned file
            with open(analyzer.messenger_file, 'w', encoding='utf-8') as f:
                f.write(cleaned_content)

            print(f"✅ StandardMessenger.swift updated")
            print(f"   Functions are now alphabetically sorted")
            if args.remove_unused and unused_functions:
                print(f"   Removed {len(unused_functions)} unused functions")

            # Format with swift-format if available
            try:
                subprocess.run(['swift-format', '--in-place', str(analyzer.messenger_file)],
                             check=True, capture_output=True)
                print("🎨 Code formatted with swift-format")
            except (subprocess.CalledProcessError, FileNotFoundError):
                print("ℹ️  swift-format not available - manual formatting may be needed")

    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
