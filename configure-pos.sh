#!/bin/bash

# Mikrotik Hotspot POS (Point of Sale) Configurator
# Reads JSON POS data and updates HTML files

set -e  # Exit on any error

# Configuration
POS_FILE="pos.json"
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

# Check if pos.json exists
check_pos_file() {
    if [[ ! -f "$POS_FILE" ]]; then
        print_error "POS file '$POS_FILE' not found!"
        echo
        echo "Please create a pos.json file with this structure:"
        echo '{'
        echo '  "locations": ['
        echo '    {'
        echo '      "name": "محل أبوعيسي",'
        echo '      "village": "قراقص",'
        echo '      "address": "بجوار صيدليه د/وليد حجازي امام الفصل الواحد",'
        echo '      "services": ["تجديد باقة", "كروت فكة", "دعم فني"],'
        echo '      "map_url": "https://maps.app.goo.gl/RuC4avfozWFFrwP6A",'
        echo '      "phone": "01234567890",'
        echo '      "hours": "من 9 صباحاً إلى 10 مساءً"'
        echo '    }'
        echo '  ]'
        echo '}'
        exit 1
    fi
}

# Validate JSON structure
validate_json() {
    print_status "Validating JSON structure..."
    
    if ! jq empty "$POS_FILE" 2>/dev/null; then
        print_error "Invalid JSON in $POS_FILE"
        exit 1
    fi
    
    # Check required fields
    if ! jq -e '.locations | type == "array"' "$POS_FILE" > /dev/null; then
        print_error "JSON must contain 'locations' array"
        exit 1
    fi
    
    # Validate each location has required fields
    local location_count=$(jq '.locations | length' "$POS_FILE")
    if [[ $location_count -eq 0 ]]; then
        print_error "No locations found in $POS_FILE"
        exit 1
    fi
    
    # Determine how many locations to validate based on limit
    local validate_count=$location_count
    if [[ -n "$LIMIT_COUNT" ]]; then
        validate_count=$(( LIMIT_COUNT < location_count ? LIMIT_COUNT : location_count ))
        print_status "Validating first $validate_count of $location_count locations (limit applied)" >&2
    fi
    
    for ((i=0; i<validate_count; i++)); do
        local location=$(jq ".locations[$i]" "$POS_FILE")
        
        # Check required fields
        if ! echo "$location" | jq -e 'has("name") and has("village") and has("address") and has("services") and has("map_url")' > /dev/null; then
            print_error "Location $((i+1)) missing required fields (name, village, address, services, map_url)"
            exit 1
        fi
        
        # Check services is array
        if ! echo "$location" | jq -e '.services | type == "array"' > /dev/null; then
            print_error "Location $((i+1)) services must be an array"
            exit 1
        fi
    done
    
    print_success "JSON validation passed"
}

# Generate HTML for a single POS location
generate_pos_html() {
    local location_json="$1"
    local name=$(echo "$location_json" | jq -r '.name')
    local village=$(echo "$location_json" | jq -r '.village')
    local address=$(echo "$location_json" | jq -r '.address')
    local map_url=$(echo "$location_json" | jq -r '.map_url')
    
    # Get optional fields
    local phone=""
    local hours=""
    if echo "$location_json" | jq -e 'has("phone")' > /dev/null; then
        phone=$(echo "$location_json" | jq -r '.phone // ""')
    fi
    if echo "$location_json" | jq -e 'has("hours")' > /dev/null; then
        hours=$(echo "$location_json" | jq -r '.hours // ""')
    fi
    
    # Start the location div
    cat << EOF
          <div class="pos-item">
            <div class="pos-content">
              <div class="pos-header">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 16 16"><path fill="currentColor" d="m7.385 15.293l-.192-.13a18 18 0 0 1-2.666-2.283C3.1 11.385 1.5 9.144 1.5 6.499C1.5 3.245 4.141 0 8 0s6.5 3.245 6.5 6.5c0 2.645-1.6 4.886-3.027 6.379a18 18 0 0 1-2.666 2.283q-.122.085-.192.13c-.203.135-.41.263-.615.393c-.205-.13-.412-.258-.615-.392M8 8.5a2 2 0 1 0 0-4a2 2 0 0 0 0 4"/></svg>
                <h3 class="pos-name">$name</h3>
              </div>
              <div class="pos-details">
                <div class="pos-detail-row">
                  <div class="first">القرية</div>
                  <div class="end">$village</div>
                </div>
                <div class="pos-detail-row">
                  <div class="first">العنوان</div>
                  <div class="end">$address</div>
                </div>
EOF

    # Add phone if available
    if [[ -n "$phone" && "$phone" != "null" ]]; then
        cat << EOF
                <div class="pos-detail-row">
                  <div class="first">الهاتف</div>
                  <div class="end">$phone</div>
                </div>
EOF
    fi

    # Add hours if available
    if [[ -n "$hours" && "$hours" != "null" ]]; then
        cat << EOF
                <div class="pos-detail-row">
                  <div class="first">ساعات العمل</div>
                  <div class="end">$hours</div>
                </div>
EOF
    fi

    # Add services
    cat << EOF
                <div class="pos-detail-row as-badges">
                  <div class="first">الخدمات</div>
                  <div class="end">
                    <ul>
EOF

    # Generate service list items
    local services=$(echo "$location_json" | jq -r '.services[]')
    while IFS= read -r service; do
        [[ -n "$service" ]] && cat << EOF
                      <li>$service</li>
EOF
    done <<< "$services"
    
    # Close services and add CTA
    cat << EOF
                    </ul>
                  </div>
                </div>
              </div>
              <div class="pos-cta">
                <a href="$map_url" target="_blank">
                  <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24"><path fill="currentColor" d="m12 17l1-2V9.858c1.721-.447 3-2 3-3.858c0-2.206-1.794-4-4-4S8 3.794 8 6c0 1.858 1.279 3.411 3 3.858V15z"/><path fill="currentColor" d="m16.267 10.563l-.533 1.928C18.325 13.207 20 14.584 20 16c0 1.892-3.285 4-8 4s-8-2.108-8-4c0-1.416 1.675-2.793 4.267-3.51l-.533-1.928C4.197 11.54 2 13.623 2 16c0 3.364 4.393 6 10 6s10-2.636 10-6c0-2.377-2.197-4.46-5.733-5.437"/></svg>
                  <span>فتح في الخريطة</span>
                  <span class="new-tab">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24"><g class="open-in-new-tab-outline"><g fill="currentColor" fill-rule="evenodd" class="Vector" clip-rule="evenodd"><path d="M5 4a1 1 0 0 0-1 1v14a1 1 0 0 0 1 1h14a1 1 0 0 0 1-1v-5.263a1 1 0 1 1 2 0V19a3 3 0 0 1-3 3H5a3 3 0 0 1-3-3V5a3 3 0 0 1 3-3h5.017a1 1 0 1 1 0 2z"/><path d="M21.411 2.572a.963.963 0 0 1 0 1.36l-8.772 8.786a.96.96 0 0 1-1.358 0a.963.963 0 0 1 0-1.36l8.773-8.786a.96.96 0 0 1 1.357 0"/><path d="M21.04 2c.53 0 .96.43.96.962V8c0 .531-.47 1-1 1s-1-.469-1-1V4h-4c-.53 0-1-.469-1-1s.43-1 .96-1z"/></g></g></svg>
                  </span>
                </a>
              </div>
            </div>
          </div>
EOF
}

# Generate all locations HTML
generate_all_pos_html() {
    local total_locations=$(jq '.locations | length' "$POS_FILE")
    local location_count=$total_locations
    
    # Apply limit if specified
    if [[ -n "$LIMIT_COUNT" ]]; then
        location_count=$(( LIMIT_COUNT < total_locations ? LIMIT_COUNT : total_locations ))
        print_status "Generating $location_count of $total_locations locations (limit applied)" >&2
    fi
    
    for ((i=0; i<location_count; i++)); do
        local location=$(jq ".locations[$i]" "$POS_FILE")
        generate_pos_html "$location"
        
        # Add newline between locations (except after the last one)
        if [[ $i -lt $((location_count - 1)) ]]; then
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

# Update target file with new locations
update_target_file() {
    local new_pos_html="$1"
    
    print_status "Updating $TARGET_FILE..."
    
    # Check if the pos div exists
    if ! grep -q 'id="pos"' "$TARGET_FILE"; then
        print_error "Could not find element with id='pos' in $TARGET_FILE"
        echo "Make sure your HTML file contains: <div class=\"pos\" id=\"pos\">"
        exit 1
    fi
    
    # Create a temporary file to write the new content
    local temp_file="${TARGET_FILE}.tmp"
    
    # Use Python to properly handle the nested HTML replacement
    cat > replace_pos.py << 'PYTHON_SCRIPT'
import sys

# Read the original file
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Get the new POS HTML from argument
new_pos = sys.argv[2]

# Find the pos div and replace its contents
in_pos_div = False
div_count = 0
result_lines = []

for line in lines:
    if 'class="pos" id="pos"' in line:
        # Found the opening div, add it and the new content
        result_lines.append(line)
        result_lines.append(new_pos + '\n')
        in_pos_div = True
        div_count = 1
    elif in_pos_div:
        # Count div tags to find the matching closing tag
        div_count += line.count('<div')
        div_count -= line.count('</div>')
        
        # When div_count reaches 0, we found the closing tag
        if div_count == 0:
            result_lines.append(line)
            in_pos_div = False
        # Skip all lines inside the pos div (don't add them)
    else:
        # Outside pos div, add the line normally
        result_lines.append(line)

# Write the result
for line in result_lines:
    print(line, end='')
PYTHON_SCRIPT

    # Run the Python script
    python3 replace_pos.py "$TARGET_FILE" "$new_pos_html" > "$temp_file"
    
    # Check if Python script succeeded
    if [[ $? -eq 0 ]]; then
        mv "$temp_file" "$TARGET_FILE"
        rm -f replace_pos.py
        print_success "Successfully updated $TARGET_FILE"
    else
        print_error "Failed to update $TARGET_FILE"
        rm -f "$temp_file" replace_pos.py
        exit 1
    fi
}

# Display summary
show_summary() {
    local total_locations=$(jq '.locations | length' "$POS_FILE")
    local processed_locations=$total_locations
    
    # Calculate processed locations based on limit
    if [[ -n "$LIMIT_COUNT" ]]; then
        processed_locations=$(( LIMIT_COUNT < total_locations ? LIMIT_COUNT : total_locations ))
    fi
    
    print_success "POS configuration completed!"
    echo
    echo "Summary:"
    echo "  • Locations processed: $processed_locations of $total_locations"
    if [[ -n "$LIMIT_COUNT" ]]; then
        echo "  • Limit applied: $LIMIT_COUNT"
    fi
    echo "  • Target file: $TARGET_FILE"
    echo "  • Backup location: $BACKUP_DIR/"
    echo "  • Source file: $POS_FILE"
    echo
    print_status "Location details:"
    
    for ((i=0; i<processed_locations; i++)); do
        local location=$(jq ".locations[$i]" "$POS_FILE")
        local name=$(echo "$location" | jq -r '.name')
        local village=$(echo "$location" | jq -r '.village')
        local services_count=$(echo "$location" | jq '.services | length')
        
        # Check for optional fields
        local extra_info=""
        if echo "$location" | jq -e 'has("phone")' > /dev/null; then
            local phone=$(echo "$location" | jq -r '.phone // ""')
            if [[ -n "$phone" && "$phone" != "null" ]]; then
                extra_info=" +Phone"
            fi
        fi
        
        if echo "$location" | jq -e 'has("hours")' > /dev/null; then
            local hours=$(echo "$location" | jq -r '.hours // ""')
            if [[ -n "$hours" && "$hours" != "null" ]]; then
                extra_info="$extra_info +Hours"
            fi
        fi
        
        echo "  • $name - $village - $services_count services$extra_info"
    done
    
    # Show skipped locations if limit was applied
    if [[ -n "$LIMIT_COUNT" && $LIMIT_COUNT -lt $total_locations ]]; then
        local skipped=$((total_locations - LIMIT_COUNT))
        print_warning "Skipped $skipped locations due to --limit $LIMIT_COUNT"
    fi
}

# Main execution
main() {
    echo "🏪 Mikrotik Hotspot POS Configurator"
    echo "===================================="
    echo
    
    # Set target file
    TARGET_FILE="${TARGET_FILE:-$DEFAULT_TARGET_FILE}"
    
    # Check dependencies
    check_dependencies
    
    # Create backup directory
    create_backup_dir
    
    # Check if pos file exists
    check_pos_file
    
    # Validate files
    validate_json
    
    # Generate new HTML
    print_status "Generating HTML for POS locations..."
    local new_pos_html=$(generate_all_pos_html)
    
    # Backup and update
    backup_target_file
    update_target_file "$new_pos_html"
    
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
            echo "  --limit, -l N        Limit number of locations to process (default: all)"
            echo "  --validate           Only validate JSON without updating"
            echo "  --list-backups       List available backups"
            echo
            echo "Files:"
            echo "  $POS_FILE            JSON file containing POS location data (required)"
            echo "  HTML files           Files containing <div class=\"pos\" id=\"pos\">"
            echo
            echo "JSON Structure:"
            echo "  {"
            echo "    \"locations\": ["
            echo "      {"
            echo "        \"name\": \"محل أبوعيسي\","
            echo "        \"village\": \"قراقص\","
            echo "        \"address\": \"بجوار صيدليه د/وليد حجازي امام الفصل الواحد\","
            echo "        \"services\": [\"تجديد باقة\", \"كروت فكة\", \"دعم فني\"],"
            echo "        \"map_url\": \"https://maps.app.goo.gl/RuC4avfozWFFrwP6A\","
            echo "        \"phone\": \"01234567890\",           // Optional"
            echo "        \"hours\": \"من 9 صباحاً إلى 10 مساءً\"    // Optional"
            echo "      }"
            echo "    ]"
            echo "  }"
            echo
            echo "Examples:"
            echo "  $0                   Update alogin.html with all locations"
            echo "  $0 -f status.html    Update status.html instead"
            echo "  $0 --limit 2         Only process first 2 locations"
            echo "  $0 -l 1 -f test.html Process 1 location in test.html"
            echo "  $0 --validate        Only check if pos.json is valid"
            echo
            echo "Development Usage:"
            echo "  $0 --limit 1         Quick testing with just 1 location"
            echo "  $0 -l 2              Test with minimal locations"
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
            check_pos_file
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