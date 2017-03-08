#!/bin/sh

set -eux

# there are no temporary downloads, the space is limited all files should be streamed directly in place

ARCH=$(uname -m)

DATA_SERVER="http://192.168.0.107:8000"
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
wget -q -O - "${DATA_SERVER}/SPL" | dd of=${SDCARD} bs=1K seek=1
wget -q -O - "${DATA_SERVER}/u-boot.img" | dd of=${SDCARD} bs=1K seek=69

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
wget -q -O - "${DATA_SERVER}/cubox-i.xz" | unxz | btrfs receive ${VOLS}/
# UGLY HACK but the name is not know
mv ${VOLS}/* ${VOLS}/root
btrfs property set -ts ${VOLS}/root ro false
btrfs sub set-default 257 ${VOLS}/root
umount ${NEWROOT}/
mount ${SDCARD}${P3} ${NEWROOT}/


echo "BOOT SETUP"
BOOT=${NEWROOT}/boot
mount ${SDCARD}${P1} ${BOOT}
wget -q -O - "${DATA_SERVER}/boot.scr" > ${BOOT}/boot.scr
wget -q -O - "${DATA_SERVER}/zImage" > ${BOOT}/zImage
wget -q -O - "${DATA_SERVER}/imx6q-cubox-i.dtb" > ${BOOT}/imx6q-cubox-i.dtb
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

echo "* NETWORK"
[[ "$ARCH" == "armv7l" ]] &&  chroot ${NEWROOT} /bin/bash -c "cd /etc/init.d && ln -s net.lo net.eth0 && rc-update add net.eth0 boot"



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
fi

umount ${NEWROOT}
echo "ALL DONE - KTHXBYE"