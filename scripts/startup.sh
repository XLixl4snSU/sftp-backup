#!/bin/bash

if [ -z "$TZ" ]
then
  export TZ=Europe/Berlin
fi

cd /home/scripts
. ./selfcheck.sh
. ./cron_update.sh
echo "------ Start des laufenden Logs ------"> /var/log/container.log

if [ $selfcheck_fail -eq 1 ]
then
  echo "Selfcheck fehlgeschlagen! Stoppe Container..."
  exit 0
else
  echo "Selfcheck erfolgreich. Container läuft."
  tail -f --follow=name /var/log/container.log
fi
