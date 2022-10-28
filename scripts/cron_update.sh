#!/bin/bash
# Import output library
. /home/scripts/global_functions.sh

# Editable Variables:
backup_cron_freq="10 3 * * *"

if [ -z "$backup_frequency" ]
then
  info "No customized cron frequency set, using default frequency: $backup_cron_freq"
else
  backup_cron_freq=$backup_frequency
  info "Customized cron frequency set, using frequency: $backup_cron_freq"
fi
cronedit () {
  crontab -l > cron.temp
  grep -q "SHELL=/bin/bash" cron.temp||sed -i "1i SHELL=/bin/bash" cron.temp
  sed -i '/\/home\/scripts\/backup_script.sh/d' cron.temp
  echo "$backup_cron_freq flock -n /tmp/backup.lock /home/scripts/backup_script.sh |& tee -a /config/logs/backup_script-\$(date +%F).log /var/log/container.log ">>cron.temp
  crontab cron.temp
  rm -f cron.temp
  ok  "Crontab successfully updated. Starting crond."
  crond -b
}
cronedit