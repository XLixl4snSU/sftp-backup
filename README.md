![](https://img.shields.io/github/workflow/status/XLixl4snSU/sftp-backup/Docker?style=for-the-badge)
![enter image description here](https://img.shields.io/github/release-date/XLixl4snSU/sftp-backup?style=for-the-badge)   ![enter image description here](https://img.shields.io/docker/v/butti/sftp-backup?style=for-the-badge) ![enter image description here](https://img.shields.io/docker/image-size/butti/sftp-backup?style=for-the-badge) ![enter image description here](https://img.shields.io/docker/pulls/butti/sftp-backup?style=for-the-badge)
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
 - Backups von Dateien eines SFTP-Servers zu einem definierbaren Zeitpunkt täglich
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
|Variable|Format|Notwendig?|Info
|--|--|--|--|
|backup_adresse|backup.example.com|Ja| SFTP-Server-URL
|backup_port|12345|Ja|Port des SFTP-Servers
|backup_nutzername|user123|Ja|SFTP-Nutzername
|backup_bwlimit|4MB|Optional|Bandbreitenlimit während des Backups.Immer mit Angabe der Einheit, z.B. MB = Megabyte
|backup_manuelle_frequenz|10 3 * * *|Optional|Format nach Crontab, siehe https://crontab.guru, aktuell standardmäßig um 03:10 Uhr|

Sind notwendige Umgebungsvariablen nicht oder falsch deklariert **stoppt** der Container nach einem Selbsttest.


## Laufender Betrieb
Dieser Container **stoppt nicht**, wenn ein Backup fehlschlägt oder der SFTP-Server nicht erreichbar ist. 

Befindet sich zum avisierten Zeitpunkt des Backups eine Datei `file.lock` im Verzeichnis `backup/`wird die ausführung des Backups so lange um jeweils 60 Sekunden verschoben, bis die Datei nicht mehr existiert.

Die Ausführung des Backups erfolgt mittels cron. Ein Lockfile sorgt dafür, dass der Cronjob nicht mehrmals gleichzeitig ausgeführt wird.

Dieser Container **speichert Logdateien** im Ordner /config/logs: Diese sind aktuell bei Bedarf manuell zu löschen.
