#!/bin/bash

# Mikrotik Hotspot Component Injector - Simple Single-Operation Version
# Injects ONE component into ONE file - much more reliable!

set -e  # Exit on any error

# Configuration
COMPONENTS_DIR="components"
BACKUP_DIR="backups"
DRY_RUN=false
DEBUG=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

print_component() {
    echo -e "${PURPLE}[COMPONENT]${NC} $1"
}

print_debug() {
    if [[ "$DEBUG" == "true" ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $1"
    fi
}

# Show usage
show_usage() {
    echo "🧩 Mikrotik Hotspot Component Injector (Simple Version)"
    echo "======================================================"
    echo
    echo "Usage: $0 comp <component.html> file <target.html> [options]"
    echo
    echo "Arguments:"
    echo "  comp <component.html>    Component to inject (e.g., footer.html)"
    echo "  file <target.html>       Target HTML file (e.g., alogin.html)"
    echo
    echo "Options:"
    echo "  --dry-run               Show what would be done without making changes"
    echo "  --debug                 Enable detailed debug output"
    echo "  --help, -h              Show this help message"
    echo
    echo "Examples:"
    echo "  $0 comp footer.html file alogin.html      # Inject footer into alogin.html"
    echo "  $0 comp footer.html file login.html       # Inject footer into login.html"
    echo "  $0 comp header.html file alogin.html      # Inject header into alogin.html"
    echo "  $0 comp footer.html file alogin.html --dry-run  # Preview changes"
    echo
    echo "How it works:"
    echo "  1. Looks for element with id matching component name (without .html)"
    echo "  2. Example: footer.html → looks for id=\"footer\""
    echo "  3. Replaces content inside that element with component content"
    echo
    echo "Example HTML:"
    echo "  <footer id=\"footer\"></footer>  <!-- Gets content from components/footer.html -->"
    echo
    echo "Requirements:"
    echo "  - python3"
    echo "  - $COMPONENTS_DIR/ directory with component HTML files"
    echo "  - Target HTML files with matching id elements"
}

# Check dependencies
check_dependencies() {
    if ! command -v python3 &> /dev/null; then
        print_error "python3 is required but not installed."
        exit 1
    fi
}

# Create backup directory if it doesn't exist
create_backup_dir() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        mkdir -p "$BACKUP_DIR"
        print_debug "Created backup directory: $BACKUP_DIR"
    fi
}

# Backup original file
backup_file() {
    local file="$1"
    local timestamp=$(date "+%Y%m%d_%H%M%S")
    local filename=$(basename "$file")
    local backup_file="${BACKUP_DIR}/${filename}.${timestamp}.backup"
    
    print_debug "Creating backup: $backup_file"
    cp "$file" "$backup_file"
    
    # Keep only the last 10 backups for this file
    local file_backups=$(ls -1t "${BACKUP_DIR}/${filename}."*.backup 2>/dev/null | tail -n +11)
    if [[ -n "$file_backups" ]]; then
        echo "$file_backups" | xargs rm -f >/dev/null 2>&1
    fi
}

# Check if a file contains a component placeholder
file_contains_component() {
    local file="$1"
    local component_id="$2"
    
    print_debug "Checking if $file contains element with id='$component_id'"
    if grep -q "id=[\"']${component_id}[\"']" "$file" 2>/dev/null; then
        print_debug "Found element with id='$component_id' in $file"
        return 0
    else
        print_debug "No element with id='$component_id' found in $file"
        return 1
    fi
}

# Inject component using Python
inject_component() {
    local component_file="$1"
    local target_file="$2"
    local component_name="$3"  # component name without .html extension
    
    print_debug "Starting component injection:"
    print_debug "  Component file: $component_file"
    print_debug "  Target file: $target_file"
    print_debug "  Component ID: $component_name"
    
    # Read component content
    local component_content
    if ! component_content=$(cat "$component_file"); then
        print_error "Failed to read component file: $component_file"
        return 1
    fi
    
    print_debug "Component content length: ${#component_content} characters"
    
    # Create temporary files
    local temp_file="${target_file}.tmp.$$"
    local error_file="injection_error.$$.log"
    
    # Create Python script inline
    print_debug "Creating and running Python injection script..."
    
    python3 << PYTHON_SCRIPT > "$temp_file" 2>"$error_file"
import sys
import re

# Read the target file
try:
    with open('$target_file', 'r', encoding='utf-8') as f:
        content = f.read()
except Exception as e:
    print(f"ERROR: Failed to read target file '$target_file': {e}", file=sys.stderr)
    sys.exit(1)

# Component content from bash
component_content = '''$component_content'''
component_name = '$component_name'

original_content = content
found_match = False

# First, find the opening tag with the matching id
opening_tag_pattern = rf'<([^>]+id=["\']' + re.escape(component_name) + r'["\'][^>]*?)>'
opening_match = re.search(opening_tag_pattern, content, re.IGNORECASE)

if not opening_match:
    print(f"ERROR: Could not find opening tag with id='{component_name}' in $target_file", file=sys.stderr)
    sys.exit(1)

# Extract tag name from the opening tag
opening_tag_full = opening_match.group(0)
opening_tag_content = opening_match.group(1)
tag_name = opening_tag_content.split()[0]

print(f"INFO: Found opening tag: {opening_tag_full}", file=sys.stderr)
print(f"INFO: Extracted tag name: {tag_name}", file=sys.stderr)

# Check if it's a self-closing tag
if opening_tag_content.endswith('/'):
    # Handle self-closing tag - convert to opening/closing tag pair
    tag_content = opening_tag_content.rstrip('/')
    replacement = f'<{tag_content}>\n{component_content}\n</{tag_name}>'
    content = content.replace(opening_tag_full, replacement)
    found_match = True
    print(f"INFO: Processed self-closing tag for component '{component_name}'", file=sys.stderr)
else:
    # Handle regular opening/closing tags - find the complete element
    # Create a more specific pattern that matches the exact opening and closing tags
    specific_pattern = rf'(<' + re.escape(tag_name) + r'[^>]+id=["\']' + re.escape(component_name) + r'["\'][^>]*>)(.*?)(<\/' + re.escape(tag_name) + r'>)'
    
    match = re.search(specific_pattern, content, re.DOTALL | re.IGNORECASE)
    if match:
        # Replace the content between the specific opening and closing tags
        replacement = f'{match.group(1)}\n{component_content}\n{match.group(3)}'
        content = content.replace(match.group(0), replacement)
        found_match = True
        print(f"INFO: Processed regular tags for component '{component_name}' (tag: {tag_name})", file=sys.stderr)
        print(f"INFO: Replaced content between <{tag_name}> and </{tag_name}>", file=sys.stderr)
        
        # Debug: Show what was replaced (only first 100 chars to avoid spam)
        old_content = match.group(2).strip()
        if len(old_content) > 100:
            old_preview = old_content[:100] + "..."
        else:
            old_preview = old_content
        print(f"DEBUG: Old content preview: {repr(old_preview)}", file=sys.stderr)
        
        if len(component_content.strip()) > 100:
            new_preview = component_content.strip()[:100] + "..."
        else:
            new_preview = component_content.strip()
        print(f"DEBUG: New content preview: {repr(new_preview)}", file=sys.stderr)
    else:
        print(f"ERROR: Could not find matching closing tag </{tag_name}> for component '{component_name}'", file=sys.stderr)
        sys.exit(1)

if not found_match:
    print(f"ERROR: Could not find element with id='{component_name}' in $target_file", file=sys.stderr)
    sys.exit(1)

# Check if anything was actually changed
if content == original_content:
    print(f"INFO: Content already matches - component '{component_name}' is up to date", file=sys.stderr)
    # Don't exit with error - this is actually a success case
else:
    print(f"SUCCESS: Component '{component_name}' content updated successfully", file=sys.stderr)

# Output the result (even if unchanged, we still output it)
print(content, end='')
PYTHON_SCRIPT

    local python_exit_code=$?
    
    print_debug "Python script exit code: $python_exit_code"
    
    # Check if Python script succeeded
    if [[ $python_exit_code -eq 0 ]]; then
        print_debug "Python script executed successfully"
        
        # Show any info/warning messages from Python
        if [[ -s "$error_file" ]]; then
            while IFS= read -r line; do
                if [[ "$line" == "INFO:"* ]]; then
                    print_debug "${line#INFO: }"
                elif [[ "$line" == "WARNING:"* ]]; then
                    print_warning "${line#WARNING: }"
                elif [[ "$line" == "SUCCESS:"* ]]; then
                    print_debug "${line#SUCCESS: }"
                fi
            done < "$error_file"
        fi
        
        if [[ "$DRY_RUN" == "true" ]]; then
            print_status "DRY RUN: Would inject $component_name into $target_file"
            rm -f "$temp_file" "$error_file"
            return 0
        else
            # Check if temp file has content
            if [[ -s "$temp_file" ]]; then
                print_debug "Temp file created successfully, replacing original"
                mv "$temp_file" "$target_file"
                print_component "✓ Successfully injected $component_name into $target_file"
                rm -f "$error_file"
                return 0
            else
                print_error "Python script produced empty output"
                rm -f "$temp_file" "$error_file"
                return 1
            fi
        fi
    else
        print_debug "Python script failed"
        print_error "Failed to inject component"
        
        # Show Python error details
        if [[ -s "$error_file" ]]; then
            while IFS= read -r line; do
                if [[ "$line" == "ERROR:"* ]]; then
                    print_error "${line#ERROR: }"
                else
                    print_error "$line"
                fi
            done < "$error_file"
        fi
        
        rm -f "$temp_file" "$error_file"
        return 1
    fi
}

# Main execution
main() {
    local component_html=""
    local target_file=""
    local expecting_component=false
    local expecting_file=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            comp)
                expecting_component=true
                expecting_file=false
                shift
                ;;
            file)
                expecting_file=true
                expecting_component=false
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --debug)
                DEBUG=true
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                if [[ "$expecting_component" == "true" ]]; then
                    component_html="$1"
                    expecting_component=false
                elif [[ "$expecting_file" == "true" ]]; then
                    target_file="$1"
                    expecting_file=false
                else
                    print_error "Unknown argument: $1"
                    echo "Use --help for usage information"
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Validate arguments
    if [[ -z "$component_html" || -z "$target_file" ]]; then
        print_error "Both component and target file must be specified"
        echo
        show_usage
        exit 1
    fi
    
    print_status "Component Injector Starting..."
    print_debug "Component: $component_html"
    print_debug "Target file: $target_file"
    print_debug "Dry run: $DRY_RUN"
    
    # Check dependencies
    check_dependencies
    
    # Create backup directory
    create_backup_dir
    
    # Validate component file
    local component_path="$COMPONENTS_DIR/$component_html"
    if [[ ! -f "$component_path" ]]; then
        print_error "Component file not found: $component_path"
        exit 1
    fi
    
    # Validate target file
    if [[ ! -f "$target_file" ]]; then
        print_error "Target file not found: $target_file"
        exit 1
    fi
    
    # Extract component name (remove .html extension)
    local component_name="${component_html%.html}"
    print_debug "Component name (ID): $component_name"
    
    # Check if target file contains the component placeholder
    if ! file_contains_component "$target_file" "$component_name"; then
        print_error "Target file '$target_file' does not contain element with id='$component_name'"
        print_status "Make sure your HTML contains: <element id=\"$component_name\">...</element>"
        exit 1
    fi
    
    # Create backup
    if [[ "$DRY_RUN" != "true" ]]; then
        backup_file "$target_file"
        print_status "Created backup in $BACKUP_DIR/"
    fi
    
    # Inject component
    if inject_component "$component_path" "$target_file" "$component_name"; then
        print_success "Component injection completed successfully!"
        echo
        echo "Summary:"
        echo "  • Component: $component_html"
        echo "  • Target file: $target_file"
        echo "  • Component ID: $component_name"
        if [[ "$DRY_RUN" != "true" ]]; then
            echo "  • Backup created in: $BACKUP_DIR/"
        fi
    else
        print_error "Component injection failed"
        exit 1
    fi
}

# Handle no arguments
if [[ $# -eq 0 ]]; then
    show_usage
    exit 1
fi

# Run main function
main "$@"