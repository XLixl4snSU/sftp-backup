FROM alpine:3.16.2
RUN apk add rclone openssh-keygen sshfs
RUN mkdir /home/scripts && mkdir /home/ssh && mkdir /config && mkdir /config/logs && mkdir /mnt/sftp && mkdir /mnt/lokal
COPY ./scripts/* /home/scripts
CMD /home/scripts/startup.sh
