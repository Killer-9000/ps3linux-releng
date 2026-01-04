#!/bin/sh

### This file uses $KERNEL_BUILD_PATH/.kernelbuilt as an identifier that the kernel has been built successfully.

# If we fail just exit right away.
set -euo pipefail

# Some constants for us to use.
KERNEL_BUILD_PATH=$(pwd)/build

THREAD_COUNT=$(nproc)
KERNEL_VERSION="6.0.19"

# Remove any existing identifier.
rm -f $KERNEL_BUILD_PATH/.kernelbuilt

# Make sure build dir exists, and linux dir isn't there.
mkdir -p $KERNEL_BUILD_PATH
rm -rf $KERNEL_BUILD_PATH/linux-$KERNEL_VERSION

# Download and extract kernel source.
/usr/bin/wget https://www.kernel.org/pub/linux/kernel/v6.x/linux-$KERNEL_VERSION.tar.xz -O $KERNEL_BUILD_PATH/linux-$KERNEL_VERSION.tar.xz
/usr/bin/tar xf $KERNEL_BUILD_PATH/linux-$KERNEL_VERSION.tar.xz -C $KERNEL_BUILD_PATH

# Apply patches for the kernel.
for patch_file in $(ls $(pwd)/resources/patches-$KERNEL_VERSION/*.patch | sort); do
    patch -d $KERNEL_BUILD_PATH/linux-$KERNEL_VERSION -p1 -i $patch_file
done

# Set the module install dir.
export INSTALL_MOD_PATH=$KERNEL_BUILD_PATH

# Copy over the config predefined with optimal settings.
cp $(pwd)/resources/config-$KERNEL_VERSION-live $KERNEL_BUILD_PATH/linux-$KERNEL_VERSION/.config

# Make sure the old config is up to date with settings.
/usr/bin/make ARCH=powerpc CROSS_COMPILE=powerpc64-linux-gnu- -C $KERNEL_BUILD_PATH/linux-6.0.19 -j$THREAD_COUNT olddefconfig

# Build the kernel image.
/usr/bin/make ARCH=powerpc CROSS_COMPILE=powerpc64-linux-gnu- -C $KERNEL_BUILD_PATH/linux-6.0.19 -j$THREAD_COUNT zImage

# Build and install the kernel modules to $INSTALL_MOD_PATH.
/usr/bin/make ARCH=powerpc CROSS_COMPILE=powerpc64-linux-gnu- -C $KERNEL_BUILD_PATH/linux-6.0.19 -j$THREAD_COUNT modules
/usr/bin/make ARCH=powerpc CROSS_COMPILE=powerpc64-linux-gnu- -C $KERNEL_BUILD_PATH/linux-6.0.19 -j$THREAD_COUNT modules_install

# Make sure the modules dir is there, and empty.
rm -rf $KERNEL_BUILD_PATH/modules
mkdir $KERNEL_BUILD_PATH/modules

# Copy over the kernel and modules.
cp $KERNEL_BUILD_PATH/linux-$KERNEL_VERSION/arch/powerpc/boot/zImage $KERNEL_BUILD_PATH/vmlinuz
cp -r $KERNEL_BUILD_PATH/lib/modules/$KERNEL_VERSION $KERNEL_BUILD_PATH/modules

# Add the completion identifier.
touch $KERNEL_BUILD_PATH/.kernelbuilt
