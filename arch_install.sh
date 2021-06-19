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
arch-chroot /mnt /bin/sh <<EOF

ln -sf /usr/share/zoneinfo/EUROPE/PARIS /etc/localtime
hwclock --systohc

sed -i 's/#en_US.UTF-8/en_US.UTF-8/p' /etc/locale.gen
locale-gen

echo arch > /etc/hostname

echo 127.0.0.1    localhost > /etc/hosts
echo ::1          localhost > /etc/hosts
echo 127.0.1.1    arch.localdomain    arch > /etc/hosts

mkinitcpio -p linux-lts

pacman -Sy -y && pacman -S -y grub efibootmgr sudo pacman-contrib wget networkmanager dhcpcd

grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck 
grub-mkconfig -o /boot/grub/grub.cfg

echo "ROOT"
passwd
echo "USER"
useradd -m plunne
passwd plunne
usermod -aG wheel,audio,video,optical,storage plunne

sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/p' /etc/sudoers.tmp

cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
list=$(mktemp)
wget 'https://www.archlinux.org/mirrorlist/?country=FR&protocol=http&ip_version=4&use_mirror_status=on' -O  $list
sed -i 's/^#S/S/p' $list
rankmirrors -n 5 $list > /etc/pacman.d/mirrorlist

systemctl enable NetworkManager
systemctl enable dhcpcd

sed -i 's/#[multilib]/[multilib]/p' /etc/pacman.conf
sed -i 's@#Include = /etc/pacman.d/mirrorlist@Include = /etc/pacman.d/mirrorlist@p' /etc/pacman.conf

echo "Install complete"

EOF

# Unmount USB
umount -IR /mnt
sleep 2
shutdown now
