#!/bin/bash

if [ -z "$TZ" ]
then
  export TZ=Europe/Berlin
fi

cd /home/scripts
. ./selfcheck.sh
. ./cron_update.sh
echo "------------ Start container log ------------"> /var/log/container.log

if [ $selfcheck_fail -eq 1 ]
then
  echo "Selfcheck failed! Stopping container..."
  exit 0
else
  echo "Selfcheck passed."
  echo
  tail -F /var/log/container.log 2> /dev/null
fi
