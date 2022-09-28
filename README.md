


![](https://img.shields.io/github/workflow/status/XLixl4snSU/sftp-backup/Docker?style=for-the-badge)
![](https://img.shields.io/github/release-date/XLixl4snSU/sftp-backup?style=for-the-badge)
![](https://img.shields.io/docker/v/butti/sftp-backup/latest?style=for-the-badge)
![](https://img.shields.io/docker/image-size/butti/sftp-backup/latest?style=for-the-badge)
![](https://img.shields.io/docker/pulls/butti/sftp-backup?style=for-the-badge)
# sftp-backup - Backup Script
**If you don't know what this project is, you won't need it.**

## Überblick
- [Features](#Features)
- [Installation und Setup](#Installation-und-Setup)
	- [Bezugsquellen](#Bezugsquellen-fertiger-Images)
	- [Selbst bauen](#Selbst-bauen)
	- [Erster Start](#Erster-Start)
- [Variablen und Volumen](#Variablen-und-Volumen)
- [Laufender Betrieb](#Laufender-Betrieb)

## Features
Es handelt sich um eine individuelle Lösung um Dateien mit einer Server-Client-Architektur zu sichern auf Dockerbasis. Hierbei hat der Client nur lesenden Zugriff auf die Daten des Servers und der Server hat keinen Zugriff auf Daten des Clients.
Das Backup wird über eine SFTP-Verbindung mittels rsync zu einer festgelegten Zeit durchgeführt

**Core-Features:**

 - Alpine Linux als Basis
 - Backups von Dateien eines SFTP-Servers zu einem definierbaren Zeitpunkt einmal täglich
 - Inkrementelle Backups mit frei wählbarer Retention-Anzahl
	 - Einzelne Backups können dank Hardlinks ohne Einfluss auf andere Backups jederzeit gelöscht werden
 - Authentication mittels SSH-Keys
 - Einfach zugänglicher Log
## Installation und Setup
Es handelt sich um einen Docker-Container. Das Image kann von Registries bezogen, aber auch lokal selbst gebaut werden.
### Bezugsquellen fertiger Images
|Bezugsquellen| Name |
|--|--|
|[Github Container Registry](https://github.com/XLixl4snSU/sftp-backup/pkgs/container/sftp-backup)|`ghcr.io/xlixl4snsu/sftp-backup`
| [Dockerhub](https://hub.docker.com/r/butti/sftp-backup) | `butti/sftp-backup` |

Der Container wird bei Release einer neuen Version auf Github **automatisch** zu den Repositories gepusht und kann sofort geupdatet werden.
### Selbst bauen
Release laden, entpacken und im Rootverzeichnis Kommando ausführen (erfordert die Installation von [Docker](https://docs.docker.com/engine/install/)):

    docker build .

### Erster Start
Der Container muss **privilegiert** (privileged) gestartet werden!

Die notwendigen [Variablen und Volumen](#Variablen-und-Volumen) müssen vor Start eingerichtet werden.

Nach dem ersten Start des Containers werden standardmäßig **SSH-Keys** erzeugt. Diese befinden sich anschließend im eingebundenen Config-Ordner.
Es können auch **eigene RSA-SSH-Keys** verwendet werden, welche sich vor Start des Containers im Config-Ordner befinden, diese müssen "private_key" sowie "public_key" heißen.

Der **Public-Key** muss dem SFTP-Server-Administrator übermittelt werden.
Dieser Container unterstützt **keine** Authentifizierung mittels Passwort. Es müssen immer SSH-Keys verwendet werden.

Der Container **stoppt immer** nach dem Start, wenn die Einbindung des SFTP-Ordners nicht erfolgreich war.
Ein Stop nach dem ersten Start ohne vorher eingefügte SSH-Keys ist daher normal (da keine erfolgreiche Authentifizierung stattfinden kann).

Innerhalb des SFTP-Root-Verzeichnisses erwartet dieser Container einen Ordner "backup/", in denen die zu sichernden Dateien liegen und einen Ordner "statistik/" in den nach Abschluss der Synchronisation der Log von Rsync übertragen wird.


## Variablen und Volumen

|Notwendige Volumen|Host-Pfad|Container-Pfad|
|--|--|--| 
|Speicherort für Backup-Daten|Frei wählbar|/mnt/lokal|
|Config-Ordner (SSH-Keys & Logs)|Frei wählbar|/config|
---
|Variable|Format|Notwendig?|Info|Standardwert
|--|--|--|--|--|
|backup_adresse|domain.com \| IP|Ja| SFTP-Server-URL|-
|backup_port|Zahl (0-65535)|Ja|Port des SFTP-Servers|-
|backup_nutzername|String|Ja|SFTP-Nutzername|-
|backup_bwlimit|Zahl mit Einheit|Optional|Bandbreitenlimit während des Backups. Mit Angabe der Einheit, z.B. MB = Megabyte|4M
|backup_manuelle_frequenz|Nach Crontab |Optional|Siehe https://crontab.guru|10 3 * * *
|backup_retention_number|Ganzzahl| Optional|Behält die letzten X täglichen Sicherungen|7
|TZ|Kontinent/Stadt|Optional|Zeitzone (siehe [Wikipedia](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones))|Europe/Berlin

Sind notwendige Umgebungsvariablen nicht oder falsch deklariert **stoppt** der Container nach einem Selbsttest.


## Laufender Betrieb
Dieser Container **stoppt nicht**, wenn ein Backup fehlschlägt oder der SFTP-Server nicht erreichbar ist. 

Befindet sich zum avisierten Zeitpunkt des Backups eine Datei `file.lock` im Verzeichnis `backup/`wird die ausführung des Backups so lange um jeweils 60 Sekunden verschoben, bis die Datei nicht mehr existiert.

Die Ausführung des Backups erfolgt einmal täglich mittels cron. Ein Lockfile sorgt dafür, dass der Cronjob nicht mehrmals gleichzeitig ausgeführt wird.

#### Backup-Funktionalität:
- Unabhängig vom Cronjob wird immer nur ein gleichzeitiges Backup des selben Tages angelegt, bei erneutem ausführen wird das bisherige Backup überschrieben
- Die Backups befinden sich in Ordnern des Formats `YYYY-MM-DD`
- Ist noch kein Ordner im Format vorhanden, erfolgt ein erstes Voll-Backup. Alle nachfolgenden Backups verwenden stets Hardlinks mit Basis des jeweils letzten Backups zur Sicherung
- Es kann jederzeit jede Backup-Version unabhängig von allen anderen Backups gelöscht werden, dies hat keinen Effekt auf andere Backup-Versionen.
- **Achtung:** im Rahmen des Backup-Scripts werden alle fremden Ordner im gewählten Backup-Verzeichnis gelöscht. Das trifft **nicht** auf einzelne Dateien zu.
- Das Script prüft nach Ausführung eines Backups ob mehr als die in `backup_retention_number` definierten Backups vorhanden sind. Wenn ja, wird das jeweils **älteste** Backup gelöscht.
- Existiert bereits vor der Nutzung ein volles Backup, kann dieses einfach in einen Ordner mit dem aktuellen Datum im Format `YYYY-MM-DD` verschoben werden. Es dient dann als Basis für zukünftige Backups.
- Backups, die am Ende des Rsync-Vorgangs nicht **exakt** in Größe dem Ursprung entsprechen werden zur Vermeidung korrupter Backups gelöscht. Ein Backup muss dann erneut erfolgen, bspw. am nächsten Tag oder manuell
- Es kann durch die Ausführung von `./backup-now` im Root-Verzeichnis jederzeit ein sofortiges Backup angestoßen werden.

Dieser Container **speichert Logdateien** im Ordner /config/logs: Diese sind aktuell bei Bedarf manuell zu löschen.