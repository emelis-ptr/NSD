#!/bin/bash
echo "AppArmor Example:"

# Test touch
/usr/bin/touch /home/nsduser/sample.txt && echo "File created" || echo "Permission denied"

# Test rm
/bin/rm /home/nsduser/sample.txt && echo "File deleted" || echo "Permission denied"

# Test mkdir
/bin/mkdir /home/nsduser/sample_dir && echo "Dir created" || echo "Permission denied"

# Test rmdir
/bin/rmdir /home/nsduser/sample_dir && echo "Dir deleted" || echo "Permission denied"
