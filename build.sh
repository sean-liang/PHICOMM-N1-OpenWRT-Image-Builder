#!/bin/bash

WORK_DIR=$PWD

read_variable()
{
	read -e -p "$1: " -i "$2" INPUT_VAR
}

mount_image()
{
	LOOP_DEV="$(losetup -P -f --show $1)"
	mount "$LOOP_DEV"p2 $IMAGE_WORK_PATH
}

umount_image()
{
	umount $IMAGE_WORK_PATH
	losetup -d $LOOP_DEV

}

cleanup()
{
	echo "Cleanup."
	rm -f $OPENWRT_WORK_IMG
	rm -f $ARMBIAN_WORK_IMG
	rm -rf $OPENWRT_WORK_PATH
	rm -rf $IMAGE_WORK_PATH
}

read_variable "Enter OpenWRT image path" "./openwrt.img"
OPENWRT_IMG="$INPUT_VAR"

read_variable "Enter Armbian image path" "./armbian.img"
ARMBIAN_IMG="$INPUT_VAR"

echo "OpenWRT Image: $OPENWRT_IMG"
echo "Armbian Image: $ARMBIAN_IMG"

OPENWRT_WORK_IMG="$OPENWRT_IMG".tmp
ARMBIAN_WORK_IMG="$ARMBIAN_IMG".tmp
OPENWRT_WORK_PATH="$WORK_DIR"/openwrt
IMAGE_WORK_PATH="$WORK_DIR"/image

cleanup

echo "Create work images."
cp $OPENWRT_IMG $OPENWRT_WORK_IMG
cp $ARMBIAN_IMG $ARMBIAN_WORK_IMG

echo "Create work directories."
mkdir -p $OPENWRT_WORK_PATH
mkdir -p $IMAGE_WORK_PATH

echo "Copy files from OpenWRT image."
mount_image $OPENWRT_WORK_IMG
mv "$IMAGE_WORK_PATH"/* $OPENWRT_WORK_PATH
rm -rf "$OPENWRT_WORK_PATH"/lib/firmware
rm -rf "$OPENWRT_WORK_PATH"/lib/modules
umount_image $OPENWRT_IMG

echo "Copy files from Armbian image."
mount_image $ARMBIAN_WORK_IMG
mv "$IMAGE_WORK_PATH"/lib/modules "$OPENWRT_WORK_PATH"/lib/
mv "$IMAGE_WORK_PATH"/lib/firmware "$OPENWRT_WORK_PATH"/lib/
mv "$IMAGE_WORK_PATH"/etc/modprobe.d "$OPENWRT_WORK_PATH"/etc/
mv "$IMAGE_WORK_PATH"/etc/fstab "$OPENWRT_WORK_PATH"/etc

for d in `find "$OPENWRT_WORK_PATH"/lib/modules/* -maxdepth 0 -type d`
do
	echo "Link modules in $d."
	cd $d
	for x in `find -name *.ko`
	do
    		ln -s $x .
	done
done
cd $WORK_DIR

echo "Modify boot script."
sed -i '39iulimit -n 51200' "$OPENWRT_WORK_PATH"/etc/init.d/boot

echo "Copy defaut configs."
rsync -a "$WORK_DIR"/files/ $OPENWRT_WORK_PATH

echo "Create firmware image."
rm -rf "$IMAGE_WORK_PATH"/*
mv "$OPENWRT_WORK_PATH"/* $IMAGE_WORK_PATH
sync
umount_image $ARMBIAN_WORK_IMG

echo "Compress firmware image."
mv $ARMBIAN_WORK_IMG n1-firmware.img
rm -f n1-firmware.img.gz
gzip n1-firmware.img

cleanup

echo "All done. Firmware Image: n1-firmware.img.gz"
