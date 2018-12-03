#!/bin/sh

set -eux

# there are no temporary downloads, the space is limited all files should be streamed directly in place

TAG="v0.17"

echo "SETUP userland"
ARCH=$(uname -m)
WGET="/usr/bin/wget"
TAR="/bin/tar"
/bin/busybox --install -s

DATA_SERVER="https://github.com/stefan-langenmaier/cubox-i-autodeploy-image/releases/download/${TAG}/"
if [ "$ARCH" == "armv7l" ]; then
    SDCARD="/dev/mmcblk1"
    P1="p1"
    P2="p2"
    P3="p3"
fi

if [ "$ARCH" == "x86_64" ]; then
    SDCARD="/dev/sdb"
    P1="1"
    P2="2"
    P3="3"
fi

echo "COPY PRIVATE CONFIG"
mkdir -p /sdcard
mount /dev/mmcblk1p1 /sdcard
cp /sdcard/config . -R
umount /sdcard

echo "PARTITION"
parted -s ${SDCARD} mklabel msdos
partprobe
parted -s ${SDCARD} mkpart primary ext2          1MiB  200MiB # boot
parted -s ${SDCARD} mkpart primary linux-swap  200MiB 1200MiB # swap
parted -s ${SDCARD} mkpart primary btrfs      1200MiB "100%"  # root volume
partprobe

echo "BOOTLOADER SETUP"
${WGET} -q -O - "${DATA_SERVER}/SPL" | dd of=${SDCARD} bs=1K seek=1
${WGET} -q -O - "${DATA_SERVER}/u-boot.img" | dd of=${SDCARD} bs=1K seek=69

echo "FORMAT"
mkfs.ext2 -L boot -F ${SDCARD}${P1}
mkswap -L swap ${SDCARD}${P2}
mkfs.btrfs -L root --force ${SDCARD}${P3}


echo "ROOT SETUP"
NEWROOT=newroot
[[ -d ${NEWROOT} ]] && rm ${NEWROOT} -r
mkdir ${NEWROOT}
mount ${SDCARD}${P3} ${NEWROOT}/
VOLS=${NEWROOT}/vols
mkdir ${VOLS}
btrfs sub create ${VOLS}/root
btrfs sub set-default 257 ${VOLS}/root
cd ${VOLS}/root
${WGET} -q -O - "${DATA_SERVER}/cubox-i.tar.xz" | ${TAR} -xpJv --checkpoint --xattrs-include='*.*' --numeric-owner
rm .dockerenv || true # make sure that there is no trace from the docker container left and open rc starts in the correct mode
cd -
umount ${NEWROOT}/
mount ${SDCARD}${P3} ${NEWROOT}/


echo "BOOT SETUP"
BOOT=${NEWROOT}/boot
mount ${SDCARD}${P1} ${BOOT}
mkdir ${BOOT}/extlinux
mkdir ${BOOT}/dtbs
${WGET} -q -O - "${DATA_SERVER}/extlinux.conf" > ${BOOT}/extlinux/extlinux.conf
${WGET} -q -O - "${DATA_SERVER}/zImage" > ${BOOT}/zImage
${WGET} -q -O - "${DATA_SERVER}/imx6q-cubox-i.dtb" > ${BOOT}/dtbs/imx6q-cubox-i.dtb
umount ${BOOT}

echo "DEFAULT CONFIGURATION"
echo "* COPY CONFIG"
GLOBAL_CONF="config/global"
cp ${GLOBAL_CONF}/* ${NEWROOT}/ -R

echo "* RANDOMIZE ROOT PWD"
[[ "$ARCH" == "armv7l" ]] && chroot ${NEWROOT} /bin/bash -c "PWD=\$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1 ) ; echo \"root:\$PWD\" | chpasswd"

echo "* ENABLE SSH"
[[ "$ARCH" == "armv7l" ]] && chroot ${NEWROOT} /bin/bash -c "rc-update add sshd default"

echo "* ENABLE NTP CLIENT"
[[ "$ARCH" == "armv7l" ]] && chroot ${NEWROOT} /bin/bash -c "rc-update add ntp-client default"

echo "* ENABLE DynDns CLIENT"
[[ "$ARCH" == "armv7l" ]] && chroot ${NEWROOT} /bin/bash -c "rc-update add ddclient default"

echo "* NETWORK"
[[ "$ARCH" == "armv7l" ]] &&  chroot ${NEWROOT} /bin/bash -c "cd /etc/init.d/ ; ln -s net.lo net.eth0 ; rc-update add net.eth0 boot"


MACHINE="NO_MACHINE_CONFIG"
if [ -d "/sys/class/net/wlp1s0" ]; then
    MACHINE=$(cat /sys/class/net/wlp1s0/address)
fi

if [ -d "/sys/class/net/eth0" ]; then
    MACHINE=$(cat /sys/class/net/eth0/address)
fi

if [ -d "config/${MACHINE}_"* ]; then
    echo "MACHINE CONFIGURATION"
    MACHINE_CONF="config/${MACHINE}_"*

    cp ${MACHINE_CONF}/* ${NEWROOT} -R

    echo "* PERMISSIONS"
    [[ "$ARCH" == "armv7l" ]] &&  chroot ${NEWROOT} /bin/bash -c "chmod +x /etc/local.d/*.start"
    [[ "$ARCH" == "armv7l" ]] &&  chroot ${NEWROOT} /bin/bash -c "chown ddclient:ddclient /etc/ddclient/ddclient.conf"


fi

umount ${NEWROOT}
echo "ALL DONE - KTHXBYE"
