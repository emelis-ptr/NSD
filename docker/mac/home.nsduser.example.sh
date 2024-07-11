include <tunables/global>
/home/nsduser/example.sh {
  include <abstractions/base>
  include <abstractions/consoles>
  include <abstractions/bash>

  owner /home/ rw,
  owner /home/** rw,
  owner /root/ rw,
  owner /root/** rw,

  /home/nsduser/example.sh ix,
  /usr/bin/bash rix,
  /usr/bin/touch mrix,
  /usr/bin/mkdir mrwix,
  /bin/touch mrwix,
  /bin/mkdir mrwix,

  deny /usr/bin/rmdir x,
  deny /usr/bin/rm x,
  deny /bin/rmdir x,
  deny /bin/rm x,

  owner /home/*/sample.txt w,
}