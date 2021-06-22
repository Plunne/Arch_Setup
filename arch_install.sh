#!/bin/sh

# Time
timedatectl set-timezone Europe/Paris
timedatectl set-ntp true

cfdisk /dev/sda

# Format partitions
mkfs.vfat -F32 /dev/sda1
mkfs.ext4 /dev/sda2

# Mount partitions
mount /dev/sda2 /mnt
mkdir -p /mnt/boot/EFI && mount -t vfat /dev/sda1 /mnt/boot/EFI

# Prepare CHROOT
pacstrap /mnt base base-devel linux-lts linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab

# START CHROOT
echo "START CHROOT"
arch-chroot /mnt <<EOF

ln -sf /usr/share/zoneinfo/EUROPE/PARIS /etc/localtime

sed -i 's/#en_US.UTF-8/en_US.UTF-8/p' /etc/locale.gen
locale-gen

echo LANG=en_US.UTF-8 > /etc/locale.conf

echo arch > /etc/hostname

echo 127.0.0.1    localhost > /etc/hosts
echo ::1          localhost > /etc/hosts
echo 127.0.1.1    arch.localdomain    arch > /etc/hosts

mkinitcpio -p linux-lts
EOF

echo "ROOT"
arch-chroot /mnt passwd

echo "USER"
arch-chroot /mnt useradd -m plunne
arch-chroot /mnt passwd plunne
arch-chroot /mnt usermod -aG wheel,audio,video,optical,storage plunne

arch-chroot /mnt <<EOF

pacman -Sy
pacman -S grub efibootmgr sudo pacman-contrib wget networkmanager dhcpcd

grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck 
grub-mkconfig -o /boot/grub/grub.cfg

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
