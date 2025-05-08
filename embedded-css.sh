#!/bin/bash

# embedded-css.sh - Embeds css/app.css content directly into HTML files
# Usage: 
#   ./embedded-css.sh        - Embeds CSS
#   ./embedded-css.sh -d     - Deletes embedded CSS

# Check for delete flag
DELETE_MODE=false
if [ "$1" = "-d" ] || [ "$1" = "--delete" ]; then
    DELETE_MODE=true
    echo "Running in DELETE mode - will remove embedded CSS"
fi

# Process each file
for file in login.html alogin.html; do
    echo "Processing $file..."
    
    # Create backup of the original file
    cp "$file" "${file}.bak"
    
    # Check if CSS is already embedded
    if grep -q "<!-- CSS-DIRECTLY-EMBEDDED -->" "$file"; then
        echo "Found embedded CSS in $file. Removing..."
        # Remove the embedded CSS
        sed -i '/<!-- CSS-DIRECTLY-EMBEDDED -->/,/<!-- END-CSS-DIRECTLY-EMBEDDED -->/d' "$file"
        echo "Removed embedded CSS from $file"
    else
        echo "No embedded CSS found in $file"
    fi
    
    # If we're not in delete mode, embed the CSS
    if [ "$DELETE_MODE" = false ]; then
        # Check if css/app.css exists
        if [ ! -f "css/app.css" ]; then
            echo "Error: css/app.css file not found"
            mv "${file}.bak" "$file"  # Restore backup
            continue
        fi
        
        # Create temporary files for splitting
        before_head=$(mktemp)
        after_head=$(mktemp)
        
        # Find the line number containing </head>
        head_line=$(grep -n "</head>" "$file" | head -1 | cut -d: -f1)
        
        if [ -z "$head_line" ]; then
            echo "Error: Could not find </head> tag in $file"
            mv "${file}.bak" "$file"  # Restore backup
            continue
        fi
        
        # Split the file at the </head> line
        head -n $((head_line - 1)) "$file" > "$before_head"
        tail -n +$head_line "$file" > "$after_head"
        
        # Create the new file with CSS embedded
        {
            cat "$before_head"
            echo " "
            echo "<style type="text/css">"
            cat css/app.css
            echo " "
            echo "</style>"
            cat "$after_head"
        } > "$file.new"
        
        # Verify and replace original file
        if [ -s "$file.new" ]; then
            mv "$file.new" "$file"
            echo "Successfully embedded CSS in $file"
        else
            echo "Error: Generated file is empty. Restoring original $file"
            rm -f "$file.new"
            mv "${file}.bak" "$file"
        fi
        
        # Clean up temporary files
        rm -f "$before_head" "$after_head"
    fi
done

if [ "$DELETE_MODE" = true ]; then
    echo "CSS removal completed!"
else
    echo "CSS embedding completed!"
fi