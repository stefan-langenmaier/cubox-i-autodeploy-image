#!/bin/bash

set -eux

CONFIG_FOLDER="config"

OUTPUT_FOLDER="output"
[ -d ${OUTPUT_FOLDER} ] && rm -r ${OUTPUT_FOLDER}
mkdir ${OUTPUT_FOLDER}

bash create-autodeploy-initramfs.sh

echo "create empty image"
dd if=/dev/zero of=${OUTPUT_FOLDER}/autodeploy.img bs=1M count=16

echo "partition image"
parted -s ${OUTPUT_FOLDER}/autodeploy.img mklabel msdos
parted -s ${OUTPUT_FOLDER}/autodeploy.img mkpart primary 1M "100%"
sleep 1
partprobe

echo "install boot loader"
losetup /dev/loop0 ${OUTPUT_FOLDER}/autodeploy.img
# mainline u-boot
dd if=u-boot-bin/SPL-201701 of=/dev/loop0 bs=1K seek=1
dd if=u-boot-bin/u-boot-201701.img of=/dev/loop0 bs=1K seek=69
losetup -d /dev/loop0

echo "format image"
losetup /dev/loop0 ${OUTPUT_FOLDER}/autodeploy.img -o 1048576 # offset of 512*2048 = 1M
mkfs.ext2 /dev/loop0
AUTODEPLOY_MOUNT=${OUTPUT_FOLDER}/autodeploy-mount
[ -d ${AUTODEPLOY_MOUNT} ] && rm -r ${AUTODEPLOY_MOUNT}
mkdir ${AUTODEPLOY_MOUNT}
mount /dev/loop0 ${AUTODEPLOY_MOUNT}

echo "copy files"
cp kernel-bin/imx6q-cubox-i-4.9.7.dtb ${AUTODEPLOY_MOUNT}/imx6q-cubox-i.dtb
cp kernel-bin/zImage-4.9.7 ${AUTODEPLOY_MOUNT}/zImage
mkimage -A arm -O linux -T script -C none -n "U-Boot boot script" -d config/boot.txt ${AUTODEPLOY_MOUNT}/boot.scr
cp ${OUTPUT_FOLDER}/autodeploy-initramfs.cpio.gz ${AUTODEPLOY_MOUNT}/
cp ${CONFIG_FOLDER}/autodeploy-script-source ${AUTODEPLOY_MOUNT}/

mkdir -p ${AUTODEPLOY_MOUNT}/config/global

echo "make root writable"
chmod a+w ${AUTODEPLOY_MOUNT}/

echo "unmount"
umount ${AUTODEPLOY_MOUNT}
losetup -d /dev/loop0
