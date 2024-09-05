#!/bin/sh

# Function to display the help menu with evenly spaced text
show_help() {
    printf "Usage: %s [OPTION] AMOUNT\n\n" "$0"
    printf "Generate lorem ipsum text.\n\n"
    
    printf "%-25s %-40s\n" "Options:" ""
    printf "  %-20s %s\n" "-w, --words" "Generate a specified amount of words"
    printf "  %-20s %s\n" "-p, --paragraphs" "Generate a specified amount of paragraphs"
    printf "  %-20s %s\n" "-h, --help" "Display this help menu"
    printf "\n"
    
    printf "%-25s %-40s\n" "Example:" ""
    printf "  %-20s %s\n" "$0 -w 100" "Generate 100 words"
    printf "  %-20s %s\n" "$0 -p 3" "Generate 3 paragraphs"
    exit 0
}

# Default values
FORMAT=""
AMOUNT=""

# Parse options using case
while [ "$#" -gt 0 ]; do
    case "$1" in
        -w|--words)
            FORMAT="words"
            AMOUNT="$2"
            shift 2
            ;;
        -p|--paragraphs)
            FORMAT="paragraphs"
            AMOUNT="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            ;;
        -*)
            echo "Error: Invalid option $1" >&2
            show_help
            ;;
        *)
            echo "Error: Unexpected argument $1" >&2
            show_help
            ;;
    esac
done

# Ensure required arguments are provided
if [ -z "$FORMAT" ] || [ -z "$AMOUNT" ]; then
    echo "Error: Missing required arguments." >&2
    show_help
fi

# Generate the lorem ipsum text
TEXT=$(nvim --headless -c "lua print(require('lorem').$FORMAT($AMOUNT))" +qall | tail -n +1)
echo "$TEXT"

