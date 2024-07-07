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
    echo "2) Add backup & send to telegram"
    echo "3) delete the backup"
    echo "0) Exit"
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

function add_backup_telegram() {
     echo "Enter the database name:"
      read db_name
      echo "Enter the database username:"
      read username
      echo "Enter the database password:"
      read password
      echo "Enter your robot token"
      read telegram_token
      echo "Enter your chatid"
      read chatid

        if [ ! -d "/root/backup/shell/" ]; then
          mkdir -p /root/backup/shell/
        fi
              backup_scripts="/root/backup/shell/$db_name.sh"
                      echo "#!/bin/bash" > $backup_scripts
                      echo "mysqldump -u $username -p $password $db_name > /root/backup/"$db_name".sql" >> $backup_scripts
                      echo 'if [ $? -eq 0 ]; then' >> $backup_scripts
                      echo ' echo "بکاپ پایگاه داده با موفقیت انجام شد: $backup_file"' >> $backup_scripts
                      echo 'send_backup_to_telegram "$backup_file"'>> $backup_scripts
                      echo " curl -H "Authorization: Bot $telegram_token" \
                                     -F "chat_id=$chatid" \
                                     -F "document=@/root/backup/"$db_name".sql" \
                                     "https://api.telegram.org/bot$telegram_token/sendDocument"" >> $backup_scripts
                      chmod +x $backup_scripts

                      # add to cron
                     (crontab -l; echo "0 0 */30 * * $backup_scripts" ) | crontab -
                      echo "Backup successfully added!"
}
# menu
while true; do
    display_menu
    read choice

    case $choice in
        1) add_backup ;;
        2) add_backup_telegram ;;
        3) remove_backup ;;
        0) exit ;;
        *) echo "Invalid selection. Please try again." ;;
    esac
done
