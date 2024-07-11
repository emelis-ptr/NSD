FROM weibeld/ubuntu-networking:latest
RUN apt update
RUN apt install -y telnet nano python3 unzip wget apparmor apparmor-utils rsyslog
COPY home.nsduser.example.sh /etc/apparmor.d/
RUN mkdir /home/nsduser
COPY example.sh /home/nsduser/
