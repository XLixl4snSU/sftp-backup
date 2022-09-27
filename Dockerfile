FROM alpine:3.16.2
RUN apk add --no-cache rsync openssh-keygen sshfs tzdata coreutils
RUN cp /usr/share/zoneinfo/Europe/Berlin /etc/localtime
RUN mkdir /home/scripts && mkdir /home/ssh && mkdir /config && mkdir /config/logs && mkdir /mnt/sftp && mkdir /mnt/lokal
COPY ./scripts/* /home/scripts/
RUN chmod +x /home/scripts/*; ln /home/scripts/backup_now.sh /backup-now
CMD /home/scripts/startup.sh