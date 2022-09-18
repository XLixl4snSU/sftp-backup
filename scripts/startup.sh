#!/bin/sh
# DO NOT MODIFY THIS LINE 5M7AnOtp5R8XZlcgkQrSntFgW6gXgm7M

# Editable Variables:
cd /home/scripts
. ./setup.sh
. ./selfcheck.sh
if [ $selfcheck_fail -eq 1 ]
then
echo Selfcheck fehlgeschlagen! Stoppe Container...
exit 0
else
/bin/sh
fi
