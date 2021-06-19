#!/bin/sh

# Time
timedatectl set-timezone Europe/Paris
timedatectl set-ntp true

fdisk /dev/sda << EOF
g
n
1

+512M
n
2


t
1
1
t
2
20

w
EOF

# Format partitions
mkfs.vfat -F32 /dev/sda1
mkfs.ext4 /dev/sda2

# Mount partitions
mount /dev/sda2 /mnt
mkdir -p /mnt/boot/EFI && mount -t vfat /dev/sda1 /mnt/boot/EFI

# Prepare CHROOT
pacstrap /mnt base base-devel linux-lts linux-firmware nano
genfstab -U -p /mnt >> /mnt/etc/fstab

# START CHROOT
echo "START CHROOT"
arch-chroot /mnt


