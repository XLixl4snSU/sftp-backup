#!/bin/bash

# Variables:
date_today=$(date "+%d.%m.%Y")

# ------- Helper Functions:--------
# Import Output Functions
. /home/scripts/global_functions.sh

sync_logs() {
    rsync_log_flags=(
        -e "ssh -p $backup_port -i /home/ssh/id_rsa"
        -r
        $logs_folder
        $backup_user@$backup_server:$sftp_logs_folder
    )
    rsync "${rsync_log_flags[@]}"
}

background_sync() {
    if [ ! "$background_sync_running" = true ]; then
        background_sync_running=true
        while true; do
            sync_logs
            sleep $backup_logsync_intervall &
            wait
        done
    fi
}

end() {
    echo "---------------   End of backup log $date_today   ---------------------------------------"
    echo
    pkill -KILL -P $sync_pid
    kill $sync_pid
    sync_logs
    ok "Synced logs."
    /home/scripts/list_backups.sh > /dev/null 2>&1 &
    exit
}

run_rsync() {
    echo "$backup_start_date" > $dest_folder.running_backup
    echo "$last_backup" >> $dest_folder.running_backup
    rsync_flags=(
        -e "ssh -p $backup_port -i /home/ssh/id_rsa"
        -rtvq
        --delete
        --stats
        --progress
        --log-file=$logs_folder"rsync-"$backup_start_date".log"
        $backup_rsync_custom_flags
        $backup_user@$backup_server:$sftp_backup_folder
        $dest_folder$backup_start_date
    )
    while :
    do
        rsync "${rsync_additional_flags[@]}" "${rsync_flags[@]}" && break
        error "rsync reported an error. Trying again in 60s... (If this error reappears multiple times there could be something wrong with the configuration or the connection.)"
        sleep 60
    done
    ok "rsync finished successfully"
    rm -rf $dest_folder.running_backup
    cleanup_and_storage_info
}

initial_backup() {
    mkdir -p $dest_folder$backup_start_date
    run_rsync
}

incremental_backup() {
    get_last_backup
    rsync_additional_flags=(
        --link-dest=$dest_folder$last_backup/
    )
    run_rsync
}

resume_backup() {
    last_backup="$(head -2 $dest_folder.running_backup | tail +2)"
    rsync_additional_flags=(
        --link-dest=$dest_folder$last_backup/
    )
    run_rsync
}

get_last_backup() {
    days=0
    match="false"
    while [ "$match" = "false" ]; do
        date=$(date --date "$search_from_date $days day ago" +%F)
        if [ -d $dest_folder$date ]; then
            if [ "$date" = "$backup_start_date" ]; then
                info "There is already a backup from today. Updating today's backup."
            else 
                info "There is already a backup from $date. Creating incremental backup."
                mkdir -p $dest_folder$backup_start_date
            fi
            last_backup=$date
            match="true"
        else
            days=$(($days + 1))
        fi
    done
}

cleanup_and_storage_info() {
    # Delete old backups
    list=""
    do_not_delete=""
    days=0
    found=0
    match="false"
    total_backups="$(find $dest_folder -maxdepth 1 -regextype posix-egrep -regex '.*[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}$' | wc -l)"
    while [ "$found" -lt "$backup_retention_number" ] && [ $found -lt "$total_backups" ]; do
        # Get all folders that aren't deleted (depending on retention)
        date=$(date --date "$days day ago" +%F)
        if [ -d $dest_folder$date ]; then
            list=$(convert_date_to_readable $date)" "$list
            do_not_delete=$do_not_delete"-not -name $date "
            found=$(($found + 1))
        fi
        days=$(($days + 1))
    done
    echo
    storage_information
    echo
    info "Keeping the following backups: $list"
    # Delete backups out of retention
    to_delete=$(find $dest_folder -mindepth 1 -type d -regextype "egrep" -regex "^.*/[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}$" $do_not_delete)
    if [ -n "$to_delete" ]; then
        info "Deleting backups out of retention (keeping last $backup_retention_number backups): $(remove_newlines "$(remove_path_from_filename "$(convert_date_to_readable "$to_delete")")")"
        rm -r $to_delete
    else
        ok "No backups need to be deleted. ($found of $backup_retention_number (retention) backups found)."
    fi
    ok "Backup script finished successfully."
    end
}

#Check if Selfcheck is still running

if pgrep -x "selfcheck.sh" > /dev/null ; then
    error "Healthcheck still running, please wait until healtcheck has finished."
    exit 1
fi
if pgrep -x "backup_script.sh" > /dev/null ; then
    error "Backup Script already running, exting."
    exit 1
fi

/home/scripts/list_backups.sh > /dev/null 2>&1 &

# ------- Start of Backup --------
# Start intervall sync of logs
background_sync > /dev/null 2>&1 &
sync_pid=$!

echo "---------------   Start backup log $date_today (Using v$backup_version)   -------------------------"
info "Starting Backup-Script..."
info "Using bandwith limit: $backup_bwlimit"
if rsync -q -e "ssh -p $backup_port -i /home/ssh/id_rsa" $backup_user@$backup_server:$sftp_backup_folder ; then
    ok "Connected successfully to SFTP-Server"
else
    error "There was an error establishing the SFTP connection or the backup folder is missing."
    error "Please check and try again."
    end
fi

sync_logs

while true ; do
    rsync -q -e "ssh -p $backup_port -i /home/ssh/id_rsa" $backup_user@$backup_server:$sftp_backup_folder"file.lock" &>/dev/null
    if [ $? -ne 0 ]; then
        ok "No lockfile deteced. Starting backup."
        break
    fi
    warn "Lockfile detected. Checking again in $lock_delay seconds."
    sleep $lock_delay
done

# Check for unfinished backups
if [ -f "$dest_folder.running_backup" ]; then
    running_backup=$(head -n 1 $dest_folder.running_backup)
    if cat $dest_folder.running_backup | grep -qE '[0-9]{4}-[0-9]{2}-[0-9]{2}' && [ -d $dest_folder$running_backup ]; then
        warn "Unfinished backup from $running_backup found. Continuing this backup."
        search_from_date=$running_backup
        backup_start_date=$running_backup
        resume_backup
    else
    warn "Running backup file corrupted. Deleting file."
    rm "$dest_folder.running_backup"
    fi
fi

backup_start_date=$(date +%F)
# Use grep to check for existing Backups
if ls $dest_folder | grep -qE '[0-9]{4}-[0-9]{2}-[0-9]{2}'; then
    incremental_backup
    # Initial Backup (if no existing one is found)
else
    info "No existing backup found. Creating initial full backup."
    initial_backup
fi
