#!/bin/bash

echo "Starting Selfcheck."
mkdir /config/logs
if [ -f "/config/id_rsa.pub" ] && [ -f "/config/id_rsa" ]; then
    echo "Key already exists. Using this key.."
	rm -rf /home/ssh/*
	cp /config/id_rsa /home/ssh/ssh_host_rsa_key.pub
	cp /config/id_rsa.pub /home/ssh/ssh_host_rsa_key
else
    echo "Key wird neu erstellt und kopiert."
	rm -rf /home/ssh/*
	rm -rf /config/id_rsa.pub
	rm -rf /config/id_rsa
	cd /home/ssh
	ssh-keygen -t rsa -b 4096 -f ssh_host_rsa_key -q -N "" < /dev/null
	cp /home/ssh/ssh_host_rsa_key.pub /config/id_rsa.pub
	cp /home/ssh/ssh_host_rsa_key /config/id_rsa
	echo "Success. Stopping container. Please use key:"
	echo "Public Key:"
	echo
	echo $(cat /config/id_rsa.pub)
	echo
	elfcheck_fail=1
	exit 0
fi
echo "Checking SFTP connection..."
set -x
sshfs -p $backup_port -o BatchMode=yes,IdentityFile=/home/ssh/ssh_host_rsa_key,StrictHostKeyChecking=accept-new,_netdev,reconnect $backup_nutzername@$backup_adresse:/ /mnt/sftp/
set +x
sleep 2
echo "Checking mounted folders..."
if [ ! -d "/mnt/sftp/backup" ]
then
  echo "Error! SFTP folder backup/ not found!"
  echo "Please check and try again!"
  umount -lf /mnt/sftp/
  selfcheck_fail=1
else
  echo "Selfcheck passed."
  umount -lf /mnt/sftp/
  selfcheck_fail=0
fi
