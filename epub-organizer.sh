#!/bin/bash


# Set the directory to process (default to current directory)
EPUB_DIR="${1:-.}"

# Check if directory exists
if [ ! -d "$EPUB_DIR" ]; then
    echo "Error: Directory '$EPUB_DIR' does not exist."
    exit 1
fi

# Initialize counters
total_files=0
organized_files=0
failed_files=0

echo "Organizing EPUB files in: $EPUB_DIR"
echo "----------------------------------------"

# Process each epub file
for file in "$EPUB_DIR"/*.epub; do
    # Check if any epub files exist
    if [ ! -e "$file" ]; then
        echo "No .epub files found in $EPUB_DIR"
        exit 1
    fi
    
    # Get just the filename without path and extension
    filename=$(basename "$file" .epub)
    total_files=$((total_files + 1))
    
    echo "Processing: $filename"
    
    # Check if filename contains " by "
    if [[ "$filename" == *" by "* ]]; then
        # Extract author name (everything after the last " by ")
        author="${filename##* by }"
        
        # Clean up any extra whitespace
        author=$(echo "$author" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        # Create author directory if it doesn't exist
        author_dir="$EPUB_DIR/$author"
        if [ ! -d "$author_dir" ]; then
            mkdir -p "$author_dir"
            echo "  Created directory: $author"
        fi
        
        # Move the file to the author directory
        if mv "$file" "$author_dir/"; then
            echo "  ✓ Moved to: $author/"
            organized_files=$((organized_files + 1))
        else
            echo "  ✗ Failed to move file"
            failed_files=$((failed_files + 1))
        fi
    else
        echo "  ✗ Could not parse author from filename (no ' by ' found)"
        failed_files=$((failed_files + 1))
    fi
    
    echo ""
done

echo "----------------------------------------"
echo "Organization complete!"
echo "Total files processed: $total_files"
echo "Successfully organized: $organized_files"
echo "Failed to organize: $failed_files"

if [ $failed_files -gt 0 ]; then
    echo ""
    echo "Note: Files that couldn't be parsed remain in the original directory."
fi