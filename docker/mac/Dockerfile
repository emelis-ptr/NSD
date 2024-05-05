FROM weibeld/ubuntu-networking:latest
RUN apt update
RUN apt install -y telnet nano python3 unzip wget apparmor apparmor-utils rsyslog
COPY bin.ping /etc/apparmor.d/
