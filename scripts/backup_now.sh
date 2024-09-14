#!/bin/bash

. /home/scripts/global_functions.sh

trap abort INT
abort() {
    rm /tmp/backup.lock
}

backup_running() {
    error "There is already  backup running. Exiting."
    exit 1
}

(
flock -n 200 || backup_running
ok "Starting backup script."
/home/scripts/backup_script.sh |& tee /config/logs/backup_script-$(date +%F).log /var/log/container.log
) 200>/tmp/backup.lock