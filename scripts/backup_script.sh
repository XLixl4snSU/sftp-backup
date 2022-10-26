#!/bin/bash

# Variables:

sftp_backup_folder="/mnt/sftp/backup/"
sftp_folder="/mnt/sftp/"
stat_folder="/mnt/sftp/statistik/"
dest_folder="/mnt/local/"
logs_folder="/config/logs/"
lock_delay=60
default_retention_number=7
default_bwlimit=4M
date_today=$(date "+%d.%m.%Y")

# Set defaults if necessary

if [ -z $backup_bwlimit ]
then
  backup_bwlimit=$default_bwlimit
fi

if [ -z $backup_retention_number ]
then
  backup_retention_number=$default_retention_number
fi

# Functions:

info () {
  echo "[INFO]  $(date "+%T"): $1"
}
error () {
  echo -e "\e[31m[ERROR] $(date "+%T"): $1\e[0m"
}
warn () {
  echo -e "\e[33m[WARN]  $(date "+%T"): $1\e[0m"
}
ok () {
  echo -e "\e[32m[OK]    $(date "+%T"): $1\e[0m"
}
d () {
date "+%d.%m.%Y %T"
}

sync_logs () {
  rsync -r $logs_folder $stat_folder
}

end () {
  echo "------------ End of backup log $date_today ------------"
  echo
  sync_logs
  umount -lf /mnt/sftp/
  exit 0
}

echo "------------ Start backup log $date_today ------------"
info "Starting Backup-Script..."
info "Using bandwith limit: $backup_bwlimit"
info "Mounting SFTP folder."
# SFTP:
set -x
sshfs -v -p $backup_port -o BatchMode=yes,IdentityFile=/home/ssh/ssh_host_rsa_key,StrictHostKeyChecking=accept-new,_netdev,reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,ConnectTimeout=20 $backup_user@$backup_server:/ $sftp_folder
set +x
# Check Mountpoint:
if mountpoint -q -- "$sftp_folder"
then
  if [ ! -d "$sftp_backup_folder" ]
  then
    error "Sucessfully connted via SFTP, but mandatory folder \"backup/\" is missing!"
    error "Please check and try again."
    end
  else
    ok "Sucessfully mounted SFTP folder."
  fi
else
  error "Error connection via SFTP. Folder could not be mounted. Aborting..."
  end
fi

sync_logs

while [ -f "$sftp_backup_folder"file.lock"" ]
do
  warn "Lockfile detected. Checking again in $lock_delay seconds."
  sleep $lock_delay
done

# Use grep to check for existing Backups
if ls $dest_folder | grep -qE '[0-9]{4}-[0-9]{2}-[0-9]{2}'
then
  days=0
  match="false"
  while [ "$match" = "false" ]
  do
    date=$(date --date "$days day ago" +%F)
    if [ -d $dest_folder$date ]
    then
      info "There is already a backup from $date. Creating incremental backup."
      last_backup=$date
      match="true"
    else
      days=$(($days+1))
    fi
  done
  today=$(date +%F)
  mkdir -p $dest_folder$today
  rsync -avq --no-perms --delete --timeout=30 --stats --log-file $logs_folder"rsync-"$today".log" --bwlimit $backup_bwlimit --link-dest=$dest_folder$last_backup/ $sftp_backup_folder $dest_folder$today
  rsync_result=$?
  info "rsync finished. Checking result..."
  if [ "$rsync_result" -eq "0" ]
  then
    ok "Incremental Backup created successfully."
  else
    error "Rsync reports an error. Logs:"
	cat $logs_folder"rsync-"$today".log"
	error "Deleting faulty backup."
	rm -rf $dest_folder$today
	exit 0
   fi

# Initial Backup
else
  today=$(date +%F)
  mkdir -p $dest_folder$today
  info "No existing backup found. Creating initial full backup."
  rsync -avq --no-perms --delete --timeout=30 --stats --log-file $logs_folder"rsync-"$today".log" --bwlimit $backup_bwlimit $sftp_backup_folder $dest_folder$today
  rsync_result=$?
  info "rsync finished. Checking result..."
  if [ "$rsync_result" -eq "0" ]
  then
    ok "Initial full backup created successfully."
  else
    error error "Rsync reports an error. Logs:"
	cat $logs_folder"rsync-"$today".log"
	error "Deleting faulty backup."
	rm -rf $dest_folder$today
	end
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
while [ "$found" -lt "$backup_retention_number" ] && [ $days -le "365" ]
do
  # Get all folders that aren't deleted (depending on retention)
  date=$(date --date "$days day ago" +%F)
  if [ -d $dest_folder$date ]
  then 
    list=$date" "$list
    do_not_delete=$do_not_delete"-not -name $date "
        found=$(($found+1))
  fi
  days=$(($days+1))
done
info "Keeping the following backups: $list"
# Delete backups out of retention
to_delete=$(find $dest_folder -mindepth 1 -type d -regextype "egrep" -regex "^.*/[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}$" $do_not_delete)
if [ -n "$to_delete" ]
then
  info "Deleting backups out of retention (keeping last $backup_retention_number backups): $to_delete"
  rm -r $to_delete
else
  ok "No backups need to be deleted. ($found of $backup_retention_number (retention) backups found)."
fi

info "Size of lokal backup folder: $(du -sh $dest_folder)"
echo
info "Individual backup folders:"
du -sh $dest_folder*
echo
info "Storage usage:"
df -h $dest_folder
echo
ok "Backup script finished successfully."
end
