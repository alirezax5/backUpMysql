#!/bin/bash

# Checking cron installation
if ! which crontab > /dev/null; then
    echo "cron is not installed. Installing..."
    sudo apt-get install cron
fi

# menu
while true; do
    echo "1. Add backup"
    echo "2. Delete the backup"
    echo "3. Exit"
    echo "Enter your choice:"
    read choice

    case $choice in
        1)
            # add backup
            echo "Enter the database name:"
            read db_name
            echo "Enter the database username:"
            read username
            echo "Enter the database password:"
            read password

            # creating shell
            backup_script="/root/backup/shell/$backup_name.sh"
            echo "#!/bin/bash" > $backup_script
            echo "mysqldump -u $username root -p $password $db_name  > /root/backup/$backup_name.sql" >> $backup_script
            chmod +x $backup_script

            # add to cron
            crontab -e
            echo "0 0,30 * * * $backup_script" >> crontab
            echo "Backup successfully added!"
            ;;
        2)
            # حذف بکاپ
            echo "Available backup files:"
            ls /root/backup/shell/*.sh

            echo "Enter the name of the backup file to delete:"
            read backup_name

            # حذف فایل بکاپ و cron مربوطه
            backup_script="/root/backup/shell/$backup_name.sh"
            if [ -f $backup_script ]; then
                rm $backup_script
                crontab -e
                sed "/$backup_script/d" crontab > crontab.tmp
                mv crontab.tmp crontab
                echo "The corresponding backup and cron files have been deleted!"
            else
                echo "The backup file $backup_name was not found!"
            fi
            ;;
        3)
            # خروج
            echo "You have exited the program."
            exit 0
            ;;
        *)
            echo "Invalid selection. Please try again."
            ;;
    esac
done
