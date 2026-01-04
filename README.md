# PS3LINUX Release Engineering

For now this is just a place for me to store what "scripts" and configs I use for building live Linux media from the Playstation 3 (petitboot) bootloader. PS3LINUX is a fork of Fedora 28 (ppc64) with optimizations for the PS3 and any updates I package and serve from my personal rpm repo hosted here: [http://www.ps3linux.net/ps3linux-repos/ps3linux](http://www.ps3linux.net/ps3linux-repos/ps3linux/).

If you are interested in developing for PS3LINUX but do not have a dedicated Linux PS3 (like my "gibson"), then this is the place you want to be. Everything here is designed to run in modern x86_64 Fedora (releases 42 and above). For example my PS3LINUX_chroot_gen.sh "script" creates an ideal environment for developing & compiling PS3LINUX compatible rpms and customizing their spec files for the PS3 platform.

### Dependencies

1. a Fedora operating system - my scripts are heavily dependent on the dnf package manager
2. qemu - for running programs executed within a ppc64 chroot `sudo dnf install qemu`
3. enable systemd's proc-sys-fs-binfmt_misc.mount unit: `sudo systemctl enable proc-sys-fs-binfmt_misc.mount`
4. optional - add your user to the kvm group: `sudo usermod -aG kvm <USERNAME>`

### How to use

NOTE - All the scripts in the toplevel directory are meant to be run as root and will fail/exit if run without proper privileges.

1. clone this repo: `git clone https://github.com/ModelCitizenPS3/ps3linux-releng.git`
2. enter repo directory: `cd ps3linux-releng`
3. run first script: `sudo ./PS3LINUX_chroot_gen.sh`
4. run second script: 'sudo ./PS3LINUX_live_iso_gen.sh
5. you should now have the file `PS3LINUX_LIVE_ISO.iso`
6. burn the image to a USB or CD/DVD: `dd if=PS3LINUX_LIVE_ISO.iso of=<USB DEVICE>`. Example USB device: `/dev/sda`.
7. BE CAREFUL WITH THE DD COMMAND. Double check that you set the right output device...
8. insert USB in your PS3 and boot your Live Linux session
9. run the PS3LINUX OS installer script: `ps3linux-install.sh`

I realize my scripts are pretty basic and my bash is atrocious. I do fully intend to clean them up a bit, add comments, and add some logic to make them more dynamic & capable.

TODO: finish writing my `ps3linux-install.sh` script

### How to use v2

1. Install the required packages to run the scripts.
 - Fedora; /usr/bin/dnf -y install bc binutils binutils-powerpc64-linux-gnu diffutils g++ gcc gcc-powerpc64-linux-gnu kmod make patch tar wget
 - Arch; sudo pacman -S bc binutils diffutils gcc kmod make patch tar wget && yay -S powerpc64-linux-gnu-gcc powerpc64-linux-gnu-binutils
 - Ubuntu; sudo apt-get install bc binutils binutils-powerpc64-linux-gnu diffutils g++ gcc gcc-powerpc64-linux-gnu kmod make patch tar wget

2. Run the `PS3LINUX_create_kernel.1.sh` script to setup the kernel components.
3. Run the `PS3LINUX_create_chroot.2.sh` script to setup the chroot enviroment.

## THE MODEL CITIZEN
