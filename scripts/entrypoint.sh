#!/bin/bash

# Import output library
. /home/scripts/global_functions.sh

shutdown () {
  info "Shutting down gracefully..."
  echo "------------ End container log ------------"
  echo
  exit 0
}

if [ -z "$TZ" ]
then
  export TZ=Europe/Berlin
fi

trap shutdown SIGTERM SIGINT
echo "">/var/log/container.log
echo "------------ Start container log ------------"

/home/scripts/cron_update.sh
/home/scripts/selfcheck.sh
selfcheck_status=$?

if ( exit $selfcheck_status)
then
  ok "Selfcheck passed. Container is running."
  echo
  tail -F /var/log/container.log 2> /dev/null &
  wait $!
else
  error "Stopping container..."
  exit 0
fi