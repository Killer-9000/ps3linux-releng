#!/bin/sh

# If we fail just exit right away
set -euo pipefail

# Some constants for us to use.
KERNEL_BUILD_PATH=$(pwd)/build
CHROOT_PATH=$(pwd)/PS3LINUX_chroot

DNF_INSTALL_OPTS="-y --use-host-config --forcearch=ppc64 --releasever=28 --disable-repo=* --enable-repo=fedora --repofrompath=ps3linux,http://www.ps3linux.net/ps3linux-repos/ps3linux/ppc64/ --no-gpgchecks --setopt=install_weak_deps=False --setopt=tsflags=nodocs --installroot=$CHROOT_PATH"

# Remove any existing identifier.
rm -f $KERNEL_BUILD_PATH/.chrootgen

# If we aren't root exit right away, we need root priv for some stuff.
if [ $(id -u) -eq 0 ]; then
    echo "This script requires root privilege to run, try again with sudo."
    exit 1
fi

# Make sure the kernel successfully compiled.
if [ ! -f "$KERNEL_BUILD_PATH/.kernelbuilt" ]; then
    echo "This script requires the kernel to be built, make sure to run that script first, and it completes without error."
    exit 1
fi

dnf $DNF_INSTALL_OPTS --exclude=fedora-release install filesystem

touch $CHROOT_PATH/etc/fstab

mount -t proc /proc $CHROOT_PATH/proc
mount -t sysfs /sys $CHROOT_PATH/sys
mount -o bind /dev $CHROOT_PATH/dev
mount -o bind /dev/pts $CHROOT_PATH/dev/pts
mount -t tmpfs tmpfs $CHROOT_PATH/run
mount -t tmpfs tmpfs $CHROOT_PATH/tmp

dnf $DNF_INSTALL_OPTS install dnf

sed -i 's/enabled=1/enabled=0/g' $CHROOT_PATH/etc/yum.repos.d/fedora-updates.repo
cp $(pwd)/resources/ps3linux.repo $CHROOT_PATH/etc/yum.repos.d/ps3linux.repo
sed -i 's/ppc64/$basearch/g' $CHROOT_PATH/etc/yum.repos.d/ps3linux.repo

echo "ps3linux" > $CHROOT_PATH/etc/hostname
echo "nameserver 8.8.8.8" > $CHROOT_PATH/etc/resolv.conf
echo "nameserver 8.8.4.4" >> $CHROOT_PATH/etc/resolv.conf

dnf $DNF_INSTALL_OPTS clean all
dnf $DNF_INSTALL_OPTS makecache
dnf $DNF_INSTALL_OPTS groupinstall core
dnf $DNF_INSTALL_OPTS install udisks2-zram nfs-utils bash-completion wget gdisk
dnf $DNF_INSTALL_OPTS clean all

rm -f $CHROOT_PATH/etc/yum.repos.d/*.rpmnew
mv -f $CHROOT_PATH/etc/nsswitch.conf $CHROOT_PATH/etc/nsswitch.conf.orig
mv -f $CHROOT_PATH/etc/nsswitch.conf.rpmnew $CHROOT_PATH/etc/nsswitch.conf

rm -rf $CHROOT_PATH/usr/share/doc
rm -rf $CHROOT_PATH/usr/share/man
rm -rf $CHROOT_PATH/lib/firmware/*
cp -rf $(pwd)/resources/6.0.19 $CHROOT_PATH/lib/modules/

cp $(pwd)/resources/10-eth0.network $CHROOT_PATH/etc/systemd/network/10-eth0.network

echo "ps3vram" > $CHROOT_PATH/etc/modules-load.d/ps3vram.conf
echo 'KERNEL=="ps3vram", ACTION=="add", RUN+="/sbin/mkswap /dev/ps3vram", RUN+="/sbin/swapon -p 200 /dev/ps3vram"' > $CHROOT_PATH/etc/udev/rules.d/10-ps3vram.rules
chmod 0200 $CHROOT_PATH/etc/shadow
sed -i '1c\root:$6$cv5wSgU5Qr51VAfB$shVUHbZViYACoKJYSou.rYODvFYemeBErPqWMaEu566QeywZcy/y7Qa0/ZAiz1y/vnTSPuphTCkqlypglOpJX/:20447:0:99999:7:::' $CHROOT_PATH/etc/shadow
chmod 0000 $CHROOT_PATH/etc/shadow
mkdir $CHROOT_PATH/mnt/target

cp $(pwd)/resources/zram-swap.sh $CHROOT_PATH/usr/sbin/zram-swap.sh
cp $(pwd)/resources/zram-swap.service $CHROOT_PATH/etc/systemd/system/zram-swap.service

cp $(pwd)/resources/ps3linux-install.sh $CHROOT_PATH/usr/sbin/ps3linux-install.sh

chroot $CHROOT_PATH /usr/bin/systemctl mask auth-rpcgss-module.service
chroot $CHROOT_PATH /usr/bin/systemctl mask rpc-gssd.service
chroot $CHROOT_PATH /usr/bin/systemctl mask systemd-tmpfiles-setup.service
chroot $CHROOT_PATH /usr/bin/systemctl mask systemd-update-utmp.service
chroot $CHROOT_PATH /usr/bin/systemctl disable auditd.service
chroot $CHROOT_PATH /usr/bin/systemctl disable fedora-import-state.service
chroot $CHROOT_PATH /usr/bin/systemctl disable fedora-readonly.service
chroot $CHROOT_PATH /usr/bin/systemctl disable mdmonitor.service
chroot $CHROOT_PATH /usr/bin/systemctl disable multipathd.service
chroot $CHROOT_PATH /usr/bin/systemctl disable sssd-secrets.socket
chroot $CHROOT_PATH /usr/bin/systemctl disable sssd.service
chroot $CHROOT_PATH /usr/bin/systemctl disable firewalld.service
chroot $CHROOT_PATH /usr/bin/systemctl disable dbus-org.fedoraproject.FirewallD1.service
chroot $CHROOT_PATH /usr/bin/systemctl disable NetworkManager.service
chroot $CHROOT_PATH /usr/bin/systemctl disable dbus-org.freedesktop.nm-dispatcher.service
chroot $CHROOT_PATH /usr/bin/systemctl disable dbus-org.freedesktop.NetworkManager.service
chroot $CHROOT_PATH /usr/bin/systemctl disable NetworkManager-wait-online.service
chroot $CHROOT_PATH /usr/bin/systemctl disable dnf-makecache.timer
chroot $CHROOT_PATH /usr/bin/systemctl enable systemd-networkd.service
chroot $CHROOT_PATH /usr/bin/systemctl enable zram-swap.service

chroot $CHROOT_PATH /usr/bin/ssh-keygen -t rsa -N '' -f /etc/ssh/ssh_host_rsa_key
chroot $CHROOT_PATH /usr/bin/ssh-keygen -t ecdsa -N '' -f /etc/ssh/ssh_host_ecdsa_key
chroot $CHROOT_PATH /usr/bin/ssh-keygen -t ed25519 -N '' -f /etc/ssh/ssh_host_ed25519_key

umount $CHROOT_PATH/tmp
umount $CHROOT_PATH/run
umount $CHROOT_PATH/dev/pts
umount $CHROOT_PATH/dev
umount $CHROOT_PATH/sys
umount $CHROOT_PATH/proc

find $CHROOT_PATH -type f \( -perm -111 -o -name '*.so*' -o -name '*.ko' \) -exec file {} \; | grep 'ELF' | cut -d: -f1 | while read f; do echo "Stripping $f"; powerpc64-linux-gnu-strip --strip-unneeded "$f" || true; done
find $CHROOT_PATH/usr/lib64 -name '*.a' -delete

echo "Done."
echo "Password for root: HACKTHEPLANET"

# Add the completion identifier.
touch $KERNEL_BUILD_PATH/.chrootgen
