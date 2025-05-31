#!/bin/bash

# Mikrotik Hotspot Plan Configurator
# Reads JSON plan data and updates HTML files

set -e  # Exit on any error

# Configuration
PLANS_FILE="plans.json"
DEFAULT_TARGET_FILE="login.html"
TARGET_FILE=""
BACKUP_DIR="backups"

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
    
    # Check for Python3
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

# Check if plans.json exists
check_plans_file() {
    if [[ ! -f "$PLANS_FILE" ]]; then
        print_error "Plans file '$PLANS_FILE' not found!"
        echo
        echo "Please create a plans.json file with this structure:"
        echo '{'
        echo '  "plans": ['
        echo '    {'
        echo '      "price": "50 جنية",'
        echo '      "data_limit": "20 جيجا",'
        echo '      "badge": "20GB",'
        echo '      "speeds": ["1 ميجا", "2 ميجا", "3 ميجا"]'
        echo '    }'
        echo '  ]'
        echo '}'
        exit 1
    fi
}

# Validate JSON structure
validate_json() {
    print_status "Validating JSON structure..."
    
    if ! jq empty "$PLANS_FILE" 2>/dev/null; then
        print_error "Invalid JSON in $PLANS_FILE"
        exit 1
    fi
    
    # Check required fields
    if ! jq -e '.plans | type == "array"' "$PLANS_FILE" > /dev/null; then
        print_error "JSON must contain 'plans' array"
        exit 1
    fi
    
    # Validate each plan has required fields
    local plan_count=$(jq '.plans | length' "$PLANS_FILE")
    if [[ $plan_count -eq 0 ]]; then
        print_error "No plans found in $PLANS_FILE"
        exit 1
    fi
    
    for ((i=0; i<plan_count; i++)); do
        local plan=$(jq ".plans[$i]" "$PLANS_FILE")
        
        if ! echo "$plan" | jq -e 'has("price") and has("data_limit") and has("badge") and has("speeds")' > /dev/null; then
            print_error "Plan $((i+1)) missing required fields (price, data_limit, badge, speeds)"
            exit 1
        fi
        
        if ! echo "$plan" | jq -e '.speeds | type == "array"' > /dev/null; then
            print_error "Plan $((i+1)) speeds must be an array"
            exit 1
        fi
    done
    
    print_success "JSON validation passed"
}

# Generate HTML for a single plan
generate_plan_html() {
    local plan_json="$1"
    local price=$(echo "$plan_json" | jq -r '.price')
    local data_limit=$(echo "$plan_json" | jq -r '.data_limit')
    local badge=$(echo "$plan_json" | jq -r '.badge')
    
    cat << EOF
            <div class="plan">
              <div class="plan-badge">$badge</div>
              <div class="plan-header">
                <h3 class="plan-price">$price</h3>
                <span class="usage-limit">$data_limit</span>
              </div>
              <div class="plan-body">
                <ul class="plan-speeds">
EOF

    # Generate speed list items
    local speeds=$(echo "$plan_json" | jq -r '.speeds[]')
    while IFS= read -r speed; do
        [[ -n "$speed" ]] && cat << EOF
                  <li>
                    <span class="plan-speed-icon"><svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 48 48"><defs><mask id="ipSCheckOne0"><g fill="none" stroke-linejoin="round" stroke-width="4"><path fill="#fff" stroke="#fff" d="M24 44a19.94 19.94 0 0 0 14.142-5.858A19.94 19.94 0 0 0 44 24a19.94 19.94 0 0 0-5.858-14.142A19.94 19.94 0 0 0 24 4A19.94 19.94 0 0 0 9.858 9.858A19.94 19.94 0 0 0 4 24a19.94 19.94 0 0 0 5.858 14.142A19.94 19.94 0 0 0 24 44Z"/><path stroke="#000" stroke-linecap="round" d="m16 24l6 6l12-12"/></g></mask></defs><path fill="currentColor" d="M0 0h48v48H0z" mask="url(#ipSCheckOne0)"/></svg></span>
                    <span class="plan-speed">$speed</span>
                  </li>
EOF
    done <<< "$speeds"
    
    cat << EOF
                </ul>
              </div>
            </div>
EOF
}

# Generate all plans HTML
generate_all_plans_html() {
    local plan_count=$(jq '.plans | length' "$PLANS_FILE")
    
    for ((i=0; i<plan_count; i++)); do
        local plan=$(jq ".plans[$i]" "$PLANS_FILE")
        generate_plan_html "$plan"
        
        # Add newline between plans (except after the last one)
        if [[ $i -lt $((plan_count - 1)) ]]; then
            echo
        fi
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

# Update target file with new plans
update_target_file() {
    local new_plans_html="$1"
    
    print_status "Updating $TARGET_FILE..."
    
    # Check if the plans div exists
    if ! grep -q 'id="plans"' "$TARGET_FILE"; then
        print_error "Could not find element with id='plans' in $TARGET_FILE"
        echo "Make sure your HTML file contains: <div class=\"plans\" id=\"plans\">"
        exit 1
    fi
    
    # Create a temporary file to write the new content
    local temp_file="${TARGET_FILE}.tmp"
    
    # Use Python to properly handle the nested HTML replacement
    cat > replace_plans.py << 'PYTHON_SCRIPT'
import sys

# Read the original file
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Get the new plans HTML from argument
new_plans = sys.argv[2]

# Find the plans div and replace its contents
in_plans_div = False
div_count = 0
result_lines = []

for line in lines:
    if 'class="plans" id="plans"' in line:
        # Found the opening div, add it and the new content
        result_lines.append(line)
        result_lines.append(new_plans + '\n')
        in_plans_div = True
        div_count = 1
    elif in_plans_div:
        # Count div tags to find the matching closing tag
        div_count += line.count('<div')
        div_count -= line.count('</div>')
        
        # When div_count reaches 0, we found the closing tag
        if div_count == 0:
            result_lines.append(line)
            in_plans_div = False
        # Skip all lines inside the plans div (don't add them)
    else:
        # Outside plans div, add the line normally
        result_lines.append(line)

# Write the result
for line in result_lines:
    print(line, end='')
PYTHON_SCRIPT

    # Run the Python script
    python3 replace_plans.py "$TARGET_FILE" "$new_plans_html" > "$temp_file"
    
    # Check if Python script succeeded
    if [[ $? -eq 0 ]]; then
        mv "$temp_file" "$TARGET_FILE"
        rm -f replace_plans.py
        print_success "Successfully updated $TARGET_FILE"
    else
        print_error "Failed to update $TARGET_FILE"
        rm -f "$temp_file" replace_plans.py
        exit 1
    fi
}

# Display summary
show_summary() {
    local plan_count=$(jq '.plans | length' "$PLANS_FILE")
    print_success "Plans configuration completed!"
    echo
    echo "Summary:"
    echo "  • Plans configured: $plan_count"
    echo "  • Target file: $TARGET_FILE"
    echo "  • Backup location: $BACKUP_DIR/"
    echo "  • Source file: $PLANS_FILE"
    echo
    print_status "Plan details:"
    jq -r '.plans[] | "  • \(.price) - \(.data_limit) - [\(.badge)] - \(.speeds | length) speeds"' "$PLANS_FILE"
}

# Main execution
main() {
    echo "🎯 Mikrotik Hotspot Plan Configurator"
    echo "======================================"
    echo
    
    # Set target file
    TARGET_FILE="${TARGET_FILE:-$DEFAULT_TARGET_FILE}"
    
    # Check dependencies
    check_dependencies
    
    # Create backup directory
    create_backup_dir
    
    # Check if plans file exists
    check_plans_file
    
    # Validate files
    validate_json
    
    # Generate new HTML
    print_status "Generating HTML for plans..."
    local new_plans_html=$(generate_all_plans_html)
    
    # Backup and update
    backup_target_file
    update_target_file "$new_plans_html"
    
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
            echo "  --file, -f FILE      Target HTML file to update (default: login.html)"
            echo "  --validate           Only validate JSON without updating"
            echo "  --list-backups       List available backups"
            echo
            echo "Files:"
            echo "  $PLANS_FILE          JSON file containing plan data (required)"
            echo "  HTML files           Files containing <div class=\"plans\" id=\"plans\">"
            echo
            echo "JSON Structure:"
            echo "  {"
            echo "    \"plans\": ["
            echo "      {"
            echo "        \"price\": \"50 جنية\","
            echo "        \"data_limit\": \"20 جيجا\","
            echo "        \"badge\": \"20GB\","
            echo "        \"speeds\": [\"1 ميجا\", \"2 ميجا\"]"
            echo "      }"
            echo "    ]"
            echo "  }"
            echo
            echo "Examples:"
            echo "  $0                   Update login.html with plans from plans.json"
            echo "  $0 -f status.html    Update status.html instead"
            echo "  $0 --validate        Only check if plans.json is valid"
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
        --validate)
            check_dependencies
            check_plans_file
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