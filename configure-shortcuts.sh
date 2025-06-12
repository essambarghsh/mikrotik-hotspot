#!/bin/bash

# Mikrotik Hotspot Shortcuts Configurator
# Reads JSON shortcut data and updates HTML files

set -e  # Exit on any error

# Configuration
SHORTCUTS_FILE="shortcuts.json"
DEFAULT_TARGET_FILE="alogin.html"
TARGET_FILE=""
BACKUP_DIR="backups"
LIMIT_COUNT=""  # New: limit number of items to process

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if jq is installed
check_dependencies() {
    if ! command -v jq &> /dev/null; then
        print_error "jq is required but not installed. Please install jq first:"
        echo "  Ubuntu/Debian: sudo apt-get install jq"
        echo "  CentOS/RHEL: sudo yum install jq"
        echo "  macOS: brew install jq"
        exit 1
    fi
    
    if ! command -v python3 &> /dev/null; then
        print_error "python3 is required but not installed."
        exit 1
    fi
}

# Create backup directory if it doesn't exist
create_backup_dir() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        mkdir -p "$BACKUP_DIR"
        print_status "Created backup directory: $BACKUP_DIR"
    fi
}

# Check if shortcuts.json exists
check_shortcuts_file() {
    if [[ ! -f "$SHORTCUTS_FILE" ]]; then
        print_error "Shortcuts file '$SHORTCUTS_FILE' not found!"
        echo
        echo "Please create a shortcuts.json file with this structure:"
        echo '{'
        echo '  "shortcuts": ['
        echo '    {'
        echo '      "name": "Google",'
        echo '      "url": "https://www.google.com",'
        echo '      "icon": "img/sites/logos--google-icon.png",'
        echo '      "target": "_blank",'
        echo '      "delay": 600'
        echo '    }'
        echo '  ]'
        echo '}'
        exit 1
    fi
}

# Validate JSON structure
validate_json() {
    print_status "Validating JSON structure..."
    
    if ! jq empty "$SHORTCUTS_FILE" 2>/dev/null; then
        print_error "Invalid JSON in $SHORTCUTS_FILE"
        exit 1
    fi
    
    # Check required fields
    if ! jq -e '.shortcuts | type == "array"' "$SHORTCUTS_FILE" > /dev/null; then
        print_error "JSON must contain 'shortcuts' array"
        exit 1
    fi
    
    # Validate each shortcut has required fields
    local total_shortcuts=$(jq '.shortcuts | length' "$SHORTCUTS_FILE")
    if [[ $total_shortcuts -eq 0 ]]; then
        print_error "No shortcuts found in $SHORTCUTS_FILE"
        exit 1
    fi
    
    # Determine how many shortcuts to validate based on limit
    local validate_count=$total_shortcuts
    if [[ -n "$LIMIT_COUNT" ]]; then
        validate_count=$(( LIMIT_COUNT < total_shortcuts ? LIMIT_COUNT : total_shortcuts ))
        print_status "Validating first $validate_count of $total_shortcuts shortcuts (limit applied)" >&2
    fi
    
    for ((i=0; i<validate_count; i++)); do
        local shortcut=$(jq ".shortcuts[$i]" "$SHORTCUTS_FILE")
        
        # Check required fields
        if ! echo "$shortcut" | jq -e 'has("name") and has("url") and has("icon")' > /dev/null; then
            print_error "Shortcut $((i+1)) missing required fields (name, url, icon)"
            exit 1
        fi
    done
    
    print_success "JSON validation passed"
}

# Generate HTML for a single shortcut
generate_shortcut_html() {
    local shortcut_json="$1"
    local name=$(echo "$shortcut_json" | jq -r '.name')
    local url=$(echo "$shortcut_json" | jq -r '.url')
    local icon=$(echo "$shortcut_json" | jq -r '.icon')
    local target=$(echo "$shortcut_json" | jq -r '.target // "_blank"')
    local delay=$(echo "$shortcut_json" | jq -r '.delay')
    
    cat << EOF
                        <div class="shortcut" data-aos="fade-up" data-aos-delay="$delay">
                            <a href="$url" target="$target" title="$name">
                                <img src="$icon" alt="$name">
                                <span class="sr-only">$name</span>
                            </a>
                        </div>
EOF
}

# Generate all shortcuts HTML
generate_all_shortcuts_html() {
    local total_shortcuts=$(jq '.shortcuts | length' "$SHORTCUTS_FILE")
    local shortcut_count=$total_shortcuts
    local auto_delay=600  # Starting delay value
    
    # Apply limit if specified
    if [[ -n "$LIMIT_COUNT" ]]; then
        shortcut_count=$(( LIMIT_COUNT < total_shortcuts ? LIMIT_COUNT : total_shortcuts ))
        print_status "Generating $shortcut_count of $total_shortcuts shortcuts (limit applied)" >&2
    fi
    
    for ((i=0; i<shortcut_count; i++)); do
        local shortcut=$(jq ".shortcuts[$i]" "$SHORTCUTS_FILE")
        
        # Check if delay is specified in JSON
        local has_custom_delay=$(echo "$shortcut" | jq 'has("delay")')
        
        if [[ "$has_custom_delay" == "true" ]]; then
            # Use custom delay from JSON
            generate_shortcut_html "$shortcut"
        else
            # Add auto-incremented delay to shortcut object
            local shortcut_with_delay=$(echo "$shortcut" | jq --arg delay "$auto_delay" '. + {delay: ($delay | tonumber)}')
            generate_shortcut_html "$shortcut_with_delay"
        fi
        
        # Increment auto delay for next shortcut
        auto_delay=$((auto_delay + 100))
    done
}

# Backup original file
backup_target_file() {
    if [[ -f "$TARGET_FILE" ]]; then
        local timestamp=$(date "+%Y%m%d_%H%M%S")
        local filename=$(basename "$TARGET_FILE")
        local backup_file="${BACKUP_DIR}/${filename}.${timestamp}.backup"
        
        print_status "Creating backup: $backup_file"
        cp "$TARGET_FILE" "$backup_file"
        
        # Keep only the last 10 backups for this file
        local file_backups=$(ls -1t "${BACKUP_DIR}/${filename}."*.backup 2>/dev/null | tail -n +11)
        if [[ -n "$file_backups" ]]; then
            print_status "Cleaning old backups..."
            echo "$file_backups" | xargs rm -f
        fi
    else
        print_error "Target file '$TARGET_FILE' not found!"
        exit 1
    fi
}

# Update target file with new shortcuts
update_target_file() {
    local new_shortcuts_html="$1"
    
    print_status "Updating $TARGET_FILE..."
    
    # Check if the shortcuts div exists
    if ! grep -q 'id="shortcuts"' "$TARGET_FILE"; then
        print_error "Could not find element with id='shortcuts' in $TARGET_FILE"
        echo "Make sure your HTML file contains: <div class=\"shortcuts\" id=\"shortcuts\">"
        exit 1
    fi
    
    # Create a temporary file to write the new content
    local temp_file="${TARGET_FILE}.tmp"
    
    # Use Python to properly handle the nested HTML replacement
    cat > replace_shortcuts.py << 'PYTHON_SCRIPT'
import sys

# Read the original file
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Get the new shortcuts HTML from argument
new_shortcuts = sys.argv[2]

# Find the shortcuts div and replace its contents
in_shortcuts_div = False
div_count = 0
result_lines = []

for line in lines:
    if 'class="shortcuts" id="shortcuts"' in line:
        # Found the opening div, add it and the new content
        result_lines.append(line)
        result_lines.append(new_shortcuts + '\n')
        in_shortcuts_div = True
        div_count = 1
    elif in_shortcuts_div:
        # Count div tags to find the matching closing tag
        div_count += line.count('<div')
        div_count -= line.count('</div>')
        
        # When div_count reaches 0, we found the closing tag
        if div_count == 0:
            result_lines.append(line)
            in_shortcuts_div = False
        # Skip all lines inside the shortcuts div (don't add them)
    else:
        # Outside shortcuts div, add the line normally
        result_lines.append(line)

# Write the result
for line in result_lines:
    print(line, end='')
PYTHON_SCRIPT

    # Run the Python script
    python3 replace_shortcuts.py "$TARGET_FILE" "$new_shortcuts_html" > "$temp_file"
    
    # Check if Python script succeeded
    if [[ $? -eq 0 ]]; then
        mv "$temp_file" "$TARGET_FILE"
        rm -f replace_shortcuts.py
        print_success "Successfully updated $TARGET_FILE"
    else
        print_error "Failed to update $TARGET_FILE"
        rm -f "$temp_file" replace_shortcuts.py
        exit 1
    fi
}

# Display summary
show_summary() {
    local total_shortcuts=$(jq '.shortcuts | length' "$SHORTCUTS_FILE")
    local processed_shortcuts=$total_shortcuts
    local auto_delay=600  # Starting delay value
    
    # Calculate processed shortcuts based on limit
    if [[ -n "$LIMIT_COUNT" ]]; then
        processed_shortcuts=$(( LIMIT_COUNT < total_shortcuts ? LIMIT_COUNT : total_shortcuts ))
    fi
    
    print_success "Shortcuts configuration completed!"
    echo
    echo "Summary:"
    echo "  • Shortcuts processed: $processed_shortcuts of $total_shortcuts"
    if [[ -n "$LIMIT_COUNT" ]]; then
        echo "  • Limit applied: $LIMIT_COUNT"
    fi
    echo "  • Target file: $TARGET_FILE"
    echo "  • Backup location: $BACKUP_DIR/"
    echo "  • Source file: $SHORTCUTS_FILE"
    echo "  • Auto-delay increment: 100ms (starting at 600ms)"
    echo
    print_status "Shortcut details:"
    
    for ((i=0; i<processed_shortcuts; i++)); do
        local shortcut=$(jq ".shortcuts[$i]" "$SHORTCUTS_FILE")
        local name=$(echo "$shortcut" | jq -r '.name')
        local url=$(echo "$shortcut" | jq -r '.url')
        local has_custom_delay=$(echo "$shortcut" | jq 'has("delay")')
        
        if [[ "$has_custom_delay" == "true" ]]; then
            local delay=$(echo "$shortcut" | jq -r '.delay')
            echo "  • $name - $url (delay: ${delay}ms - custom)"
        else
            echo "  • $name - $url (delay: ${auto_delay}ms - auto)"
            auto_delay=$((auto_delay + 100))
        fi
    done
    
    # Show skipped shortcuts if limit was applied
    if [[ -n "$LIMIT_COUNT" && $LIMIT_COUNT -lt $total_shortcuts ]]; then
        local skipped=$((total_shortcuts - LIMIT_COUNT))
        print_warning "Skipped $skipped shortcuts due to --limit $LIMIT_COUNT"
    fi
}

# Main execution
main() {
    echo "🔗 Mikrotik Hotspot Shortcuts Configurator (Enhanced)"
    echo "====================================================="
    echo
    
    # Set target file
    TARGET_FILE="${TARGET_FILE:-$DEFAULT_TARGET_FILE}"
    
    # Check dependencies
    check_dependencies
    
    # Create backup directory
    create_backup_dir
    
    # Check if shortcuts file exists
    check_shortcuts_file
    
    # Validate files
    validate_json
    
    # Generate new HTML
    print_status "Generating HTML for shortcuts..."
    local new_shortcuts_html=$(generate_all_shortcuts_html)
    
    # Backup and update
    backup_target_file
    update_target_file "$new_shortcuts_html"
    
    # Show results
    show_summary
}

# Handle script arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            echo "Usage: $0 [options]"
            echo
            echo "Options:"
            echo "  --help, -h           Show this help message"
            echo "  --file, -f FILE      Target HTML file to update (default: alogin.html)"
            echo "  --limit, -l N        Limit number of shortcuts to process (default: all)"
            echo "  --validate           Only validate JSON without updating"
            echo "  --list-backups       List available backups"
            echo
            echo "Files:"
            echo "  $SHORTCUTS_FILE      JSON file containing shortcut data (required)"
            echo "  HTML files           Files containing <div class=\"shortcuts\" id=\"shortcuts\">"
            echo
            echo "JSON Structure:"
            echo "  {"
            echo "    \"shortcuts\": ["
            echo "      {"
            echo "        \"name\": \"Google\","
            echo "        \"url\": \"https://www.google.com\","
            echo "        \"icon\": \"img/sites/logos--google-icon.png\","
            echo "        \"target\": \"_blank\",     // Optional (default: _blank)"
            echo "        \"delay\": 1200            // Optional custom delay (auto: 600, 700, 800...)"
            echo "      }"
            echo "    ]"
            echo "  }"
            echo
            echo "Delay Behavior:"
            echo "  • Auto-generated: 600ms, 700ms, 800ms, 900ms... (+100ms each)"
            echo "  • Custom delays in JSON take priority over auto-generation"
            echo "  • Mix and match: some shortcuts auto, others custom"
            echo
            echo "Examples:"
            echo "  $0                   Update alogin.html with all shortcuts"
            echo "  $0 -f login.html     Update login.html instead"
            echo "  $0 --limit 5         Only process first 5 shortcuts"
            echo "  $0 -l 3 -f test.html Process 3 shortcuts in test.html"
            echo "  $0 --validate        Only check if shortcuts.json is valid"
            echo
            echo "Development Usage:"
            echo "  $0 --limit 3         Quick testing with just 3 shortcuts"
            echo "  $0 -l 1              Minimal HTML with single shortcut"
            echo
            echo "Requirements:"
            echo "  - jq (JSON processor)"
            echo "  - python3 (for HTML processing)"
            exit 0
            ;;
        --file|-f)
            TARGET_FILE="$2"
            shift 2
            ;;
        --limit|-l)
            if [[ -z "$2" ]] || ! [[ "$2" =~ ^[0-9]+$ ]]; then
                print_error "Limit must be a positive number"
                exit 1
            fi
            LIMIT_COUNT="$2"
            shift 2
            ;;
        --validate)
            check_dependencies
            check_shortcuts_file
            validate_json
            print_success "JSON validation successful"
            exit 0
            ;;
        --list-backups)
            if [[ -d "$BACKUP_DIR" ]]; then
                echo "Available backups:"
                ls -1t "$BACKUP_DIR"/*.backup 2>/dev/null | head -20 || echo "No backups found"
            else
                echo "No backup directory found"
            fi
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Run main function
main