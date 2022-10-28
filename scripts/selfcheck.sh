#!/bin/bash

# Set variables
retry_delay=5m
retry_count=12

# Import output library
. /home/scripts/global_functions.sh

#Functions
echo_key () {
  info "Using Public Key:"
  echo
  echo $(cat /config/id_rsa.pub)
  echo
}

info "Starting Selfcheck."
mkdir -p /config/logs
if [ -f "/config/id_rsa.pub" ] && [ -f "/config/id_rsa" ]; then
  ok "Keys already exist. Using existing keys.."
  rm -rf /home/ssh/*
  cp /config/id_rsa* /home/ssh/
  echo_key
else
  info "No existing keys found, generating keys."
  rm -rf /home/ssh/* /config/id_rsa*
  ssh-keygen -t rsa -b 4096 -f ssh_host_rsa_key -q -N ""  -f /home/ssh/id_rsa  < /dev/null
  cp /home/ssh/id_rsa* /config/
  ok "Success generation keys. Stopping container. Please use key:"
  echo_key
  exit 1
fi
info "Checking SFTP connection..."

mount_sftp
sleep 1


check_sftp () {
  mountpoint -q $sftp_folder
  return
}

check_sftp_backup_folder () {
  if [ ! -d "$sftp_backup_folder" ]
  then
    error "Sucessfully connted via SFTP, but mandatory folder \"backup/\" is missing!"
    error "Please check your configuration and try again!"
    umount -lf /mnt/sftp/
    selfcheck_fail=1
    exit 1
  else
    ok "SFTP configuration ok."
    umount -lf /mnt/sftp/
    exit 0
  fi
}

info "Checking mounted folders..."
if check_sftp
then
  check_sftp_backup_folder
else
  error "Couldn't mount SFTP folder."
  warn "Trying again in $retry_delay for $retry_count times!"
  try=1
  while [ "$try" -le "$retry_count" ]
  do
    sleep $retry_delay
    warn "Starting retry $try/$retry_count..."
    try=$((try + 1))
    mount_sftp
    sleep 1
    if check_sftp
    then 
      check_sftp_backup_folder
    fi
    if [ "$try" -lt "$retry_count" ]
    then
      warn "Retry failed. Trying again in $retry_delay."
    fi
  done
  error "SFTP folder couldn't be mounted at last try."
  exit 1
fi