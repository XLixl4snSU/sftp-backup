#!/bin/bash

# Editable Variables:
sftp_backup_folder="/mnt/sftp/backup/"
sftp_folder="/mnt/sftp/"
stat_folder="/mnt/sftp/statistik/"
dest_folder="/mnt/lokal/"
logs_folder="/config/logs/"
lock_delay=60
default_retention_number=7
default_bwlimit=4M

date_today=$(date "+%d.%m.%Y %T")

d () {
date "+%d.%m.%Y %T"
}

echo "------ Start Backup-Log vom $date_today ------"
echo $(d)": Starte Backup-Script..."

# Setze Standardwerte falls keine ENV durch Nutzer gesetzt wird
if [ -z $backup_bwlimit ]
then
  backup_bwlimit=$default_bwlimit
fi

if [ -z $backup_retention_number ]
then
  backup_retention_number=$default_retention_number
fi

echo $(d)": Verwende Bandbreitenlimit: $backup_bwlimit"
echo $(d)": Binde SFTP-Verzeichnis ein."
set -x
sshfs -v -p $backup_port -o BatchMode=yes,IdentityFile=/home/ssh/ssh_host_rsa_key,StrictHostKeyChecking=accept-new,_netdev,reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,ConnectTimeout=20 $backup_nutzername@$backup_adresse:/ $sftp_folder
set +x
if [ ! -d "$sftp_backup_folder" ]
then
  echo $(d)": Fehler bei der SSH-Verbindung! Ordner konnte nicht eingebunden werden. Breche ab."
  umount -lf $sftp_folder
  exit 0
fi

rsync -r $logs_folder $stat_folder

while [ -f "$sftp_backup_folder"file.lock"" ]
do
  echo $(d)": Lock-Datei erkannt. Prüfe erneut in $lock_delay Sekunden."
  sleep $lock_delay
done

# Prüfe per Grep ob bereits Backup-Ordner im Format vorhanden sind.
# Wenn vorhanden, inkrimentelles Backup
if ls $dest_folder | grep -qE '[0-9]{4}-[0-9]{2}-[0-9]{2}'
then
  days=0
  match="false"
  while [ "$match" = "false" ]
  do
    date=$(date --date "$days day ago" +%F)
    if [ -d $dest_folder$date ]
    then
      echo $(d)": Es existiert bereits ein Backup von $date. Inkrementelles Backup wird erstellt."
      last_backup=$date
      match="true"
    else
      days=$(($days+1))
    fi
  done
  heute=$(date +%F)
  mkdir -p $dest_folder$heute
  rsync -avq --no-perms --delete --timeout=30 --stats --log-file $logs_folder"rsync-"$heute".log" --bwlimit $backup_bwlimit --link-dest=$dest_folder$last_backup/ $sftp_backup_folder $dest_folder$heute
  rsync_result=$?
  echo $(d)": rsync beendet. Prüfe Backup..."
  if [ "$rsync_result" -eq "0" ]
  then
    echo $(d)": Inkrementelles Backup erfolgreich beendet. Kopiere Logdatei auf Server..."
  else
    echo $(d)": Fehler! rsync meldet Fehler! Logs:"
	cat $logs_folder"rsync-"$heute".log"
	echo $(d)": Lösche fehlerhaftes Backup!"
	rm -rf $dest_folder$heute
	cp -rf $logs_folder"rsync-"$heute".log" $stat_folder"rsync-"$heute".log"
	exit 0
   fi

# Initiales Backup
else
  heute=$(date +%F)
  mkdir -p $dest_folder$heute
  echo $(d)": Es existiert noch kein Backup. Erstelle initiales Backup. Logs unter "$logs_folder"rsync-"$heute".log"
  rsync -avq --no-perms --delete --timeout=30 --stats --log-file $logs_folder"rsync-"$heute".log" --bwlimit $backup_bwlimit $sftp_backup_folder $dest_folder$heute
  rsync_result=$?
  echo $(d)": rsync beendet. Prüfe Backup..."
  if [ "$rsync_result" -eq "0" ]
  then
    echo $(d)": Initiales Backup beendet. Kopiere Logdatei auf Server..."
  else
    echo $(d)": Fehler! rsync meldet Fehler! Logs:"
	cat $logs_folder"rsync-"$heute".log"
	echo $(d)": Lösche fehlerhaftes Backup und beende Script!"
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
echo $(d)": Folgende Backups werden behalten: $list"
# Alle anderen Ordner löschen

to_delete=$(find $dest_folder -mindepth 1 -type d $do_not_delete)
if [ -n "$to_delete" ]
then
  echo $(d)": Lösche alle anderen Ordner (behalte letzte $backup_retention_number Sicherungen): $to_delete"
  find $dest_folder -mindepth 1 -type d -regextype "egrep" -regex "^.*/[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}$" $do_not_delete -exec rm -r {} +
else
  echo $(d)": Es müssen keine alten Backups gelöscht werden ($found von $backup_retention_number (Retention) Sicherungen vorhanden)."
fi

echo $(d)": Größe der Backup-Verzeichnisse: " $(du -sh $dest_folder) "(gesamt) Einzeln:"
du -sh $dest_folder*
echo $(d)": Backup-Script beendet."
rsync -r /config/logs/ /mnt/sftp/statistik/
umount -lf /mnt/sftp/
echo "------ Ende Backup-Log vom $date_today  ------"
