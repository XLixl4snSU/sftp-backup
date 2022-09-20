#!/bin/sh
# DO NOT MODIFY THIS LINE 5M7AnOtp5R8XZlcgkQrSntFgW6gXgm7M

echo Selfcheck starten.
mkdir /config/logs
if [ -f "/config/public_key" ] && [ -f "/config/private_key" ]; then
    echo "Key existiert. Dieser wird weiterhin verwendet."
	cp /config/public_key /home/ssh/ssh_host_rsa_key.pub
	cp /config/private_key /home/ssh/ssh_host_rsa_key
else
    echo Key wird neu erstellt und kopiert.
	rm -rf /home/ssh/*
	rm -rf /config/public_key
	rm -rf /config/private_key
	cd /home/ssh
	ssh-keygen -t rsa -b 4096 -f ssh_host_rsa_key -q -N "" < /dev/null
	cp ssh_host_rsa_key.pub /config/public_key
	cp /home/ssh/ssh_host_rsa_key /config/private_key
	echo Erfolg. Container wird gestoppt. Bitte Key nutzen.
	elfcheck_fail=1
	exit 0
fi
echo Baue SFTP-Verbindung auf...
set -x
sshfs -p $backup_port -o BatchMode=yes,IdentityFile=/home/ssh/ssh_host_rsa_key,StrictHostKeyChecking=accept-new,_netdev,reconnect $backup_nutzername@$backup_adresse:/ /mnt/sftp/
set +x
sleep 2
echo Prüfe eingebundenes Verzeichnis...
if [ ! -d "/mnt/sftp/backup" ]
then
  echo Fehler! SFTP-Verzeichnis ist nicht korrekt eingebunden!
  echo Konfiguration Prüfen und Container erneut starten!
  umount -lf /mnt/sftp/
  selfcheck_fail=1
else
  echo Selfcheck bestanden.
  umount -lf /mnt/sftp/
  selfcheck_fail=0
fi
