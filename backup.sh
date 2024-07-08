#!/bin/bash

# Function to print rainbow colored text
rainbow_text() {
    local text="$1"
    local colors=( "\e[31m" "\e[91m" "\e[93m" "\e[92m" "\e[36m" "\e[94m" "\e[35m" )  # Red, Light Red, Yellow, Green, Cyan, Blue, Purple
    local reset="\e[0m"
    local idx=0

    for (( i=0; i<${#text}; i++ )); do
        echo -ne "${colors[$idx]}${text:$i:1}"
        idx=$(( (idx + 1) % ${#colors[@]} ))
    done
    echo -e "$reset"
}

# Header
header_text="  █████╗ ██╗     ██╗██████╗ ███████╗███████╗ █████╗ ██╗  ██╗███████╗
 ██╔══██╗██║     ██║██╔══██╗██╔════╝╚══███╔╝██╔══██╗╚██╗██╔╝██╔════╝
 ███████║██║     ██║██████╔╝█████╗    ███╔╝ ███████║ ╚███╔╝ ███████╗
 ██╔══██║██║     ██║██╔══██╗██╔══╝   ███╔╝  ██╔══██║ ██╔██╗ ╚════██║
 ██║  ██║███████╗██║██║  ██║███████╗███████╗██║  ██║██╔╝ ██╗███████║
 ╚═╝  ╚═╝╚══════╝╚═╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝"

# Print the header in bright blue and bold
echo -e "\e[1;94m$(rainbow_text "$header_text")\e[0m"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if cron is installed
if ! which crontab > /dev/null; then
    echo -e "${RED}cron is not installed. Installing...${NC}"
    sudo apt-get install cron
fi

function display_menu() {
    echo -e "${BLUE}===================================${NC}"
    echo -e "${GREEN}MySQL backup management menu${NC}"
    echo -e "${YELLOW}https://github.com/alirezax5/backUpMysql${NC}"
    echo -e "${BLUE}===================================${NC}"
    echo -e "${GREEN}1) Add backup${NC}"
    echo -e "${GREEN}2) Add backup & send to telegram every 30 minutes${NC}"
    echo -e "${GREEN}3) Delete a backup${NC}"
    echo -e "${GREEN}0) Exit${NC}"
    echo -e "${BLUE}===================================${NC}"
    echo -e "${YELLOW}Enter your choice:${NC}"
}

function add_backup() {
    echo -e "${YELLOW}Enter the database name:${NC}"
    read db_name
    echo -e "${YELLOW}Enter the database username:${NC}"
    read username
    echo -e "${YELLOW}Enter the database password:${NC}"
    read -rsp "Password: " PASSWORD
    echo

    if [ ! -d "/root/backup/" ]; then
        mkdir -p /root/backup/
    fi

    # Create backup script
    backup_file="/root/backup/$(date +\%Y-\%m-\%d-\%H-\%M)_$db_name.sql"
    mysqldump -u "$username" -p"$PASSWORD" "$db_name" > "$backup_file"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Backup successfully created at $backup_file.${NC}"
    else
        echo -e "${RED}Failed to create backup.${NC}"
        return 1
    fi

    # Display status
    echo -e "${BLUE}Status:${NC}"
    echo -e "${GREEN}Backup for database '$db_name' created.${NC}"
}

function add_backup_telegram() {
    echo -e "${YELLOW}Enter the database name:${NC}"
    read db_name
    echo -e "${YELLOW}Enter the database username:${NC}"
    read username
    echo -e "${YELLOW}Enter your bot token:${NC}"
    read telegram_token
    echo -e "${YELLOW}Enter your chat id:${NC}"
    read chatid
    echo -e "${YELLOW}Enter the database password:${NC}"
    read -rsp "Password: " PASSWORD
    echo

    if [ ! -d "/root/backup/" ]; then
        mkdir -p /root/backup/
    fi

    # Create backup file name
    backup_file="/root/backup/$(date +\%Y-\%m-\%d-\%H-\%M)_$db_name.sql"

    # Create backup script
    backup_script="/root/backup/$db_name.sh"
    echo "#!/bin/bash" > "$backup_script"
    echo "backup_file=$backup_file" >> "$backup_script"
    echo "mysqldump -u $username -p$PASSWORD $db_name > \$backup_file" >> "$backup_script"
    echo 'if [ $? -eq 0 ]; then' >> "$backup_script"
    echo "  curl -s --insecure -F chat_id=$chatid -F document=@\$backup_file https://api.telegram.org/bot$telegram_token/sendDocument" >> "$backup_script"
    echo 'fi' >> "$backup_script"
    chmod +x "$backup_script"

    # Add to cron to run every 30 minutes
    (crontab -l; echo "*/30 * * * * $backup_script") | crontab -
    echo -e "${GREEN}Backup and send to Telegram every 30 minutes successfully added!${NC}"

    # Execute backup immediately
    bash "$backup_script"

    # Display status
    echo -e "${BLUE}Status:${NC}"
    echo -e "${GREEN}Backup and send to Telegram for database '$db_name' added.${NC}"
    echo -e "${YELLOW}Cron job scheduled to run every 30 minutes.${NC}"
}

function remove_backup() {
    echo -e "${YELLOW}Available backup files:${NC}"
    ls /root/backup/*.sql

    echo -e "${YELLOW}Enter the name of the backup file to delete (including full path):${NC}"
    read backup_file

    if [ ! -f "$backup_file" ]; then
        echo -e "${RED}Backup file $backup_file not found!${NC}"
        return 1
    fi

    rm -f "$backup_file"

    # Remove from cron (if exists)
    (crontab -l | grep -v "$backup_file" | crontab -)

    echo -e "${GREEN}The backup file $backup_file was deleted successfully.${NC}"
    echo -e "${GREEN}The cron task associated with this backup file has also been deleted.${NC}"

    # Display status
    echo -e "${BLUE}Status:${NC}"
    echo -e "${GREEN}Backup file '$backup_file' deleted.${NC}"
}

# Input Setting
stty -echoctl

# Menu loop
while true; do
    display_menu
    read choice

    case $choice in
        1) add_backup ;;
        2) add_backup_telegram ;;
        3) remove_backup ;;
        0) exit ;;
        *) echo -e "${RED}Invalid selection. Please try again.${NC}" ;;
    esac
done

# Restore Input Setting
stty echoctl
