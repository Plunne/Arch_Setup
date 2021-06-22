#!/bin/bash

# Time
timedatectl set-timezone Europe/Paris
timedatectl set-ntp true

cfdisk /dev/sda

# Format partitions
mkfs.vfat -F32 /dev/sda1
mkfs.ext4 /dev/sda2

# Mount partitions
mount /dev/sda2 /mnt
mkdir -p /mnt/boot/efi && mount -t vfat /dev/sda1 /mnt/boot/efi

# Prepare CHROOT
pacstrap /mnt base base-devel linux-lts linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab

# START CHROOT
echo "START CHROOT"
arch-chroot /mnt <<EOF
git clone https://github.com/Plunne/Arch_Setup.git
cp -r Arch_Setup/arch-chroot.sh .
EOF
