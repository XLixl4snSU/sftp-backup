#!/bin/bash
sftp_backup_folder="/mnt/sftp/backup/"
sftp_folder="/mnt/sftp/"
remote_logs_folder="/mnt/sftp/logs/"
dest_folder="/mnt/local/"
logs_folder="/config/logs/"
lock_delay=60

default_retention_number=7
default_bwlimit=4M

# Set default values if not declared
if [ -z $backup_bwlimit ]
then
  export backup_bwlimit=$default_bwlimit
fi

if [ -z $backup_retention_number ]
then
  export backup_retention_number=$default_retention_number
fi

time_now () {
  date "+%T"
}
info () {
  echo "[INFO]  $(time_now): $1"
}
error () {
  echo -e "\e[31m[ERROR] $(time_now): $1\e[0m"
}
warn () {
  echo -e "\e[33m[WARN]  $(time_now): $1\e[0m"
}
ok () {
  echo -e "\e[32m[OK]    $(time_now): $1\e[0m"
}
mount_sftp () {
  #set -x
  sshfs -v -p $backup_port -o BatchMode=yes,IdentityFile=/home/ssh/id_rsa,StrictHostKeyChecking=accept-new,_netdev,reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,ConnectTimeout=20 $backup_user@$backup_server:/ $sftp_folder
  #set +x
}
