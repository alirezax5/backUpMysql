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

# Function to clear the terminal
clear_terminal() {
    clear
    echo -e "\e[1;94m$(rainbow_text "$header_text")\e[0m"
}

# Check if cron is installed
if ! which crontab > /dev/null; then
    echo -e "${RED}cron is not installed. Installing...${NC}"
    sudo apt-get install cron
fi

# Function to parse time strings
parse_time() {
    local time_str="$1"
    local value="${time_str:0:-1}"
    local unit="${time_str: -1}"
    local minutes

    case "$unit" in
        m) minutes="$value" ;;
        h) minutes=$((value * 60)) ;;
        d) minutes=$((value * 1440)) ;;  # 1440 minutes in a day
        M) minutes=$((value * 43200)) ;; # 43200 minutes in a month (30 days)
        *) echo -e "${RED}Invalid time format.${NC}" && return 1 ;;
    esac

    echo "$minutes"
}

function display_menu() {
    clear_terminal
    echo -e "${BLUE}===================================${NC}"
    echo -e "${GREEN}MySQL backup management menu${NC}"
    echo -e "${YELLOW}https://github.com/alirezax5/backUpMysql${NC}"
    echo -e "${BLUE}Spetial Thanks To ${GREEN}Mr.HamidRouter${NC}"
    echo -e "${BLUE}===================================${NC}"
    echo -e "${GREEN}1) Add backup${NC}"
    echo -e "${GREEN}2) Add backup & send to telegram${NC}"
    echo -e "${GREEN}3) Delete a backup${NC}"
    echo -e "${GREEN}0) Exit${NC}"
    echo -e "${BLUE}===================================${NC}"
    echo -e "${YELLOW}Enter your choice:${NC}"
}

function add_backup() {
    clear_terminal
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
    clear_terminal
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
    echo -e "${YELLOW}Enter the backup interval (e.g., 30m, 1h, 1d, 1M):${NC}"
    read interval

    # Parse the time interval
    minutes=$(parse_time "$interval")
    if [ $? -ne 0 ]; then
        return 1
    fi

    if [ ! -d "/root/backup/" ]; then
        mkdir -p /root/backup/
    fi

    # Create backup file name
    backup_file="/root/backup/$(date +\%Y-\%m-\%d-\%H-\%M)_$db_name.sql"

    # Create backup script
    backup_script="/root/backup/$db_name.sh"
    echo "#!/bin/bash" > "$backup_script"
    echo "backup_file=/root/backup/\$(date +\%Y-\%m-\%d-\%H-\%M)_$db_name.sql" >> "$backup_script"
    echo "mysqldump -u $username -p$PASSWORD $db_name > \$backup_file" >> "$backup_script"
    echo 'if [ $? -eq 0 ]; then' >> "$backup_script"
    echo "  curl -s --insecure -F chat_id=$chatid -F document=@\$backup_file https://api.telegram.org/bot$telegram_token/sendDocument" >> "$backup_script"
    echo 'fi' >> "$backup_script"
    chmod +x "$backup_script"

    # Add to cron
    cron_expr="*/$minutes * * * * $backup_script"
    (crontab -l; echo "$cron_expr") | crontab -
    echo -e "${GREEN}Backup and send to Telegram every $interval successfully added!${NC}"

    # Execute backup immediately
    bash "$backup_script"

    # Display status
    echo -e "${BLUE}Status:${NC}"
    echo -e "${GREEN}Backup and send to Telegram for database '$db_name' added.${NC}"
    echo -e "${YELLOW}Cron job scheduled to run every $interval.${NC}"
}

function remove_backup() {
    clear_terminal
    # Display available databases
    echo -e "${YELLOW}Available databases for backup:${NC}"
    backup_files=(/root/backup/*.sql)
    db_names=()

    for backup_file in "${backup_files[@]}"; do
        db_name=$(basename "$backup_file" | sed -r 's/^.*_[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}_(.*)\.sql$/\1/')
        db_names+=("$db_name")
    done

    # Remove duplicate database names
    unique_db_names=($(printf "%s\n" "${db_names[@]}" | sort -u))

    for db_name in "${unique_db_names[@]}"; do
        echo -e "${GREEN}$db_name${NC}"
    done

    echo -e "${YELLOW}Enter the name of the database to delete backups for (e to exit):${NC}"
    read db_name

    if [ "$db_name" == "" ]; then
        return
    elif [ "$db_name" == "e" ]; then
        exit
    fi

    # Find and delete backup files
    backup_files=($(ls /root/backup/*_"$db_name".sql 2>/dev/null))

    if [ ${#backup_files[@]} -eq 0 ]; then
        echo -e "${RED}No backup files found for database '$db_name'!${NC}"
        echo -e "${YELLOW}Press any key to continue...${NC}"
        read -n 1 -s
        return
    fi

    # Confirmation before deletion
    echo -e "${YELLOW}Are you sure you want to delete all backup files for '$db_name'? (y/n):${NC}"
    read confirm

    if [ "$confirm" != "y" ]; then
        echo -e "${YELLOW}Deletion canceled.${NC}"
        echo -e "${YELLOW}Press any key to continue...${NC}"
        read -n 1 -s
        return
    fi

    for backup_file in "${backup_files[@]}"; do
        rm -f "$backup_file"

        # Remove from cron (if exists)
        (crontab -l | grep -v "$backup_file" | crontab -)

        echo -e "${GREEN}The backup file $backup_file was deleted successfully.${NC}"
        echo -e "${GREEN}The cron task associated with this backup file has also been deleted.${NC}"
    done

    # Display status
    echo -e "${BLUE}Status:${NC}"
    echo -e "${GREEN}All backup files for database '$db_name' deleted.${NC}"
    echo -e "${YELLOW}Press any key to continue...${NC}"
    read -n 1 -s
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

    echo -e "${BLUE}Spetial Thanks To ${GREEN}Mr.HamidRouter${NC}"
    echo -e "${GREEN}1) Go back to main menu${NC}"
    echo -e "${GREEN}0) Exit${NC}"
    echo -e "${BLUE}=========================${NC}"
    echo -e "${YELLOW}Enter your choice:${NC}"
    read choice

    if [ "$choice" -eq 0 ]; then
        exit
    fi
done

# Restore Input Setting
stty echoctl