#!/bin/sh
# DO NOT MODIFY THIS LINE 5M7AnOtp5R8XZlcgkQrSntFgW6gXgm7M

# Editable Variables:

sftp_folder="/mnt/sftp/backup/"
stat_folder="/mnt/sftp/statistik/"
dest_folder="/mnt/lokal/"
logs_folder="/config/logs/"
lock_delay=60
default_retention_number=7
default_bwlimit=4M

echo $(date)": Starte Backup-Script..."

# Setze Standardwerte falls keine ENV durch Nutzer gesetzt wird
if [ -z $backup_bwlimit ]
then
  backup_bwlimit=$default_bwlimit
fi

if [ -z $backup_retention_number ]
then
  backup_retention_number=$default_retention_number
fi

echo "Verwende Bandbreitenlimit: $backup_bwlimit"
echo "Binde SFTP-Verzeichnis ein."

sshfs -v -p $backup_port -o BatchMode=yes,IdentityFile=/home/ssh/ssh_host_rsa_key,StrictHostKeyChecking=accept-new,_netdev,reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,ConnectTimeout=20 $backup_nutzername@$backup_adresse:/ /mnt/sftp/

if [ ! -d "$sftp_folder" ]
then
  echo "Fehler bei der SSH-Verbindung! Ordner konnte nicht eingebunden werden. Breche ab."
  umount -lf /mnt/sftp/
  exit 0
fi

cp -rf $logs_folder* $stat_folder

while [ -f "$sftp_folder"file.lock"" ]
do
  echo "Lock-Datei erkannt. Prüfe erneut in $lock_delay Sekunden."
  sleep $lock_delay
done

# Prüfe per Grep ob bereits Backup-Ordner im Format vorhanden sind.
if ls $dest_folder | grep -qE '[0-9]{4}-[0-9]{2}-[0-9]{2}'
then
  days=0
  match="false"
  while [ "$match" = "false" ]
  do
    date=$(date --date "$days day ago" +%F)
    if [ -d $dest_folder$date ]
    then
      echo $(date)": Es existiert bereits ein Backup von $date. Inkrementelles Backup wird erstellt."
      last_backup=$date
      match="true"
    else
      days=$(($days+1))
    fi
  done
  heute=$(date +%F)
  mkdir -p $dest_folder$heute
  rsync -avq --no-perms --delete --timeout=30 --stats --log-file $logs_folder"rsync-"$heute".log" --bwlimit $backup_bwlimit --link-dest=$dest_folder$last_backup/ $sftp_folder $dest_folder$heute
  echo $(date)": Rsync beendet. Prüfe Backup..."
  size_dest=$(du $dest_folder$heute | cut -f1)
  size_origin=$(du $sftp_folder | cut -f1)
  if [ "$size_dest" -eq "$size_origin" ]
  then
    echo $(date)": Inkrementelles Backup erfolgreich beendet. Kopiere Logdatei auf Server..."
  else
    echo $(date)": Fehler! Backup stimmt nicht mit Original überein. Größe SFTP: $size_origin Größe Backup: $size_dest"
	echo $(date)": Lösche fehlerhaftes Backup!"
	rm -rf $dest_folder$heute
	cp -rf $logs_folder"rsync-"$heute".log" $stat_folder"rsync-"$heute".log"
	exit 0
   fi

else
  heute=$(date +%F)
  mkdir -p $dest_folder$heute
  echo $(date)": Es existiert noch kein Backup. Erstelle initiales Backup. Logs unter logs/duplicati-sftp-$heute.log"
  rsync -avq --no-perms --delete --timeout=30 --stats --log-file $logs_folder"rsync-"$heute".log" --bwlimit $backup_bwlimit $sftp_folder $dest_folder$heute
  size_dest=$(du $dest_folder$heute | cut -f1)
  size_origin=$(du $sftp_folder | cut -f1)
  if [ "$size_dest" -eq "$size_origin" ]
  then
     echo $(date)": Initiales Backup beendet. Kopiere Logdatei auf Server..."
  else
    echo $(date)": Fehler! Backup stimmt nicht mit Original überein. Größe SFTP: $size_origin Größe Backup: $size_dest"
	echo $(date)": Lösche fehlerhaftes Backup und beende Script!"
	rm -rf $dest_folder$heute
	cp -rf $logs_folder"rsync-"$heute".log" $stat_folder"rsync-"$heute".log"
	exit 0
   fi
fi

# Kopiere Logs
cp -rf $logs_folder"rsync-"$heute".log" $stat_folder"rsync-"$heute".log"

# Alte Backups löschen
list=""
do_not_delete=""
days=0
found=0
match="false"
while [ "$found" -lt "$backup_retention_number" ] && [ $days -le "365" ]
do
  # Sammelt alle Ordner die nicht gelöscht werden sollen (abhängig von Retention)
  date=$(date --date "$days day ago" +%F)
  if [ -d $dest_folder$date ]
  then 
    list=$date" "$list
    do_not_delete=$do_not_delete"-not -name $date "
        found=$(($found+1))
  fi
  days=$(($days+1))
done
echo $(date)": Folgende Backups werden behalten: $list"
# Alle anderen Ordner löschen

to_delete=$(find $dest_folder -type d -mindepth 1 $do_not_delete)
if [ -n "$to_delete" ]
then
  echo $(date)": Lösche alle anderen Ordner (behalte letzte $backup_retention_number Sicherungen): $to_delete"
  find $dest_folder -type d -mindepth 1 $do_not_delete -exec rm -r {} +
else
  echo $(date)": Es müssen keine alten Backups gelöscht werden ($found von $backup_retention_number (Retention) Sicherungen vorhanden)."
fi
echo "Größe der Backup-Verzeichnisse: " $(du -sh $dest_folder) "Einzeln: "$(du -sh $dest_folder*)
echo $(date)": Backup-Script beendet."
