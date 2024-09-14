#!/bin/bash

# Import output library
. /home/scripts/global_functions.sh

#Functions
echo_key () {
  info "Using Public Key:"
  echo
  echo $(cat /config/id_rsa.pub)
  echo
}

check_sftp_folder () {
  folder="$1"
  if rsync -q -e "ssh -p $backup_port -i /home/ssh/id_rsa -o StrictHostKeyChecking=no -o BatchMode=yes" $backup_user@$backup_server:$folder
  then
    ok "Connected via SFTP and found folder $folder"
    return 0
  else
    error "Couldn't connect via SFTP or folder $folder is missing!"
    return 1
  fi
}

info "Starting Selfcheck."
info "Starting OliveTine"

OliveTin &

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
  ok "Successfully generated keys. Stopping container. Please use the following public key:"
  echo_key
  exit 1
fi

info "Checking SFTP connection."
if check_sftp_folder $sftp_backup_folder && check_sftp_folder $sftp_logs_folder ; then
  ok "Connection tested successfully."
  exit 0
else
  error "See above errors for details."
  selfcheck_fail=1
  exit 1
fi