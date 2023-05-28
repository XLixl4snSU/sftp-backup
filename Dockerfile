FROM alpine:3.18.0
RUN apk add --no-cache rsync openssh-keygen sshfs tzdata coreutils bash findutils
RUN cp /usr/share/zoneinfo/Europe/Berlin /etc/localtime
RUN mkdir /home/scripts && mkdir /home/ssh && mkdir /config && mkdir /config/logs && mkdir /mnt/sftp
COPY ./scripts/* /home/scripts/
RUN chmod +x /home/scripts/*; ln /home/scripts/backup_now.sh /usr/bin/backup-now
ENV backup_version=3.3.2
ENTRYPOINT ["/home/scripts/entrypoint.sh"]
