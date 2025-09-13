# Messenger Cleanup Script

This Python script analyzes `StandardMessenger.swift` to help maintain clean, organized code by:

1. **Finding unused functions** - Scans the entire codebase to identify functions that are never called
2. **Removing unused functions** - Optionally removes functions that aren't used anywhere
3. **Alphabetizing functions** - Sorts remaining functions alphabetically for better organization
4. **Maintaining formatting** - Preserves documentation, proper spacing, and Swift conventions

## Requirements

- Python 3.6+
- Swift project with `StandardMessenger.swift` file
- Optional: `swift-format` for automatic code formatting

## Usage

### Basic Analysis (Dry Run)

```bash
# Just analyze and show what would be done
python3 Scripts/messenger_cleanup.py --dry-run
```

This will:
- Show total function count
- List all unused functions
- Show what changes would be made
- **Make no actual changes**

### Alphabetize Functions Only

```bash
# Sort functions alphabetically but keep all functions
python3 Scripts/messenger_cleanup.py
```

This will:
- Keep all functions (even unused ones)
- Sort them alphabetically
- Create a backup of the original file
- Update `StandardMessenger.swift`

### Remove Unused Functions and Alphabetize

```bash
# Remove unused functions AND sort alphabetically
python3 Scripts/messenger_cleanup.py --remove-unused
```

This will:
- Remove functions that are never called
- Sort remaining functions alphabetically
- Create a backup of the original file
- Update `StandardMessenger.swift`

### Advanced Options

```bash
# Specify custom project root
python3 Scripts/messenger_cleanup.py --project-root /path/to/project

# Combine options
python3 Scripts/messenger_cleanup.py --remove-unused --dry-run --project-root /path/to/project
```

## How It Works

### Function Detection

The script parses `StandardMessenger.swift` and extracts:
- Function names and signatures
- Complete function bodies
- Associated documentation comments
- Line numbers and positions

### Usage Analysis

For each function, the script searches the entire codebase for usage patterns:
- `messenger.functionName(`
- `context.msg.functionName(`
- `.functionName(`
- `functionName(`

Search locations include:
- `Sources/` directory (all Swift files)
- `Tests/` directory (all Swift files)
- `Executables/` directory (all Swift files)

### Safe Backup System

Before making any changes, the script:
1. Creates a backup file (`StandardMessenger.swift.backup`)
2. Only modifies the original after successful analysis
3. Preserves all documentation and formatting

## Example Output

```
🔍 Project root: /Users/dev/MyProject
📖 Extracting functions from StandardMessenger.swift...
   Found 392 functions
Analyzing function usage...
  Checking allCommandNothingHere... used in 2 location(s)
  Checking almostDo... UNUSED
  Checking already... used in 5 location(s)
  ...

📊 ANALYSIS SUMMARY
==================================================
Total functions: 392
Used functions: 387
Unused functions: 5

🗑️  UNUSED FUNCTIONS:
  - almostDo
  - obsoleteFunction1
  - oldDeprecatedMethod
  - testOnlyFunction
  - unusedHelper

🔧 Generating cleaned file...
💾 Backup created: StandardMessenger.swift.backup
✅ StandardMessenger.swift updated
   Functions are now alphabetically sorted
   Removed 5 unused functions
🎨 Code formatted with swift-format
```

## Safety Features

- **Automatic backups** - Original file is always backed up
- **Dry run mode** - Test changes without modifying files
- **Comprehensive analysis** - Searches entire codebase for usage
- **Preserves documentation** - Maintains all `///` comments and formatting
- **Error handling** - Graceful failure with helpful error messages

## Integration with Development Workflow

### Regular Cleanup (Recommended)

```bash
# Monthly cleanup - just analyze
python3 Scripts/messenger_cleanup.py --dry-run

# If satisfied with analysis, apply changes
python3 Scripts/messenger_cleanup.py --remove-unused
```

### Pre-commit Hook

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash
python3 Scripts/messenger_cleanup.py --dry-run
if [ $? -ne 0 ]; then
    echo "Messenger cleanup analysis failed"
    exit 1
fi
```

### CI/CD Integration

```yaml
# In GitHub Actions or similar
- name: Check messenger cleanliness
  run: python3 Scripts/messenger_cleanup.py --dry-run
```

## Troubleshooting

### "Package.swift not found"

The script auto-detects the project root by looking for `Package.swift`. If it can't find it:

```bash
python3 Scripts/messenger_cleanup.py --project-root /path/to/your/project
```

### "StandardMessenger.swift not found"

Ensure the file exists at:
```
Sources/GnustoEngine/Messenger/StandardMessenger.swift
```

### False Positives

If a function is marked as unused but you know it's used:
1. Check if it's called via reflection or dynamic dispatch
2. Verify the function name matches exactly (case-sensitive)
3. Check if it's used in build scripts or code generation

### Swift Format Issues

If `swift-format` is not available, the script will still work but won't auto-format. Install it with:

```bash
# Using Homebrew
brew install swift-format

# Or build from source
git clone https://github.com/apple/swift-format.git
cd swift-format
swift build -c release
```

## Contributing

To improve the script:
1. Add new search patterns for function usage
2. Enhance documentation preservation
3. Add support for other file types
4. Improve error handling and reporting

## Notes

- The script is conservative - it only removes functions with zero detected usage
- Documentation comments (`///`) are preserved and associated with their functions
- Function signatures and return types are maintained exactly
- The script handles complex multi-line function signatures correctly
