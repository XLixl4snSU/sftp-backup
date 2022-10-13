#!/bin/bash

flock -n /tmp/backup.lock /home/scripts/backup_script.sh >> /config/logs/backup_script-$(date +%F).log 2>&1; rsync -a /config/logs/ /mnt/sftp/statistik/; umount -lf /mnt/sftp/
