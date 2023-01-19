#!/bin/bash

# Variables:
date_today=$(date "+%d.%m.%Y")

# Functions:
# Import Output Functions

. /home/scripts/global_functions.sh

sync_logs() {
    if [ -d "$remote_logs_folder" ]; then
        rsync -r $logs_folder $remote_logs_folder
    fi
}

end() {
    echo "------------ End of backup log $date_today ------------"
    echo
    sync_logs
    umount -lf /mnt/sftp/
    exit 0
}

backup_error() {
    error "Rsync reports an error. Logs:"
    cat $logs_folder"rsync-"$today".log"
    error "Deleting faulty backup."
    rm -rf $dest_folder$today
    error "Backup unsuccessful!"
    end
}

echo "------------ Start backup log $date_today (Using v$backup_version)------------"
info "Starting Backup-Script..."
info "Using bandwith limit: $backup_bwlimit"
info "Mounting SFTP folder."
# SFTP:
mount_sftp
# Check Mountpoint:
if mountpoint -q -- "$sftp_folder"; then
    if [ ! -d "$sftp_backup_folder" ]; then
        error "Sucessfully connted via SFTP, but mandatory folder \"backup/\" is missing!"
        error "Please check and try again."
        end
    else
        ok "Sucessfully mounted SFTP folder."
    fi
else
    error "Error connection via SFTP. Folder could not be mounted. Aborting..."
    error "Backup unsuccessful!"
    end
fi

sync_logs

while [ -f "$sftp_backup_folder"file.lock"" ]; do
    warn "Lockfile detected. Checking again in $lock_delay seconds."
    sleep $lock_delay
done

# Use grep to check for existing Backups
if ls $dest_folder | grep -qE '[0-9]{4}-[0-9]{2}-[0-9]{2}'; then
    days=0
    match="false"
    while [ "$match" = "false" ]; do
        date=$(date --date "$days day ago" +%F)
        if [ -d $dest_folder$date ]; then
            info "There is already a backup from $date. Creating incremental backup."
            last_backup=$date
            match="true"
        else
            days=$(($days + 1))
        fi
    done
    today=$(date +%F)
    mkdir -p $dest_folder$today
    rsync -avq --no-perms --delete --timeout=30 --stats --log-file $logs_folder"rsync-"$today".log" --bwlimit $backup_bwlimit --link-dest=$dest_folder$last_backup/ $sftp_backup_folder $dest_folder$today
    rsync_result=$?
    info "rsync finished. Checking result..."
    if [ "$rsync_result" -eq "0" ]; then
        ok "Incremental Backup created successfully."
    else
        backup_error
    fi

    # Initial Backup
else
    today=$(date +%F)
    mkdir -p $dest_folder$today
    info "No existing backup found. Creating initial full backup."
    rsync -avq --no-perms --delete --timeout=30 --stats --log-file $logs_folder"rsync-"$today".log" --bwlimit $backup_bwlimit $sftp_backup_folder $dest_folder$today
    rsync_result=$?
    info "rsync finished. Checking result..."
    if [ "$rsync_result" -eq "0" ]; then
        ok "Initial full backup created successfully."
    else
        backup_error
    fi
fi

# Sync Logs
sync_logs

# Delete old backups
list=""
do_not_delete=""
days=0
found=0
match="false"
while [ "$found" -lt "$backup_retention_number" ] && [ $days -le "365" ]; do
    # Get all folders that aren't deleted (depending on retention)
    date=$(date --date "$days day ago" +%F)
    if [ -d $dest_folder$date ]; then
        list=$(convert_date_to_readable $date)" "$list
        do_not_delete=$do_not_delete"-not -name $date "
        found=$(($found + 1))
    fi
    days=$(($days + 1))
done

info "Keeping the following backups: $list"
# Delete backups out of retention
to_delete=$(find $dest_folder -mindepth 1 -type d -regextype "egrep" -regex "^.*/[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}$" $do_not_delete)
if [ -n "$to_delete" ]; then
    info "Deleting backups out of retention (keeping last $backup_retention_number backups): $to_delete"
    rm -r $to_delete
else
    ok "No backups need to be deleted. ($found of $backup_retention_number (retention) backups found)."
fi
echo
info "Storage Information:"
echo "Total: $(du -sh $dest_folder | awk '{print $1}'), actual size distribution of individual folders:"
echo
echo "$(remove_path_from_filename "$(convert_date_to_readable "$(du -sh $dest_folder*)")")"
echo
echo "Size of each backup:"
echo
for d in $dest_folder*; do
    if [ -d "$d" ] && [[ $d =~ ^.*/[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}$ ]]; then
        echo $(convert_date_to_readable $(du -sh $d | awk -F" +|/" '{print $NF}'))": "$(du -sh $d | awk '{print $1}')
    fi
done
echo
df -h $dest_folder
echo
ok "Backup script finished successfully."
end