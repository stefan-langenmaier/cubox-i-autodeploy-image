set -eux

OUTPUT_FOLDER="output"
mkdir -p ${OUTPUT_FOLDER}

CONFIG_FOLDER="config"

INITRAMFS_FOLDER="${OUTPUT_FOLDER}/autodeploy-initramfs"

[[ -d ${INITRAMFS_FOLDER} ]] && rm -r ${INITRAMFS_FOLDER}
mkdir -p ${INITRAMFS_FOLDER}/{bin,dev,etc,lib,mnt/root,proc,root,sbin,sys,usr/lib,usr/bin,usr/sbin,etc/ssl/certs,usr/share/ca-certificates}
cp -a /dev/{null,console,tty,tty0,tty1,ram0,urandom,random} ${INITRAMFS_FOLDER}/dev/
cp -a /proc/{net/route,cmdline} ${INITRAMFS_FOLDER}/proc/
cp -a /bin/busybox ${INITRAMFS_FOLDER}/bin/busybox
cp -a ${CONFIG_FOLDER}/start-script ${INITRAMFS_FOLDER}/start-script
chmod +x ${INITRAMFS_FOLDER}/start-script

# dns resolution is dynamically linked even if busybox is static
# https://wiki.gentoo.org/wiki/Custom_Initramfs#DNS
cp /lib/libnss_{dns,files}.so.2 /lib/libresolv.so.2 /lib/ld-linux-armhf.so.3 /lib/ld-2.28.so /lib/libc.so.6 ${INITRAMFS_FOLDER}/lib
cp ${CONFIG_FOLDER}/etc/host.conf ${INITRAMFS_FOLDER}/etc
cp ${CONFIG_FOLDER}/etc/nsswitch.conf ${INITRAMFS_FOLDER}/etc
cp ${CONFIG_FOLDER}/etc/resolv.conf ${INITRAMFS_FOLDER}/etc
cp ${CONFIG_FOLDER}/etc/inittab ${INITRAMFS_FOLDER}/etc


bash copy-recursive-ll.sh /usr/bin/wget ${INITRAMFS_FOLDER}
bash copy-recursive-ll.sh /usr/sbin/parted ${INITRAMFS_FOLDER}
bash copy-recursive-ll.sh /sbin/btrfs ${INITRAMFS_FOLDER}
bash copy-recursive-ll.sh /sbin/mkfs.btrfs ${INITRAMFS_FOLDER}
bash copy-recursive-ll.sh /sbin/mkfs.ext2 ${INITRAMFS_FOLDER}
bash copy-recursive-ll.sh /sbin/mkswap ${INITRAMFS_FOLDER}
bash copy-recursive-ll.sh /usr/sbin/partprobe ${INITRAMFS_FOLDER}
bash copy-recursive-ll.sh /bin/tar ${INITRAMFS_FOLDER}
bash copy-recursive-ll.sh /usr/bin/unxz ${INITRAMFS_FOLDER}

# copy ssl certs
cp -a /etc/ssl/certs/ ${INITRAMFS_FOLDER}/etc/ssl/
cp -a /usr/share/ca-certificates/ ${INITRAMFS_FOLDER}/usr/share/

# install a shell
cd ${INITRAMFS_FOLDER}
ln bin/busybox bin/sh
ln bin/busybox bin/umount
ln bin/busybox init
ln bin/busybox sbin/reboot

# for a seperate file
#cd /usr/src/autodeply-initramfs
find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../autodeploy-initramfs.cpio.gz
#find . -print0 | cpio --null -ov --format=newc | gzip -9 > /boot/custom-initramfs.cpio.gz
cd -
echo "INITRAMFS READY"
