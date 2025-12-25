#!/bin/sh

echo "Generating squashfs root filesystem image from PS3LINUX_chroot directory..."
mksquashfs /root/PS3LINUX_chroot /root/ps3_install.img -comp xz -b 1M -Xdict-size 100% -noappend

mv -fv /root/ps3_install.img /root/PS3LINUX_Live_ISO/LiveOS/ps3_install.img

echo "Generating PS3LINUX live install ISO..."
mkisofs -r -J -V PS3LINUX -o /root/PS3LINUX_Live_ISO.iso PS3LINUX_Live_ISO/
