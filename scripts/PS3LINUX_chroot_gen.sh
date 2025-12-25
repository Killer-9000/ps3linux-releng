#!/bin/sh

EXCLUDES="diffutils,policycoreutils,libselinux-utils,firewalld,python3-slip-dbus,ipset,libnetfilter_conntrack,python3-firewall,ebtables,ipset-libs,libnfnetlink,python3-slip,firewalld-filesystem,iptables,python3-decorator,kernel-bootwrapper,perl-Data-Dumper,perl-File-Path,perl-Scalar-List-Utils,perl-Unicode-Normalize,perl-libs,perl-threads,powerpc-utils-core,binutils,perl-Carp,libservicelog,perl-Errno,perl-IO,perl-Socket,perl-constant,perl-macros,perl-threads-shared,ppc64-utils,librtas,sg3_utils-libs,lsvpd,perl-Exporter,perl-PathTools,perl-Text-Tabs+Wrap,perl-interpreter,perl-parent,powerpc-utils,bc,libvpd,man-db,groff-base,libpipeline,plymouth,plymouth-scripts,plymouth-core-libs,selinux-policy,selinux-policy-targeted,sssd-client,libini_config,libtevent,sssd-common,c-ares,http-parser,libbasicobjects,libcollection,libdhash,libldb,libpath_utils,libref_array,libsss_certmap,libsss_idmap,libsss_nss_idmap,libtalloc,libtdb,grub2-tools-minimal,grub2-tools,grubby,file,gettext,gettext-libs,grub2-common,libcroco,libgomp,os-prober,which,dnf-yum"

mkdir -v /root/PS3LINUX_chroot

dnf -y --use-host-config --forcearch=ppc64 --releasever=28 --disable-repo=* --enable-repo=fedora --repofrompath=ps3linux,http://www.ps3linux.net/ps3linux-repos/ps3linux/ppc64/ --no-gpgchecks --setopt=install_weak_deps=False --setopt=tsflags=nodocs --exclude=${EXCLUDES} --installroot=/root/PS3LINUX_chroot install filesystem

rm -fv /root/PS3LINUX_chroot/dev/null
mknod -m 600 /root/PS3LINUX_chroot/dev/console c 5 1
mknod -m 666 /root/PS3LINUX_chroot/dev/null c 1 3

touch /root/PS3LINUX_chroot/etc/fstab

mount -vt proc /proc /root/PS3LINUX_chroot/proc
mount -vt sysfs /sys /root/PS3LINUX_chroot/sys
mount -vo bind /dev /root/PS3LINUX_chroot/dev
mount -vo bind /dev/pts /root/PS3LINUX_chroot/dev/pts
mount -vt tmpfs tmpfs /root/PS3LINUX_chroot/run
mount -vt tmpfs tmpfs /root/PS3LINUX_chroot/tmp

dnf -y --use-host-config --forcearch=ppc64 --releasever=28 --disable-repo=* --enable-repo=fedora --repofrompath=ps3linux,http://www.ps3linux.net/ps3linux-repos/ps3linux/ppc64/ --no-gpgchecks --setopt=install_weak_deps=False --setopt=tsflags=nodocs --exclude=${EXCLUDES} --installroot=/root/PS3LINUX_chroot install dnf vi

cp -fv /root/ps3linux.repo /root/PS3LINUX_chroot/etc/yum.repos.d/ps3linux.repo
echo "ps3linux" > /root/PS3LINUX_chroot/etc/hostname
echo "nameserver 8.8.8.8" > /root/PS3LINUX_chroot/etc/resolv.conf
sed -i 's/enabled=1/enabled=0/g' /root/PS3LINUX_chroot/etc/yum.repos.d/fedora-updates.repo

chroot /root/PS3LINUX_chroot /usr/bin/dnf --releasever=28 clean all
chroot /root/PS3LINUX_chroot /usr/bin/dnf --releasever=28 makecache
chroot /root/PS3LINUX_chroot /usr/bin/dnf -y --releasever=28 --setopt=install_weak_deps=False --setopt=tsflags=nodocs --exclude=${EXCLUDES} groupinstall core
chroot /root/PS3LINUX_chroot /usr/bin/dnf -y --setopt=install_weak_deps=False --setopt=tsflags=nodocs --exclude=${EXCLUDES} install anaconda-tui
chroot /root/PS3LINUX_chroot /usr/bin/dnf -y --setopt protected_packages= remove sudo
chroot /root/PS3LINUX_chroot /usr/bin/dnf clean all

rm -fv /root/PS3LINUX_chroot/etc/yum.repos.d/*.rpmnew
mv -fv /root/PS3LINUX_chroot/etc/nsswitch.conf /root/PS3LINUX_chroot/etc/nsswitch.conf.orig
mv -fv /root/PS3LINUX_chroot/etc/nsswitch.conf.rpmnew /root/PS3LINUX_chroot/etc/nsswitch.conf
rm -rvf /root/PS3LINUX_chroot/usr/share/doc
rm -rvf /root/PS3LINUX_chroot/usr/share/man
rm -rvf /root/PS3LINUX_chroot/lib/firmware/*
cp -rvf /root/6.0.19 /root/PS3LINUX_chroot/lib/modules/
cp -fv /root/10-eth0.network /root/PS3LINUX_chroot/etc/systemd/network/10-eth0.network
cp -fv /root/zram.conf /root/PS3LINUX_chroot/etc/systemd/zram.conf
echo "ps3vram" > /root/PS3LINUX_chroot/etc/modules-load.d/ps3vram.conf
echo 'KERNEL=="ps3vram", ACTION=="add", RUN+="/sbin/mkswap /dev/ps3vram", RUN+="/sbin/swapon -p 200 /dev/ps3vram"' > /root/PS3LINUX_chroot/etc/udev/rules.d/10-ps3vram.rules
echo "[Install]" >> /root/PS3LINUX_chroot/lib/systemd/system/zram.service
echo "WantedBy=multi-user.target" >> /root/PS3LINUX_chroot/lib/systemd/system/zram.service
chmod 0200 /root/PS3LINUX_chroot/etc/shadow
sed -i '1c\root:$6$cv5wSgU5Qr51VAfB$shVUHbZViYACoKJYSou.rYODvFYemeBErPqWMaEu566QeywZcy/y7Qa0/ZAiz1y/vnTSPuphTCkqlypglOpJX/:20447:0:99999:7:::' /root/PS3LINUX_chroot/etc/shadow
chmod 0000 /root/PS3LINUX_chroot/etc/shadow

chroot /root/PS3LINUX_chroot /usr/bin/systemctl mask systemd-tmpfiles-setup.service
chroot /root/PS3LINUX_chroot /usr/bin/systemctl mask systemd-update-utmp.service
chroot /root/PS3LINUX_chroot /usr/bin/systemctl disable auditd.service
chroot /root/PS3LINUX_chroot /usr/bin/systemctl disable dmraid-activation.service
chroot /root/PS3LINUX_chroot /usr/bin/systemctl disable fedora-import-state.service
chroot /root/PS3LINUX_chroot /usr/bin/systemctl disable fedora-readonly.service
chroot /root/PS3LINUX_chroot /usr/bin/systemctl disable lvm2-monitor.service
chroot /root/PS3LINUX_chroot /usr/bin/systemctl disable mdmonitor.service
chroot /root/PS3LINUX_chroot /usr/bin/systemctl disable multipathd.service
chroot /root/PS3LINUX_chroot /usr/bin/systemctl disable NetworkManager.service
chroot /root/PS3LINUX_chroot /usr/bin/systemctl disable dbus-org.freedesktop.nm-dispatcher.service
chroot /root/PS3LINUX_chroot /usr/bin/systemctl disable dbus-org.freedesktop.NetworkManager.service
chroot /root/PS3LINUX_chroot /usr/bin/systemctl disable NetworkManager-wait-online.service
chroot /root/PS3LINUX_chroot /usr/bin/systemctl disable NetworkManager-dispatcher.service
chroot /root/PS3LINUX_chroot /usr/bin/systemctl disable chronyd.service
chroot /root/PS3LINUX_chroot /usr/bin/systemctl disable dm-event.socket
chroot /root/PS3LINUX_chroot /usr/bin/systemctl disable lvm2-lvmetad.socket
chroot /root/PS3LINUX_chroot /usr/bin/systemctl disable lvm2-lvmpolld.socket
chroot /root/PS3LINUX_chroot /usr/bin/systemctl disable dnf-makecache.timer
chroot /root/PS3LINUX_chroot /usr/bin/systemctl enable systemd-networkd.service

rm -fv /root/PS3LINUX_chroot/etc/ssh/ssh_host_*
chroot /root/PS3LINUX_chroot /usr/bin/ssh-keygen -t rsa -N '' -f /etc/ssh/ssh_host_rsa_key
chroot /root/PS3LINUX_chroot /usr/bin/ssh-keygen -t ecdsa -N '' -f /etc/ssh/ssh_host_ecdsa_key
chroot /root/PS3LINUX_chroot /usr/bin/ssh-keygen -t ed25519 -N '' -f /etc/ssh/ssh_host_ed25519_key

umount /root/PS3LINUX_chroot/tmp
umount /root/PS3LINUX_chroot/run
umount /root/PS3LINUX_chroot/dev/pts
umount /root/PS3LINUX_chroot/dev
umount /root/PS3LINUX_chroot/sys
umount /root/PS3LINUX_chroot/proc

find /root/PS3LINUX_chroot -type f \( -perm -111 -o -name '*.so*' -o -name '*.ko' \) -exec file {} \; | grep 'ELF' | cut -d: -f1 | while read f; do echo "Stripping $f"; /usr/sbin/powerpc64-linux-gnu-strip --strip-unneeded "$f" || true; done
find /root/PS3LINUX_chroot/usr/lib64 -name '*.a' -delete

echo "Done."
echo "Password for root: HACKTHEPLANET"

