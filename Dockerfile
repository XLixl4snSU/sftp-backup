FROM alpine:3.16.2
RUN apk add rclone openssh-keygen sshfs
RUN mkdir /home/scripts && mkdir /home/ssh && mkdir /config && mkdir /config/logs && mkdir /mnt/sftp && mkdir /mnt/lokal
COPY setup.sh /home/scripts
RUN cd /home/scripts chmod +x setup.sh && ./setup.sh
CMD /home/scripts/startup.sh
