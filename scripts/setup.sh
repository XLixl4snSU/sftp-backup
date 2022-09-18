#!/bin/sh
# DO NOT MODIFY THIS LINE 5M7AnOtp5R8XZlcgkQrSntFgW6gXgm7M

# Editable Variables:



download () {
  test=10
  if [ $counter -le $test ]
    then
      wget -O $1_temp https://raw.githubusercontent.com/XLixl4snSU/sftp-backup/main/scripts/$1
    if grep 5M7AnOtp5R8XZlcgkQrSntFgW6gXgm7M "$1_temp";
    then
      counter=0
    else
      counter=$((counter + 1))
      slee 10
      download $1
    fi
  else
    exit
  fi
}
check () {
  if [ -f $1 ]
  then
    hash_akt=$(md5sum "$1" | cut -d ' ' -f 1)
    hash_neu=$(md5sum "$1_temp" | cut -d ' ' -f 1)
    if [ "$hash_akt" = "$hash_neu" ]
    then
      echo Version aktuell \($1\).
      rm $1_temp
    else
      rm -f backup_script.sh
      mv $1_temp $1
      chmod +x $1
      echo Update erfolgreich \($1\).
      if [ $1 = "cron_update.sh" ]
      then
        ./cron_update.sh
      fi
    fi
  else
    mv $1_temp $1
    chmod +x $1
    echo Erster Setup erfolgreich \($1\).
    if [ $1 = "cron_update.sh" ]
    then
      ./cron_update.sh
    fi
  fi
}

cd /home/scripts
counter=0
download backup_script.sh
check backup_script.sh
download setup.sh
check setup.sh
download cron_update.sh
check cron_update.sh
download startup.sh
check startup.sh
download selfcheck.sh
check selfcheck.sh
