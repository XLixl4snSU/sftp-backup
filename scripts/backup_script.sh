#!/bin/sh
# DO NOT MODIFY THIS LINE 5M7AnOtp5R8XZlcgkQrSntFgW6gXgm7M
# Test
#Test2
if [ -z $backup_bwlimit ]
then
  backup_bwlimit=4M
fi
datum=$(date +%F)
sshfs -p $backup_port -o BatchMode=yes,IdentityFile=/home/ssh/ssh_host_rsa_key,StrictHostKeyChecking=accept-new,_netdev,reconnect $backup_nutzername@$backup_adresse:/ /mnt/sftp/
rclone sync --create-empty-src-dirs -v /mnt/sftp/backup/ /mnt/lokal/ --bwlimit $backup_bwlimit --log-file /config/logs/duplicati-sftp-$datum.log --stats 30s
cp /config/logs/duplicati-sftp-$datum.log /mnt/sftp/statistik/duplicati-sftp-$datum.log
umount -lf /mnt/sftp/
echo Backup beendet.
