#!/bin/bash

flock -n /tmp/backup.lock /home/scripts/backup_script.sh >> /config/logs/backup_script-$(date +%F).log; cp -rf /config/logs/backup_script-$(date +%F).log /mnt/sftp/statistik/backup_script-$(date +%F).log; umount -lf /mnt/sftp/