#!/bin/sh
# DO NOT MODIFY THIS LINE 5M7AnOtp5R8XZlcgkQrSntFgW6gXgm7M

# Editable Variables:
backup_cron_freq="15 5 * * *"
setup_cron_freq="5 0 * * *"

if [ -z "$backup_manuelle_frequenz" ]
then
  echo Keine manuelle Cron-Frequenz gesetzt, verwende Standardfrequenz: $backup_cron_freq
else
  backup_cron_freq=$backup_manuelle_Frequenz
  echo Manuelle Cron-Frequenz gesetzt, diese wird verwendet und lautet $backup_cron_freq
fi

cronedit () {
  crontab -l > cron.temp
  sed -i '/\/home\/scripts\/backup_script.sh/d' cron.temp
  echo "$backup_cron_freq /home/scripts/backup_script.sh">>cron.temp
  sed -i '/\/home\/scripts\/setup.sh/d' cron.temp
  echo "$setup_cron_freq /home/scripts/setup.sh">>cron.temp
  crontab cron.temp
  rm -f cron.temp
  echo Crontab aktualisiert. Starte crond.
  crond -b
}

cronedit
