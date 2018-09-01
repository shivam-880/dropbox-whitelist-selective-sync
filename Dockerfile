FROM janeczku/dropbox:latest
MAINTAINER Shivam Kapoor <mail@shivamkapoor.com>
COPY dropbox-whitelist-selective-sync.sh /root/
COPY startup.sh /root/
ENTRYPOINT ["/root/startup.sh"]
