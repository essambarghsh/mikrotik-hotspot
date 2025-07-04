#!/bin/bash

# Mikrotik Hotspot Plan Configurator
# Reads JSON plan data and updates HTML files

set -e  # Exit on any error

# Configuration
PLANS_FILE="plans.json"
DEFAULT_TARGET_FILE="login.html"
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
        echo '      "extra_badge": "Popular",'
        echo '      "css_classes": ["featured", "discount"],'
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
    
    # Determine how many plans to validate based on limit
    local validate_count=$plan_count
    if [[ -n "$LIMIT_COUNT" ]]; then
        validate_count=$(( LIMIT_COUNT < plan_count ? LIMIT_COUNT : plan_count ))
        print_status "Validating first $validate_count of $plan_count plans (limit applied)" >&2
    fi
    
    for ((i=0; i<validate_count; i++)); do
        local plan=$(jq ".plans[$i]" "$PLANS_FILE")
        
        # Check required fields
        if ! echo "$plan" | jq -e 'has("price") and has("data_limit") and has("badge") and has("speeds")' > /dev/null; then
            print_error "Plan $((i+1)) missing required fields (price, data_limit, badge, speeds)"
            exit 1
        fi
        
        # Check speeds is array
        if ! echo "$plan" | jq -e '.speeds | type == "array"' > /dev/null; then
            print_error "Plan $((i+1)) speeds must be an array"
            exit 1
        fi
        
        # Check optional css_classes is array if present
        if echo "$plan" | jq -e 'has("css_classes")' > /dev/null; then
            if ! echo "$plan" | jq -e '.css_classes | type == "array"' > /dev/null; then
                print_error "Plan $((i+1)) css_classes must be an array"
                exit 1
            fi
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
    
    # Get extra badge (optional)
    local extra_badge=""
    if echo "$plan_json" | jq -e 'has("extra_badge")' > /dev/null; then
        extra_badge=$(echo "$plan_json" | jq -r '.extra_badge // ""')
    fi
    
    # Get CSS classes (optional)
    local css_classes="plan"
    if echo "$plan_json" | jq -e 'has("css_classes")' > /dev/null; then
        local custom_classes=$(echo "$plan_json" | jq -r '.css_classes[]?' | tr '\n' ' ')
        if [[ -n "$custom_classes" ]]; then
            css_classes="plan $custom_classes"
        fi
    fi
    
    # Start the plan div with custom classes and badges container
    cat << EOF
            <div class="$css_classes">
              <div class="badges">
                <div class="plan-badge">$badge</div>
EOF

    # Add extra badge if it exists
    if [[ -n "$extra_badge" && "$extra_badge" != "null" ]]; then
        cat << EOF
                <div class="extra-badge">$extra_badge</div>
EOF
    fi

    cat << EOF
              </div>
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
    local total_plans=$(jq '.plans | length' "$PLANS_FILE")
    local plan_count=$total_plans
    
    # Apply limit if specified
    if [[ -n "$LIMIT_COUNT" ]]; then
        plan_count=$(( LIMIT_COUNT < total_plans ? LIMIT_COUNT : total_plans ))
        print_status "Generating $plan_count of $total_plans plans (limit applied)" >&2
    fi
    
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
    local total_plans=$(jq '.plans | length' "$PLANS_FILE")
    local processed_plans=$total_plans
    
    # Calculate processed plans based on limit
    if [[ -n "$LIMIT_COUNT" ]]; then
        processed_plans=$(( LIMIT_COUNT < total_plans ? LIMIT_COUNT : total_plans ))
    fi
    
    print_success "Plans configuration completed!"
    echo
    echo "Summary:"
    echo "  • Plans processed: $processed_plans of $total_plans"
    if [[ -n "$LIMIT_COUNT" ]]; then
        echo "  • Limit applied: $LIMIT_COUNT"
    fi
    echo "  • Target file: $TARGET_FILE"
    echo "  • Backup location: $BACKUP_DIR/"
    echo "  • Source file: $PLANS_FILE"
    echo
    print_status "Plan details:"
    
    # Enhanced summary showing new features
    for ((i=0; i<processed_plans; i++)); do
        local plan=$(jq ".plans[$i]" "$PLANS_FILE")
        local price=$(echo "$plan" | jq -r '.price')
        local data_limit=$(echo "$plan" | jq -r '.data_limit')
        local badge=$(echo "$plan" | jq -r '.badge')
        local speeds_count=$(echo "$plan" | jq '.speeds | length')
        
        # Check for extra badge
        local extra_info=""
        if echo "$plan" | jq -e 'has("extra_badge")' > /dev/null; then
            local extra_badge=$(echo "$plan" | jq -r '.extra_badge // ""')
            if [[ -n "$extra_badge" && "$extra_badge" != "null" ]]; then
                extra_info=" +Badge:$extra_badge"
            fi
        fi
        
        # Check for CSS classes
        if echo "$plan" | jq -e 'has("css_classes")' > /dev/null; then
            local classes=$(echo "$plan" | jq -r '.css_classes[]?' | tr '\n' ',' | sed 's/,$//')
            if [[ -n "$classes" ]]; then
                extra_info="$extra_info +Classes:$classes"
            fi
        fi
        
        echo "  • $price - $data_limit - [$badge] - $speeds_count speeds$extra_info"
    done
    
    # Show skipped plans if limit was applied
    if [[ -n "$LIMIT_COUNT" && $LIMIT_COUNT -lt $total_plans ]]; then
        local skipped=$((total_plans - LIMIT_COUNT))
        print_warning "Skipped $skipped plans due to --limit $LIMIT_COUNT"
    fi
}

# Main execution
main() {
    echo "🎯 Mikrotik Hotspot Plan Configurator (Enhanced)"
    echo "==============================================="
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
            echo "  --limit, -l N        Limit number of plans to process (default: all)"
            echo "  --validate           Only validate JSON without updating"
            echo "  --list-backups       List available backups"
            echo
            echo "Files:"
            echo "  $PLANS_FILE          JSON file containing plan data (required)"
            echo "  HTML files           Files containing <div class=\"plans\" id=\"plans\">"
            echo
            echo "Enhanced JSON Structure:"
            echo "  {"
            echo "    \"plans\": ["
            echo "      {"
            echo "        \"price\": \"50 جنية\","
            echo "        \"data_limit\": \"20 جيجا\","
            echo "        \"badge\": \"20GB\","
            echo "        \"extra_badge\": \"Popular\",          // Optional"
            echo "        \"css_classes\": [\"featured\", \"discount\"], // Optional"
            echo "        \"speeds\": [\"1 ميجا\", \"2 ميجا\"]"
            echo "      }"
            echo "    ]"
            echo "  }"
            echo
            echo "New Features:"
            echo "  • extra_badge: Additional badge text (e.g., 'Popular', 'Best Value')"
            echo "  • css_classes: Array of custom CSS classes for styling"
            echo "  • --limit flag: Process only first N plans (great for development)"
            echo
            echo "Examples:"
            echo "  $0                   Update login.html with all plans"
            echo "  $0 -f status.html    Update status.html instead"
            echo "  $0 --limit 3         Only process first 3 plans"
            echo "  $0 -l 5 -f test.html Process 5 plans in test.html"
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