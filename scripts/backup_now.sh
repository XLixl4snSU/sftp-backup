#!/bin/bash
trap abort INT

abort() {
    rm /tmp/backup.lock
}

flock -n /tmp/backup.lock /home/scripts/start_backup.sh 