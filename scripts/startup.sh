#!/bin/sh
# DO NOT MODIFY THIS LINE 5M7AnOtp5R8XZlcgkQrSntFgW6gXgm7M

# Editable Variables:

if [ -z "$TZ" ]
then
  export TZ=Europe/Berlin
fi

cd /home/scripts
. ./selfcheck.sh
. ./cron_update.sh

if [ $selfcheck_fail -eq 1 ]
then
  echo "Selfcheck fehlgeschlagen! Stoppe Container..."
  exit 0
else
  echo "Selfcheck erfolgreich. Container läuft."
  /bin/sh
  sleep infinity
fi
