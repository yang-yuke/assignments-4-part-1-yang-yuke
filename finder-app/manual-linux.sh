#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v6.6.43
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-


if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
    ## Clean the kernel build environment (optional)
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE mrproper
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE defconfig
    #make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE modules
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE -j$(nproc) Image dtbs

    ## Copy the generated image to ${OUTDIR}
    cp arch/${ARCH}/boot/Image ${OUTDIR}/
fi

echo "Adding the Image in outdir"

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
    echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
#    rm -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
mkdir -p ${OUTDIR}/rootfs/{bin,boot,dev,etc,home,lib,lib64,media,mnt,opt,proc,root,run,sbin,srv,sys,tmp,usr,var}
mkdir -p ${OUTDIR}/rootfs/usr/{bin,lib,sbin}
mkdir -p ${OUTDIR}/rootfs/var/log

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE distclean
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE defconfig #use default config
else
    cd busybox
fi

# TODO: Make and install busybox
if [ ! -f "${OUTDIR}/rootfs/bin/busybox" ]; 
then
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE # Build BusyBox
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE CONFIG_PREFIX=${OUTDIR}/rootfs/ install # Install BusyBox to ${OUTDIR}/rootfs/ (adjust as necessary)
else
    echo "busybox binary already exists in ${OUTDIR}/rootfs/bin/busybox"
fi

echo "Library dependencies"

# TODO: Add library dependencies to rootfs
INTERPRETER=$(${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "program interpreter" | awk '{print $NF}' | tr -d '[]')
LIBS=$(${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "Shared library" | awk '{print $NF}' | tr -d '[]')

## Copy the program interpreter
export SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)


## Copy the program interpreter
for lib in $INTERPRETER; do
    # find the full path of the dependent library of busybox
    libpath=$(find $SYSROOT/lib -name "$(basename "$lib")")

    if [ -n "$libpath" ]; then
        echo "Copying $lib to rootfs"
        sudo cp "$libpath" "${OUTDIR}/rootfs/lib/"
    else
        echo "Library $lib not found in sysroot/lib"
    fi
done

## Copy the shared libraries
## If using 64-bit libraries, you may need to copy them to lib64
for lib in $LIBS; do
    # find the full path of the dependent library of busybox
    libpath=$(find $SYSROOT/lib64 -name "$lib")

    if [ -n "$libpath" ]; then
        echo "Copying $lib to rootfs"
        sudo cp "$libpath" "${OUTDIR}/rootfs/lib64/"
    else
        echo "Library $lib not found in sysroot/lib64"
    fi
done

# TODO: Clean and build the writer utility
## Change to the script directory
cd "$FINDER_APP_DIR"

DEST="${OUTDIR}/rootfs/home/writer"
#${CROSS_COMPILE}gcc -o ${OUTDIR}/rootfs/home/writer writer.c
# check if file exists
if [ ! -f "$DEST" ]; then
    echo "$DEST does not exist. Compiling..."
    $CC -o "$DEST" "$SRC"
else
    echo "$DEST already exists. No need to compile."
fi

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
sudo cp -r ${FINDER_APP_DIR}/conf/ ${OUTDIR}/rootfs/home/
sudo cp ${FINDER_APP_DIR}/finder-test.sh ${OUTDIR}/rootfs/home/

cd ${OUTDIR}/rootfs

# create character device node
if [ ! -e "${OUTDIR}/rootfs/dev/null" ]; then
    sudo mknod -m 666 ${OUTDIR}/rootfs/dev/null c 1 3
fi
if [ ! -e "${OUTDIR}/rootfs/dev/console" ]; then
    sudo mknod -m 600 ${OUTDIR}/rootfs/dev/console c 5 1
fi
if [ ! -e "${OUTDIR}/rootfs/dev/tty" ]; then
    sudo mknod -m 666 ${OUTDIR}/rootfs/dev/tty c 5 0
fi
if [ ! -e "${OUTDIR}/rootfs/dev/tty0" ]; then
    sudo mknod -m 666 ${OUTDIR}/rootfs/dev/tty0 c 4 0
fi
if [ ! -e "${OUTDIR}/rootfs/dev/ttyS0" ]; then
    sudo mknod -m 666 ${OUTDIR}/rootfs/dev/ttyS0 c 4 64
fi
if [ ! -e "${OUTDIR}/rootfs/dev/ttyAMA0" ]; then
    sudo mknod -m 666 ${OUTDIR}/rootfs/dev/ttyAMA0 c 204 64
fi
if [ ! -e "${OUTDIR}/rootfs/dev/zero" ]; then
    sudo mknod -m 666 ${OUTDIR}/rootfs/dev/zero c 1 5
fi
if [ ! -e "${OUTDIR}/rootfs/dev/ptmx" ]; then
    sudo mknod -m 666 ${OUTDIR}/rootfs/dev/ptmx c 5 2
fi
if [ ! -e "${OUTDIR}/rootfs/dev/random" ]; then
    sudo mknod -m 444 ${OUTDIR}/rootfs/dev/random c 1 8
fi
if [ ! -e "${OUTDIR}/rootfs/dev/urandom" ]; then
    sudo mknod -m 444 ${OUTDIR}/rootfs/dev/urandom c 1 9
fi

# create block device node
if [ ! -e "${OUTDIR}/rootfs/dev/sda" ]; then
    sudo mknod -m 666 ${OUTDIR}/rootfs/dev/sda b 8 0
fi
if [ ! -e "${OUTDIR}/rootfs/dev/sda1" ]; then
    sudo mknod -m 666 ${OUTDIR}/rootfs/dev/sda1 b 8 1
fi
if [ ! -e "${OUTDIR}/rootfs/dev/sdb" ]; then
    sudo mknod -m 666 ${OUTDIR}/rootfs/dev/sdb b 8 16
fi
if [ ! -e "${OUTDIR}/rootfs/dev/sdb1" ]; then
    sudo mknod -m 666 ${OUTDIR}/rootfs/dev/sdb1 b 8 17
fi

#sudo mount -t proc procfs ${OUTDIR}/rootfs/proc
#sudo mount -t sysfs sysfs ${OUTDIR}/rootfs/sys

# TODO: Chown the root directory
sudo chown -R root:root ${OUTDIR}/rootfs

# Copy the autorun-qemu.sh script into the outdir/rootfs/home directory
sudo cp ${FINDER_APP_DIR}/autorun-qemu.sh ${OUTDIR}/rootfs/home/
sudo cp ${FINDER_APP_DIR}/finder.sh ${OUTDIR}/rootfs/home/

# TODO: Create initramfs.cpio.gz
cd ${OUTDIR}/rootfs
find . -print0 | cpio --null -ov --format=newc --owner root:root | gzip -9 > ../initramfs.cpio.gz

# Clean up: remove the initramfs directory if not needed
#rm -rf ${INITRAMFS_DIR}