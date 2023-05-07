#!/bin/bash

/home/scripts/backup_script.sh |& tee /config/logs/backup_script-$(date +%F).log /var/log/container.log