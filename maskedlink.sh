#!/bin/bash

#----------------------------#
#        MASKED LINK v2     #
#----------------------------#
# Features:
# - Menu-based Interface
# - Tool Checks with Install Help
# - Masked URL Validation & Preview
# - History Saving and Logging
# - Optional QR Code via Online API

# Color Codes
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
WHITE='\033[1;37m'
NC='\033[0m' # Reset

# Branding Banner
echo -e "${GREEN}"
cat << 'EOF'
 ___  ___  ___   _____ _   __ ___________ _     _____ _   _  _   __
|  \/  | / _ \ /  ___| | / /|  ___|  _  \ |   |_   _| \ | || | / /
| .  . |/ /_\ \\ `--.| |/ / | |__ | | | | |     | | |  \| || |/ / 
| |\/| ||  _  | `--. \    \ |  __|| | | | |     | | | . ` ||    \ 
| |  | || | | |/\__/ / |\  \| |___| |/ /| |_____| |_| |\  || |\  \
\_|  |_/\_| |_/\____/\_| \_/\____/|___/ \_____/\___/\_| \_/\_| \_/
EOF
echo -e "${NC}"

# File paths
HISTORY_FILE="masked_links_history.txt"
LOG_FILE="maskedlink.log"

# Static English messages
MSG_ENTER_URL="Please enter the target URL:"
MSG_INVALID_URL="Invalid URL. Please use full http or https URL including a valid domain."
MSG_SUCCESS="Here is your masked link:"
MSG_CHOOSE_OPTION="Choose an option:"

# Check required tools
check_tools() {
    MISSING=0
    for tool in curl xdg-open; do
        if ! command -v $tool &>/dev/null; then
            echo -e "${RED}[✘] $tool not found.${NC}"
            echo -e "${YELLOW}Install it with: sudo apt install $tool${NC}"
            MISSING=1
        else
            echo -e "${GREEN}[✔] $tool found${NC}"
        fi
    done

    if command -v xclip &>/dev/null || command -v pbcopy &>/dev/null; then
        echo -e "${GREEN}[✔] Clipboard support found${NC}"
    else
        echo -e "${YELLOW}[!] No clipboard tool found (xclip/pbcopy).${NC}"
    fi

    [[ $MISSING -eq 1 ]] && echo -e "${RED}Please install missing tools and re-run.${NC}" && exit 1
}

# URL validation
is_valid_url() {
    [[ "$1" =~ ^https?://.+\..+ ]]
}

# Shorten URL using TinyURL
shorten_url() {
    curl -s "https://tinyurl.com/api-create.php?url=$1"
}

# Save to history & log
save_history() {
    echo "$1" >> "$HISTORY_FILE"
    echo "[`date`] $2 - $1" >> "$LOG_FILE"
}

# Live check for URL
check_live() {
    if curl --output /dev/null --silent --head --fail "$1"; then
        echo -e "${GREEN}[✔] Shortened URL is reachable.${NC}"
    else
        echo -e "${RED}[✘] Shortened URL is NOT reachable.${NC}"
    fi
}



# Optional QR code via API
generate_qr() {
    echo -en "${BLUE}Do you want a QR code? (y/n): ${NC}"
    read qr_choice
    if [[ "$qr_choice" =~ ^[Yy](es)?$ ]]; then
        qr_url="https://api.qrserver.com/v1/create-qr-code/?data=$1&size=300x300"
        xdg-open "$qr_url" 2>/dev/null || open "$qr_url"
    fi
}

# Masking process
mask_url() {
    echo -e "\n${WHITE}$MSG_ENTER_URL${NC}"
    while true; do
        echo -n "Phishing URL (with http/https): "
        read phish
        if is_valid_url "$phish"; then break
        else echo -e "${RED}$MSG_INVALID_URL${NC}"; fi
    done

    short=$(shorten_url "$phish")
    shorter=${short#https://}
    shorter=${shorter#http://}

    echo -e "\nLegit-looking domain to mask with (e.g., https://google.com):"
    while true; do
        read -p "Mask Domain: " mask
        if is_valid_url "$mask"; then break
        else echo -e "${RED}$MSG_INVALID_URL${NC}"; fi
    done

    echo -e "\nSocial Engineering keywords (e.g., free-money):"
    while true; do
        read -p "Keywords (no spaces, use -): " words
        if [[ "$words" =~ [[:space:]] ]]; then
            echo -e "${RED}[!] Spaces are not allowed. Please use '-' instead of spaces.${NC}"
        else
            break
        fi
    done

    if [[ -z "$words" ]]; then
        final="$mask@$shorter"
    else
        final="$mask-$words@$shorter"
    fi

    echo -e "\n${GREEN}$MSG_SUCCESS ${final}${NC}"
    echo -e "\nSaving and checking..."

    save_history "$final" "$phish"
    check_live "https://$shorter"
    

    # Copy to clipboard
    if command -v xclip &>/dev/null; then
        echo -n "$final" | xclip -selection clipboard
        echo -e "${YELLOW}[✔] Copied to clipboard (xclip)${NC}"
    elif command -v pbcopy &>/dev/null; then
        echo -n "$final" | pbcopy
        echo -e "${YELLOW}[✔] Copied to clipboard (pbcopy)${NC}"
    fi

    generate_qr "$final"
}

# Show history
show_history() {
    if [[ -f "$HISTORY_FILE" ]]; then
        echo -e "${BLUE}--- Masked Link History ---${NC}"
        cat "$HISTORY_FILE"
    else
        echo -e "${RED}[!] No history found.${NC}"
    fi
}

# Menu system
main_menu() {
    while true; do
        echo -e "\n${WHITE}=========== MASKED LINK MENU ===========${NC}"
        echo -e "1. Mask a new phishing link"
        echo -e "2. View masking history"
        echo -e "3. Exit"
        echo -ne "${BLUE}$MSG_CHOOSE_OPTION ${NC}"
        read choice

        case $choice in
            1) mask_url ;;
            2) show_history ;;
            3) echo -e "${YELLOW}Exiting...${NC}"; exit ;;
            *) echo -e "${RED}Invalid option. Try again.${NC}" ;;
        esac
    done
}

# ----------- Script Starts Here -----------
check_tools
main_menu
