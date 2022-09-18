# Backup-Script

**If you don't know what this project is, you don't need it.**


# Container aufsetzen
## Was dieser Container macht
Es handelt sich um eine individuelle Lösung um Dateien mit einer Server-Client-Architektur zu sichern. Hierbei hat der Client nur lesenden Zugriff auf die Daten des Servers und der Server hat keinen Zugriff auf Daten des Clients.
Das Backup wird über eine SFTP-Verbindung mittels rsync zu einer festgelegten Zeit durchgeführt

## Variablen und Volumen

|Notwendige Volumen|Host-Pfad|Container-Pfad|
|--|--|--| 
|Speicherort für Backup-Daten|Frei wählbar|/mnt/lokal|
|Config-Ordner (SSH-Keys)|Frei wählbar|/config|
---
|Variable|Format|Notwendig?|Info
|--|--|--|--|
|backup_adresse|backup.example.com|Ja| Volle URL
|backup_port|12345|Ja
|backup_nutzername|user123|Ja
|backup_bwlimit|4MB|Optional|Immer mit Angabe der Einheit, MB = Megabyte
|backup_manuelle_Frequenz|0 1 * * *|Optional|Format nach Crontab, siehe https://crontab.guru|

Sind notwendige Umgebungsvariablen nicht oder falsch deklariert **stoppt** der Container nach einem Selbsttest.
## Erster Start
Nach dem ersten Start des Containers werden SSH-Keys erzeugt. Diese befinden sich anschließend im eingebundenen Config-Ordner. Diese müssen genutzt werden um die SFTP-Verbindung aufzubauen. Der Public-Key muss dem Server-Besitzer übermittelt werden.

Der Container **stoppt immer** nach dem Start, wenn die Einbindung des SFTP-Ordners nicht erfolgreich war. Innerhalb des SFTP-Root-Verzeichnisses erwartet dieser Container einen Ordner "backup/", in denen die zu sichernden Dateien liegen und einen Ordner "statistik/" in den nach Abschluss der Synchronisation der Log von Rsync übertragen wird.
## Laufender Container
Dieser Container **stoppt nicht**, wenn ein Backup fehlschlägt oder der SFTP-Server nicht erreichbar ist. 
Dieser Container updatet in einem vom Ersteller festgelegten Intervall automatisch die im Container verwendeten Scripte, tut das aber auch bei jedem Start.

Dieser Container **speichert Logdateien** im Ordner /config/logs: Diese sind aktuell bei Bedarf manuell zu löschen.

