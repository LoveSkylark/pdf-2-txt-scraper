#!/bin/sh

# Check if i directory exists
if [ ! -d "/i" ]; then
    echo "i directory does not exist."
    exit 1
fi

# Function to convert PDF to text
convert_pdf() {
    local pdf="$1"
    local text_file="$2"
    local unlocked_pdf="$3"

    if pdftk "$pdf" dump_data 2>/dev/null | grep -q "Encrypted: yes"; then
        echo "Unlocking: $pdf"
        pdftk "$pdf" i_pw your_password o "$unlocked_pdf" 2>/dev/null
        echo "Converting to text: $unlocked_pdf"
        pdftotext "$unlocked_pdf" "$text_file" 2>/dev/null
    else
        echo "Skipping (not locked): $pdf"
        echo "Converting to text: $pdf"
        pdftotext "$pdf" "$text_file" 2>/dev/null
    fi
}

# Function to convert DOCX, ODT, and Markdown to text
convert_document() {
    local doc="$1"
    local text_file="$2"
    echo "Converting to text: $doc"
    case "$doc" in
        *.docx)
            pandoc --file-format docx "$doc" -o "$text_file" 2>/dev/null
            ;;
        *.odt)
            pandoc --file-format odt "$doc" -o "$text_file" 2>/dev/null
            ;;
        *.md)
            pandoc "$doc" -t plain -o "$text_file" 2>/dev/null
            ;;
        *)
            echo "Unsupported file type: $doc"
            ;;
    esac
}

# Process all files in the /i directory and its subdirectories
find /i -type f | while read -r file; do
    base_name=$(basename "$file")
    text_file="/o/${base_name%.*}.txt"

    case "$file" in
        *.pdf)
            unlocked_pdf="/o/${base_name%.*}.unlock.pdf"
            convert_pdf "$file" "$text_file" "$unlocked_pdf"
            ;;
        *.docx | *.odt | *.md)
            convert_document "$file" "$text_file"
            ;;
        *)
            echo "Unsupported file type: $file"
            ;;
    esac
done

echo "Processing complete. Text files are in the /o directory."