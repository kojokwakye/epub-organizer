#!/bin/bash
# EPUB File Organizer - Dash Separator Version
# Creates author folders and moves files (handles "Title - Author" format)
# Usage: ./organize_epub.sh [directory_path] [--dry-run]

# Set default values
EPUB_DIR="${1:-.}"
DRY_RUN=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [directory_path] [--dry-run]"
            echo "Options:"
            echo "  directory_path    Directory containing EPUB files (default: current directory)"
            echo "  --dry-run        Show what would be done without actually moving files"
            echo "  --help, -h       Show this help message"
            echo ""
            echo "Expected filename format: 'Title - Author.epub'"
            exit 0
            ;;
        *)
            if [ -z "$EPUB_DIR" ] || [ "$EPUB_DIR" = "." ]; then
                EPUB_DIR="$1"
            fi
            shift
            ;;
    esac
done

# Check if directory exists
if [ ! -d "$EPUB_DIR" ]; then
    echo "Error: Directory '$EPUB_DIR' does not exist."
    exit 1
fi

# Function to sanitize directory names
sanitize_dirname() {
    local name="$1"
    # Remove leading/trailing whitespace
    name=$(echo "$name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    # Replace problematic characters with underscores
    name=$(echo "$name" | sed 's/[\/\\:*?"<>|]/_/g')
    # Remove multiple consecutive spaces/underscores
    name=$(echo "$name" | sed 's/[[:space:]_]\+/_/g')
    # Limit length to 200 characters (safe filesystem limit)
    name=$(echo "$name" | cut -c1-200)
    echo "$name"
}

# Initialize counters
total_files=0
organized_files=0
failed_files=0

if [ "$DRY_RUN" = true ]; then
    echo "DRY RUN MODE - No files will be moved"
    echo "======================================"
fi

echo "Organizing EPUB files in: $EPUB_DIR"
echo "Expected format: 'Title - Author.epub'"
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
    
    # Check if filename contains " - " (space-dash-space)
    if [[ "$filename" == *" - "* ]]; then
        # Extract author name (everything after the last " - ")
        author="${filename##* - }"
        
        # Extract title (everything before the last " - ")
        title="${filename% - *}"
        
        # Clean up author name
        author=$(sanitize_dirname "$author")
        
        if [ -z "$author" ]; then
            echo "  ✗ Author name is empty after parsing"
            failed_files=$((failed_files + 1))
        else
            # Create author directory if it doesn't exist
            author_dir="$EPUB_DIR/$author"
            
            if [ "$DRY_RUN" = true ]; then
                echo "  [DRY RUN] Would create directory: $author"
                echo "  [DRY RUN] Would move to: $author/"
                organized_files=$((organized_files + 1))
            else
                if [ ! -d "$author_dir" ]; then
                    if mkdir -p "$author_dir"; then
                        echo "  Created directory: $author"
                    else
                        echo "  ✗ Failed to create directory: $author"
                        failed_files=$((failed_files + 1))
                        echo ""
                        continue
                    fi
                fi
                
                # Move the file to the author directory
                if mv "$file" "$author_dir/"; then
                    echo "  ✓ Moved to: $author/"
                    organized_files=$((organized_files + 1))
                else
                    echo "  ✗ Failed to move file"
                    failed_files=$((failed_files + 1))
                fi
            fi
        fi
    else
        echo "  ✗ Could not parse author from filename (no ' - ' found)"
        echo "    Expected format: 'Title - Author.epub'"
        failed_files=$((failed_files + 1))
    fi
    
    echo ""
done

echo "----------------------------------------"
if [ "$DRY_RUN" = true ]; then
    echo "DRY RUN complete - no files were actually moved"
else
    echo "Organization complete!"
fi
echo "Total files processed: $total_files"
echo "Successfully organized: $organized_files"
echo "Failed to organize: $failed_files"

if [ $failed_files -gt 0 ]; then
    echo ""
    echo "Note: Files that couldn't be parsed remain in the original directory."
    echo "Expected filename format: 'Title - Author.epub'"
fi
