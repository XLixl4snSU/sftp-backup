#!/bin/bash
dest_folder="/mnt/local/"
logs_folder="/config/logs/"

default_lock_delay=300
default_sftp_backup_folder="/backup/"
default_sftp_logs_folder="/logs/"
default_backup_retention_number=7
default_backup_logsync_intervall=60

set_defaults() {
  for var in "$@"; do
    default_key="default_$var"
    if [ -z "${!var}" ]; then
      export $var=${!default_key}
    fi
  done
}

set_defaults backup_retention_number backup_logsync_intervall sftp_backup_folder sftp_logs_folder lock_delay

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

storage_information() {
  echo "------------  Storage Information  ------------------"
  echo "Total: $(du -sh $dest_folder | awk '{print $1}'), actual size distribution of individual folders:"
  echo
  echo "$(remove_path_from_filename "$(convert_date_to_readable "$(du -sh $dest_folder* | grep -E '[0-9]{4}-[0-9]{2}-[0-9]{2}')")")" | awk '{print $2 ": " $1}'
  echo
  echo "Total size of each backup independently:"
  echo
  for d in $dest_folder*; do
      if [ -d "$d" ] && [[ $d =~ ^.*/[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}$ ]]; then
          echo $(convert_date_to_readable $(du -sh $d | awk -F" +|/" '{print $NF}'))": "$(du -sh $d | awk '{print $1}')
      fi
  done
  echo
  df -h $dest_folder
  echo "------------  End of Storage Information  -----------"
}

check_backup_script_status() {
  if pgrep "backup_script" > /dev/null || pgrep "backup-now" > /dev/null || pgrep "backup_now" > /dev/null; then
  ok "Backup script is currently running."
  else
  info "Backup script not running."
  fi
}

cleanup_logs() {
 echo Test 
}

purge_old_logs() {
  days="$1"
  if [ -z "${days}" ]; then
    error "Not purging logs. No value provided."
  else
    ok "Starting purge of logs older than $days days."
    purge_date=$(date -d "now - $days days" +%s)
    log_date_list=()
    count=0
    pattern="(.*)([[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2})(.*)"
    for f in /config/logs/*; do
        if [[ $f =~ $pattern ]]; then
            #log_date_list+=(${BASH_REMATCH[2]})
            converted_date=$(date -d "${BASH_REMATCH[2]}" +%s)
            if [ "$converted_date" -lt "$purge_date" ]; then
              info "Deleting $f"
              rm "$f"
              count=$((count + 1))
            fi
        fi
    done
    /home/scripts/list_backups.sh
    ok "Purging of logs older than $days days completed. $count files deleted."
  fi
}
