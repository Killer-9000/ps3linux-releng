#!/bin/sh

# If we fail just exit right away
set -euo pipefail

call_dnf() {
    set +e
    dnf $DNF_INSTALL_OPTS $@
    set -e
}

# Some constants for us to use.
KERNEL_BUILD_PATH=$(pwd)/build
CHROOT_PATH=$(pwd)/PS3LINUX_chroot

DNF_INSTALL_OPTS="-y --use-host-config --forcearch=ppc64 --releasever=28 --disable-repo=* --enable-repo=fedora --repofrompath=ps3linux,http://www.ps3linux.net/ps3linux-repos/ps3linux/ppc64/ --no-gpgchecks --setopt=install_weak_deps=False --setopt=tsflags=nodocs --installroot=$CHROOT_PATH"

# Remove any existing identifier.
rm -f $KERNEL_BUILD_PATH/.chrootgen

# If we aren't root exit right away, we need root priv for some stuff.
if [ ! $(id -u) -eq 0 ]; then
    echo "This script requires root privilege to run, try again with sudo."
    exit 1
fi

# Make sure the kernel successfully compiled.
if [ ! -f "$KERNEL_BUILD_PATH/.kernelbuilt" ]; then
    echo "This script requires the kernel to be built, make sure to run that script first, and it completes without error."
    exit 1
fi

# Make sure we have a clean directory to work with.
rm -rf $CHROOT_PATH

# Install the base filesystem.
call_dnf --exclude=fedora-release install filesystem

# Link the important folders, not mounting them right now since it requires priv.
ln -s /dev $CHROOT_PATH/dev
ln -s /proc $CHROOT_PATH/proc
ln -s /sys $CHROOT_PATH/sys

# Create the fstab file for mounting
touch $CHROOT_PATH/etc/fstab

# Install the dnf package manager.
call_dnf install dnf

# Disable the fedora-updates repo?
sed -i 's/enabled=1/enabled=0/g' $CHROOT_PATH/etc/yum.repos.d/fedora-updates.repo
# Add the ps3linux repo.
cp $(pwd)/resources/ps3linux.repo $CHROOT_PATH/etc/yum.repos.d/ps3linux.repo
# I don't know why this is happening?
# sed -i 's/ppc64/$basearch/g' $CHROOT_PATH/etc/yum.repos.d/ps3linux.repo

# Set the hostname.
echo "ps3linux" > $CHROOT_PATH/etc/hostname

# Add dns servers.
echo "nameserver 8.8.8.8" > $CHROOT_PATH/etc/resolv.conf
echo "nameserver 8.8.4.4" >> $CHROOT_PATH/etc/resolv.conf

# Clean, cache, install core and utilites.
call_dnf clean all
call_dnf makecache
call_dnf group install core
call_dnf install udisks2-zram nfs-utils bash-completion wget gdisk
call_dnf clean all

# Get rid of tmp files.
rm -f $CHROOT_PATH/etc/yum.repos.d/*.rpmnew
if [ -f $CHROOT_PATH/etc/nsswitch.conf.rpmnew ]; then
    mv -f $CHROOT_PATH/etc/nsswitch.conf $CHROOT_PATH/etc/nsswitch.conf.orig
    mv -f $CHROOT_PATH/etc/nsswitch.conf.rpmnew $CHROOT_PATH/etc/nsswitch.conf
fi

# Once again, I don't know why you're doign this, I suppose you use gpt instead of the manuals.
# rm -rf $CHROOT_PATH/usr/share/doc
# rm -rf $CHROOT_PATH/usr/share/man
# rm -rf $CHROOT_PATH/lib/firmware/*

# Copy over our kernel modules.
cp -rf $KERNEL_BUILD_PATH/lib/modules $CHROOT_PATH/lib/modules

# Copy over our ethernet network
cp $(pwd)/resources/10-eth0.network $CHROOT_PATH/etc/systemd/network/10-eth0.network

# Setup the vram swap rules and service.
echo "ps3vram" > $CHROOT_PATH/etc/modules-load.d/ps3vram.conf
echo 'KERNEL=="ps3vram", ACTION=="add", RUN+="/sbin/mkswap /dev/ps3vram", RUN+="/sbin/swapon -p 200 /dev/ps3vram"' > $CHROOT_PATH/etc/udev/rules.d/10-ps3vram.rules
cp $(pwd)/resources/zram-swap.sh $CHROOT_PATH/usr/sbin/zram-swap.sh
cp $(pwd)/resources/zram-swap.service $CHROOT_PATH/etc/systemd/system/zram-swap.service

# I don't what what the shadow file is, but it seems needed.
chmod 0200 $CHROOT_PATH/etc/shadow
sed -i '1c\root:$6$cv5wSgU5Qr51VAfB$shVUHbZViYACoKJYSou.rYODvFYemeBErPqWMaEu566QeywZcy/y7Qa0/ZAiz1y/vnTSPuphTCkqlypglOpJX/:20447:0:99999:7:::' $CHROOT_PATH/etc/shadow
chmod 0000 $CHROOT_PATH/etc/shadow

# Copy over the install script.
cp $(pwd)/resources/ps3linux-install.sh $CHROOT_PATH/usr/sbin/ps3linux-install.sh

if [ ! /bin/true ]; then

    # Mask services. Doing so manually so no reliance on systemd.
    # ln -s $CHROOT_PATH/usr/lib/systemd/system/auth-rpcgss-module.service /dev/null
    # ln -s $CHROOT_PATH/usr/lib/systemd/system/rpc-gssd.service /dev/null
    # ln -s $CHROOT_PATH/usr/lib/systemd/system/systemd-tmpfiles-setup.service /dev/null
    # ln -s $CHROOT_PATH/usr/lib/systemd/system/systemd-update-utmp.service /dev/null

    # chroot $CHROOT_PATH /usr/bin/systemctl disable auditd.service
    # chroot $CHROOT_PATH /usr/bin/systemctl disable fedora-import-state.service
    # chroot $CHROOT_PATH /usr/bin/systemctl disable fedora-readonly.service
    # chroot $CHROOT_PATH /usr/bin/systemctl disable mdmonitor.service
    # chroot $CHROOT_PATH /usr/bin/systemctl disable multipathd.service
    # chroot $CHROOT_PATH /usr/bin/systemctl disable sssd-secrets.socket
    # chroot $CHROOT_PATH /usr/bin/systemctl disable sssd.service
    # chroot $CHROOT_PATH /usr/bin/systemctl disable firewalld.service
    # chroot $CHROOT_PATH /usr/bin/systemctl disable dbus-org.fedoraproject.FirewallD1.service
    # chroot $CHROOT_PATH /usr/bin/systemctl disable NetworkManager.service
    # chroot $CHROOT_PATH /usr/bin/systemctl disable dbus-org.freedesktop.nm-dispatcher.service
    # chroot $CHROOT_PATH /usr/bin/systemctl disable dbus-org.freedesktop.NetworkManager.service
    # chroot $CHROOT_PATH /usr/bin/systemctl disable NetworkManager-wait-online.service
    # chroot $CHROOT_PATH /usr/bin/systemctl disable dnf-makecache.timer

    # chroot $CHROOT_PATH /usr/bin/systemctl enable systemd-networkd.service
    # chroot $CHROOT_PATH /usr/bin/systemctl enable zram-swap.service

    # I don't think this is needed?
    # chroot $CHROOT_PATH /usr/bin/ssh-keygen -t rsa -N '' -f /etc/ssh/ssh_host_rsa_key
    # chroot $CHROOT_PATH /usr/bin/ssh-keygen -t ecdsa -N '' -f /etc/ssh/ssh_host_ecdsa_key
    # chroot $CHROOT_PATH /usr/bin/ssh-keygen -t ed25519 -N '' -f /etc/ssh/ssh_host_ed25519_key

    find $CHROOT_PATH -type f \( -perm -111 -o -name '*.so*' -o -name '*.ko' \) -exec file {} \; | grep 'ELF' | cut -d: -f1 | while read f; do echo "Stripping $f"; powerpc64-linux-gnu-strip --strip-unneeded "$f" || true; done
    find $CHROOT_PATH/usr/lib64 -name '*.a' -delete

    echo "Done."
    echo "Password for root: HACKTHEPLANET"

    # Add the completion identifier.
    touch $KERNEL_BUILD_PATH/.chrootgen

fi