#!/bin/bash

# Import output library
. /home/scripts/global_functions.sh

if [ -z "$TZ" ]
then
  export TZ=Europe/Berlin
fi

cd /home/scripts
./cron_update.sh
./selfcheck.sh
selfcheck_status=$?
echo "------------ Start container log ------------"> /var/log/container.log

if ( exit $selfcheck_status)
then
  ok "Selfcheck passed. Container is running."
  echo
  tail -F /var/log/container.log 2> /dev/null
else
  error "Stopping container..."
  exit 0
fi