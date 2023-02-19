#!/bin/bash
sftp_backup_folder="/mnt/sftp/backup/"
sftp_folder="/mnt/sftp/"
remote_logs_folder="/mnt/sftp/logs/"
dest_folder="/mnt/local/"
logs_folder="/config/logs/"
lock_delay=60

default_backup_retention_number=7
default_backup_bwlimit=4M
default_backup_logsync_intervall=10

set_defaults() {
  for var in "$@"; do
    default_key="default_$var"
    if [ -z "${!var}" ]; then
      export $var=${!default_key}
    fi
  done
}

set_defaults backup_retention_number backup_bwlimit backup_logsync_intervall

time_now () {
  date "+%T"
}
date_and_time() {
    date "+%d.%m.%Y %T"
}
convert_date_to_readable() {
  string=$1
  pattern="(.*)([[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2})(.*)"
  while [[ $string =~ $pattern ]]; do
    date=$(date -d ${BASH_REMATCH[2]} "+%d.%m.%Y")
    string=${BASH_REMATCH[1]}$date${BASH_REMATCH[3]}
  done
  echo "$string"
}

remove_path_from_filename() {
  string="$1"
  for part in $string; do
    base=$(basename "$part")
    string="${string/"$part"/"$base"}"
  done
  echo "$string"
}

remove_newlines() {
  string="$1"
  echo "${string//$'\n'/ }"
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
  sshfs -v -p $backup_port -o BatchMode=yes,IdentityFile=/home/ssh/id_rsa,StrictHostKeyChecking=accept-new,_netdev,reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,ConnectTimeout=20 $backup_user@$backup_server:/ $sftp_folder
}