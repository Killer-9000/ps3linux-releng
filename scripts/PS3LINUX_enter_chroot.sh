#!/bin/bash

mount -vt proc /proc /root/PS3LINUX_chroot/proc
mount -vt sysfs /sys /root/PS3LINUX_chroot/sys
mount -vo bind /dev /root/PS3LINUX_chroot/dev
mount -vo bind /dev/pts /root/PS3LINUX_chroot/dev/pts
mount -vt tmpfs tmpfs /root/PS3LINUX_chroot/run
mount -vt tmpfs tmpfs /root/PS3LINUX_chroot/tmp
chroot /root/PS3LINUX_chroot /usr/bin/env -i ARCH=powerpc HOME=/root TERM="$TERM" PS1='\u:\w\$ ' PATH=/root/.local/bin:/usr/lib64/ccache:/usr/bin:/usr/sbin:/bin:/sbin /bin/bash --login
