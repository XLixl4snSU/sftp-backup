FROM alpine:3.16.2
RUN apk add --no-cache rclone openssh-keygen sshfs tzdata 
RUN cp /usr/share/zoneinfo/Europe/Berlin /etc/localtime
RUN apk del --no-cache tzdata
RUN mkdir /home/scripts && mkdir /home/ssh && mkdir /config && mkdir /config/logs && mkdir /mnt/sftp && mkdir /mnt/lokal
COPY ./scripts/* /home/scripts/
CMD /home/scripts/startup.sh
