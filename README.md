


![](https://img.shields.io/github/workflow/status/XLixl4snSU/sftp-backup/Docker?style=flat-square)
![](https://img.shields.io/github/release-date/XLixl4snSU/sftp-backup?style=flat-square)
![](https://img.shields.io/docker/v/butti/sftp-backup/latest?style=flat-square)
![](https://img.shields.io/docker/image-size/butti/sftp-backup/latest?style=flat-square)
![](https://img.shields.io/docker/pulls/butti/sftp-backup?style=flat-square)

 <br>
 <a href="https://github.com/XLixl4snSU/sftp-backup"><img src="https://github.githubassets.com/images/modules/logos_page/GitHub-Logo.png" height="40"></a>    &nbsp;&nbsp;&nbsp;   <a href="https://hub.docker.com/r/butti/sftp-backup"><img src="https://www.docker.com/wp-content/uploads/2022/03/horizontal-logo-monochromatic-white.png" height="40" ></a>
 <br><br>
 
## Overview
- [Features](#Features)
- [Requirements, Installation and Setup](#Requirements,-Installation-and-Setup)
	- [Where to get the Image](#Where-to-get-the-Image)
	- [Build locally](#Build-locally)
	- [First Start](#First-Start)
- [Environment variables and volumes](#Environment-variables-and-volumes) 
- [ Running the container](#Running-the-container)

## Features
This project is the base for a docker container that provides the possibility to create local backups from a remote SFTP-Host with rsync. It's customized for my personal use, but it can be used by anybody.

**Core-Features:**

 - Docker base image: Alpine Linux
 - Very lightweight (<10mb compressed docker image)
 - Backups of files on a remote SFTP-Server on time a day
 - Rudimentary incremental Backups with a custom retention period in days
 - Authentication by SSH-Keys
 - Easily accessible Logs with extensive information of the process
## Requirements, Installation and Setup
This project is the base of of Docker container. You can pull the image from DockerHub and GitHub Container Repository, but also build it locally.
### Requirements:
 - Docker installed on your host machine. See https://docs.docker.com/engine/install/ for instructions.
 - SFTP-Server that supports authentication via RSA-SSH-Keys (basically all should do)
	 - folder `backup/` in the users root directory
		 - this is where you mount the data that you want to back up
		 - you should configure this folder to be **read-only** by the SFTP-user
	 - optionally (but highly recommended) folder `logs/` in the users root directory
		 - this is where logs are saved to from the remote container
		 - this needs to be configured **read-write**



### Where to get the Image
|Registry| Name |
|--|--|
|[Github Container Registry](https://github.com/XLixl4snSU/sftp-backup/pkgs/container/sftp-backup)|`ghcr.io/xlixl4snsu/sftp-backup`
| [Dockerhub](https://hub.docker.com/r/butti/sftp-backup) | `butti/sftp-backup` |

The container is build via GitHub Actions and automatically pushed to the repositories (updating the :latest tag and creating a semver tag like :1.0.1).
If you use the latest version (which is the default when pulling with no :tag) you can install updates just by pulling the image and recreating the container.
### Build locally
This is only for advanced users.
Download a release, extract it and run the following command in the root folder:

    docker build .

### First Start
You have to run the container with the **privileged** flag, otherwise the fuse mount won't work (and therefore also the container).

See [Environment variables and volumes](#Environment-variables-and-volumes) for the flags you need to run the container.

Example:

    docker run --privileged --name sftp-backup -e "backup_port=2025" -e "backup_user=myusername" -e "backup_address=sftp.domain.com" -v "/path/to/local/folder/config:/config" -v "/path/to/local/folder/local:/mnt/local/" -d butti/sftp-backup:latest
    

When you start the container for the first time, it will create **SSH-Keys** (if they don't already exist). These will be located in your mounted config-folder.
It is possible to use your own **RSA-SSH-Keys**. They have to be named `id_rsa` (private key) and `id_rsa.pub` (public key). Make sure they are in the correct format, because they won't be checked atm. It is always a good practice to let the container generate them for you. 
You now have to use this public key and add it as a authentication method on your server. See the documentation of the SFTP-Server you are using on how to do it. It is **not possible** to use a password to authenticate for security reasons.

The container will **always stop** after start if the startup script can't successfully establish a connection to the SFTP-Server.
If you haven't provided keys beforehand it is therefore expected for the container to stop after the first start. Just start it again once your SFTP-Server is configured to use the public key.

Make sure that the folder `backup` exists in the root folder of your SFTP-User (see [requirements](#requirements)).
If you want to get the logs that are created by the backup script on your SFTP-Server, you can create a folder `logs` in your SFTP-Users root directory. Logs will be synced to this location before and after each backup.


## Environment variables and volumes

|Mandatory volumes|Host path|Container path|
|--|--|--| 
|backup folder|as you wish|/mnt/local|
|config folder (SSH-Keys & Logs)|as you wish|/config|
---
|Variable|Format|Mandatory?|Info|Default value
|--|--|--|--|--|
|backup_server|domain.com \| IP|Ja| URL or IP of the SFTP server|-
|backup_port|Zahl (0-65535)|Ja|Port SFTP server|-
|backup_user|String|Ja|SFTP username|-
|backup_bwlimit|number and unit|Optional|Bandwith limit during the backup. Always add a unit, e.g. M = Megabyte|4M
|backup_frequency|See Crontab |Optional|See https://crontab.guru|10 3 * * *
|backup_retention_number|int| Optional|Keeps last X (daily) Backups|7
|TZ|Continent/City|Optional|Timezone (see [Wikipedia](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones))|Europe/Berlin

Mandatory variables have to be declared, otherwise the container will stop after a healthcheck.


## Running the container
The container **won't stop** if a backup fails or the SFTP server isn't reachable anymore. You therefore have to check logs regularly.
If theres a file `file.lock` in the `backup/` folder on the SFTP server the script will wait until the files is deleted (check every 60 seconds).
This is useful if you for example backup a backup and you don't want to transfer incomplete or inconsistent data. 
Just create a file called `file.lock`for the duration the contents of the directory are changed and remove it afterwards (easy to automate if you for example use a script).

#### Backup functionality:

- The backups are structured in folders named  `YYYY-MM-DD`
- If there is no folder following this convention at all, the script will create a new full backup
- Every following backup will use hard links to the latest backup 
- Because this container uses hard links you can delete any `YYYY-MM-DD`  folder you want, this won't affect the remaining backups
- After backup execution the script will delete any backups that exceed the defined `backup_retention_number` (from oldest to newest)
- If you already have a local backup you can move it in the mounted folder and rename it in the sheme used by the container: `YYYY-MM-DD` to the current date, so for example `2022-10-24`. This backup will now be used as a base for the incremental backups.
- Please not that if there's an rsync error in the backup process, the incomplete backup will be deleted to keep data integrety. The script won't try again automatically (until it's executed again by cron).
- **Limitation**: There will only be one backup per day, as this is how the scripts are designed. Even if you modify the cronjob to run multiple times a day, the existing backup will just be overwritten, but not saved separately.
	- You can on the other hand use a crontab format that creates backups less often than every day, for example every two days or every week
- You can run `docker exec sftp-backup backup-now` to manually start a backup
