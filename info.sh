#!/bin/bash

# Configuration - Add patterns to exclude (space-separated)
EXCLUDE_PATTERNS=(".git node_modules .next old *.gitignore .deprecated backups project-info.md info info.sh shell.sh prompt commands")

# Output file
OUTPUT_FILE="project-info.md"

# Create exclude pattern string for tree command
EXCLUDE=""
for pattern in $EXCLUDE_PATTERNS; do
    EXCLUDE="$EXCLUDE -I $pattern"
done

# Generate timestamp
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Function to format dependencies from package.json
format_dependencies() {
    local deps="$1"
    echo "$deps" | jq -r 'to_entries | .[] | "    * \"" + .key + "\": \"" + .value + "\""'
}

# Read dependencies from package.json
if [ -f "package.json" ]; then
    DEPENDENCIES=$(jq '.dependencies' package.json)
    DEV_DEPENDENCIES=$(jq '.devDependencies' package.json)
else
    echo "Error: package.json not found!"
    exit 1
fi

# Create the output file with header and project information
cat > "$OUTPUT_FILE" << EOF
# Mikrotik Hotspot Auth UI
Generated on: $TIMESTAMP

## Project Information
* Name: Mikrotik Hotspot Auth UI & Landing Page
* Description: A user interface for Mikrotik RouterOS Hotspot authentication and landing page after login.
* Author: Essam Barghsh
* Language: Javascript, CSS, HTML

## System Information & Additional information
* My operating system: Ubuntu
* Code Editor: Visual Studio Code

## Directory Structure
\`\`\`
EOF

# Generate tree structure and append to file
tree -a -L 32 --dirsfirst $EXCLUDE >> "$OUTPUT_FILE"

# Close the code block
echo "\`\`\`" >> "$OUTPUT_FILE"

echo "Project Information has been generated in $OUTPUT_FILE"