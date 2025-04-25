#!/bin/bash

# Create temporary directory
TMP_DIR=$(mktemp -d)
echo "Created temporary directory: $TMP_DIR"

# Function to fetch and process a repository
fetch_repo() {
    local repo_url=$1
    local target_dir=$2

    echo "Fetching $target_dir..."

    # Clone to temporary directory
    git clone "$repo_url" "$TMP_DIR/$target_dir"

    # Create target directory if it doesn't exist
    mkdir -p "Docs/References/$target_dir"

    # Copy only .zil, .md, and .txt files
    find "$TMP_DIR/$target_dir" -type f \( -name "*.zil" -o -name "*.md" -o -name "*.txt" \) -exec cp {} "Docs/References/$target_dir/" \;

    echo "Processed $target_dir"
}

# Fetch repositories
fetch_repo "https://github.com/historicalsource/amfv.git" "A Mind Forever Voyaging"
fetch_repo "https://github.com/historicalsource/hitchhikersguide.git" "Hitchhikers Guide to the Galaxy"
fetch_repo "https://github.com/historicalsource/zork1.git" "Zork 1"

# Clean up temporary directory
rm -rf "$TMP_DIR"
echo "Cleaned up temporary directory"

echo "Done!"
