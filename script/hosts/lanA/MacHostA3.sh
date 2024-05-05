#!/bin/bash

# To mount the system
mount -tsecurityfs securityfs /sys/kernel/security

# To view the current status
apparmor_status

# To place a profile into enforce mode
aa-enforce /etc/apparmor.d/bin.ping

# To reload a profile
apparmor_parser -r /etc/apparmor.d/bin.ping