#!/bin/bash

# TODO
#  - sed for WHEEL sudo
#  - sed command for locale file modification
#  - auto vs. interactie mode
#  - microcode install
# BUGS:
#  - hwclock

cat <<"EOF"

Hello,

This is a script to install base packages for the following distros:
   1. Arch Linux OS

The base install includes:
   i. all drivers
   ii. disk partitions
   iii. services for internet i.e. it can access the internet
   iv. git ready i.e. it is setup to configure git ssh access

Requirements
   1. wifi name and password

Running
   1. Boot to Distro USB to root login prompt
   2. bash < (curl -L github.com/insomnicles/scripts/0-install-base.sh)

EOF


arch_greeting() {

cat <<"EOF"

-----------------------------------------------------------------
        .
       / \         _       _  _ 
      /^  \      _| |_     o  o 
     /  _  \    |_   _|     .. 
    /  | | ~\     |_|    \______/ 
   /.-'   '-.\              

-----------------------------------------------------------------

EOF

}

arch_internet() {
   # ethernet should work out of the box
   # mobile requires mbctrl
   iwctl wlan0 station scan
   echo "Enter Wifi Access Point\n"
   read name
   iwctl wlan0 station ${name}
}

arch_base() {
   pacstrap -K /mnt base linux linux-firmware sof-firmware iwd man-db man-pages texinfo neovim vi base-devel sudo pacman-contrib intel-ucode grub efibootmgr git openssh zsh
}

arch_time() {
   timedatectl 
   ln -sf /usr/share/zoneinfo/Canada/Eastern /etc/localtime
   hwclock --systohc
}

arch_locale() {
   sed -i "/en_US.UTF8 UTF8/s/^#//g" /etc/locale.gen
   local-gen
}


arch_partition() {
   # partiioning: EFI /boot, cache, root home
cat <<"EOF"
Partitioning...
EFI/boot:	/dev/sda1
root(/):	/dev/sda2
cache:		/dev/sda3
home (/home):	/dev/sda4
EOF
   mkfs.fat -F 32 /dev/sda1
   mkfs.ext4 /dev/sda2
   mkswap /dev/sda3
   mount --mkdir /dev/sda2 /mnt
   mount --mkdir /dev/sda1 /mnt/boot
   swapon /dev/sda3
   mount --mkdir /dev/sda4 /mnt/home
   genfstab -U /mnt >> /mnt/etc/fstab
   arch-chroot /mnt
}

arch_root() {
   echo "\nEnter Root password"
   passwd
}

arch_enable_sudoers() {
   echo "Uncomment like wheel ALL=(ALL:ALL) ALL"
   read userwait
   #sed -i "/%wheel ALL=(ALL:ALL) ALL/s/^# //g" /etc/sudoers
   visudo
}

arch_user() {
   echo "Enter Regular User Name\n"
   echo "This user will have sudo access\n"
   read new_username
   if [ -d "/home/${new_username}" ]; then
	echo "exit: that user exists already"
   fi
   useradd -m -G wheel -s /bin/bash ${username}
}


arch_network_config() {

cat "EOF"
[Match]
Name=wlan0

[Network]
DHCP=yes
IgnoreCarrierLoss=3s
EOF > /etc/systemd/network/25-wireless.network

mkdir /etc/iwd
cat "EOF"
[General]
EnableNetworkConfiguration=true
EOF > /etc/iwd/main.conf

}

arch_bootloader() {
   pacman -S --needed --noconfirm grub efibootmgr
   grub-install --target=x86_64 --efi-directory=/boot --bootloader-id=GRUB
   grub-mkconfig -o /boot/grub/grub.cfg
}

arch_system_setup() {
   systemctl enable iwd
   systemctl enable systemd-resolved 
   systemctl enable systemd-timesyncd
   systemctl enable sshd
}

arch_install_complete() {
cat <<"EOF"
Installation complete!

- remove USB 
- reboot the system

Distro: Arch (base)
Firmware: linux-firmware, sof-firmware, intel-ucode
Bootloader: grub
Networking: iwd (dhcp), systemd-resolvd (dns)
OS Package Manager: pacman
Version Control: git
Editor: neovim vi
EOF
}

install_arch_base() {
    arch_greeting
    arch_internet
    arch_base
    arch_time
    arch_locale
    arch_partition
    arch_root
    arch_enable_sudoers
    arch_user
    arch_network_config
    arch_bootloader
    arch_system_setuup
    arch_install_complete
}

cat <<"EOF"
Choose you OS
1. Arch Linux Base only
EOF
read choice_os

if [ $choice_os -eq 1 ]; then
    install_arch_base
fi

