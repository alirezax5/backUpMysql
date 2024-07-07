#!/bin/bash

# Checking cron installation
if ! which crontab > /dev/null; then
    echo "cron is not installed. Installing..."
    sudo apt-get install cron
fi
function display_menu() {
    echo "==================================="
    echo "MySQL backup management menu"
    echo "https://github.com/alirezax5/backUpMysql"
    echo "==================================="
    echo "1) Add backup"
    echo "2) delete the backup"
    echo "3) Exit"
    echo "==================================="
    echo "Enter your choice:"
}
function add_backup() {
    # add backup
              echo "Enter the database name:"
              read db_name
              echo "Enter the database username:"
              read username
              echo "Enter the database password:"
              read password

               if [ ! -d "/root/backup/shell/" ]; then
               mkdir -p /root/backup/shell/
               fi
              # creating shell
              backup_script="/root/backup/shell/$db_name.sh"

              echo "#!/bin/bash" > $backup_script
              echo "mysqldump -u $username -p $password $db_name > /root/backup/$(eval echo date +%Y-%m-%d-%H-%M)_"$db_name".sql" >> $backup_script
              chmod +x $backup_script

              # add to cron
             (crontab -l; echo "0 0 */30 * * $backup_script" ) | crontab -
              echo "Backup successfully added!"

  }
function remove_backup() {
    echo "Available backup files:"
    ls /root/backup/shell/

    echo "Enter the name of the backup file to delete:"
    read backup_file

    if [ ! -f "/root/backup/shell/$backup_file" ]; then
        echo "Backup file $backup_file not found!"
        return 1
    fi

    rm -f /root/backup/shell/$backup_file

    (crontab -l | grep -v "$backup_file" | crontab -)

    echo "The backup file $backup_file was deleted successfully."
    echo "The cron task associated with this backup file has also been deleted."
}

# menu
while true; do
    display_menu
    read choice

    case $choice in
        1) add_backup ;;
        2) remove_backup ;;
        3) exit ;;
        *) echo "Invalid selection. Please try again." ;;
    esac
done
