# PS3LINUX Release Engineering

For now this is just a place for me to store what "scripts" and configs I use for building live Linux media for the Playstation 3 (petitboot) game console. PS3LINUX is a fork of Fedora 28 (ppc64) with optimizations for the PS3's Cell CPU and any updates I package and serve from my personal PS3LINUX dnf repo (at http://www.ps3linux.net/ps3linux-repos/ps3linux/).

If you are interested in developing for PS3LINUX but do not have a dedicated Linux PS3 (like my gibson), then this is the place you want to be. Everything here is designed to run in modern x86_64 Fedora (releases 42 and above). For example my PS3LINUX_chroot_gen.sh "script" creates an ideal environment for developing & compiling PS3LINUX compatible rpm packages & spec files etc...

TODO: Now that I have a working live ISO I need to start thinking about replacing Fedora's branding & other assets with my own. Also I may need to write a ps3linux-install script if I can't get Anaconda to run in the console's tiny 256 MiB of memory.

THE MODEL CITIZEN
