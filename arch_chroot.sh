#!/bin/bash

USER_NAME=plunne
HOST_NAME=btw

ln -sf /usr/share/zoneinfo/EUROPE/PARIS /etc/localtime

sed -i 's/#en_US.UTF-8/en_US.UTF-8/p' /etc/locale.gen
locale-gen

echo LANG=en_US.UTF-8 > /etc/locale.conf

echo $HOST_NAME > /etc/hostname

echo 127.0.0.1    localhost > /etc/hosts
echo ::1          localhost > /etc/hosts
echo 127.0.1.1    $HOST_NAME.localdomain    $HOST_NAME > /etc/hosts

mkinitcpio -p linux-lts

echo "***** ROOT *****"
passwd

echo "***** USER *****"
useradd -m $USER_NAME
passwd $USER_NAME
usermod -aG wheel,audio,video,optical,storage $USER_NAME

echo "***** GRUB *****"
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub_uefi --recheck 
grub-mkconfig -o /boot/grub/grub.cfg

sed -i 's@^# %wheel ALL@%wheel ALL@p' /etc/sudoers.tmp

cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
list=$(mktemp)
wget 'https://www.archlinux.org/mirrorlist/?country=FR&protocol=http&ip_version=4&use_mirror_status=on' -O  $list
sed -i 's/^#S/S/p' $list
rankmirrors -n 5 $list > /etc/pacman.d/mirrorlist

systemctl enable NetworkManager
systemctl enable dhcpcd

sed -i 's/#[multilib]/[multilib]/p' /etc/pacman.conf
sed -i 's@#Include = /etc/pacman.d/mirrorlist@Include = /etc/pacman.d/mirrorlist@p' /etc/pacman.conf

echo "Install complete !"

exit
