FROM alpine:3.20.3
RUN apk add --no-cache rsync openssh-keygen sshfs tzdata coreutils bash findutils jq
RUN cp /usr/share/zoneinfo/Europe/Berlin /etc/localtime
RUN mkdir /home/scripts && mkdir /home/ssh && mkdir /config && mkdir /config/logs && mkdir /mnt/sftp
RUN wget https://github.com/OliveTin/OliveTin/releases/latest/download/OliveTin_linux_amd64.apk && apk add --allow-untrusted OliveTin_linux_amd64.apk && rm OliveTin_linux_amd64.apk
COPY ./olivetin/config.yaml /etc/OliveTin/
COPY ./scripts/* /home/scripts/
RUN chmod +x /home/scripts/*; ln /home/scripts/backup_now.sh /usr/bin/backup-now
ENV backup_version=3.5.0
ENTRYPOINT ["/home/scripts/entrypoint.sh"]