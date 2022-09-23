#!/bin/sh
# DO NOT MODIFY THIS LINE 5M7AnOtp5R8XZlcgkQrSntFgW6gXgm7M
# Test
#Test2
echo Start Backup-Script...
if [ -z $backup_bwlimit ]
then
  backup_bwlimit=4M
fi
echo Verwende Bandbreitenlimit: $backup_bwlimit
echo Binde SFTP-Verzeichnis ein.
sshfs -p $backup_port -o BatchMode=yes,IdentityFile=/home/ssh/ssh_host_rsa_key,StrictHostKeyChecking=accept-new,_netdev,reconnect $backup_nutzername@$backup_adresse:/ /mnt/sftp/
while [ -f "/mnt/sftp/backup/file.lock" ]
do
  echo Lock-Datei erkannt. Prüfe erneut in 60 Sekunden.
  sleep 60
done
datum=$(date +%F)
echo Starte Backup. Logs sind zu finden unter logs/duplicati-sftp-$datum.log
rclone sync --create-empty-src-dirs -v /mnt/sftp/backup/ /mnt/lokal/ --bwlimit $backup_bwlimit --log-file /config/logs/duplicati-sftp-$datum.log --stats 120s
echo Backup beendet. Kopiere Logdatei auf Server...
cp /config/logs/duplicati-sftp-$datum.log /mnt/sftp/statistik/duplicati-sftp-$datum.log
umount -lf /mnt/sftp/
echo Backup-Script beendet.


