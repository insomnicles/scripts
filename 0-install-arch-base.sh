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
   2. iwctl wlan0 station "wifi-access-point"
   enter "password"
   3. bash < (curl -L github.com/insomnicles/scripts/0-install-base.sh)

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
   iwctl station wlan0 get-networks
   echo "Enter Wifi Access Point Name\n"
   read name
   iwctl wlan0 station ${name}
}

arch_base() {
   pacstrap -K /mnt base linux linux-firmware sof-firmware iwd man-db man-pages texinfo neovim vi base-devel sudo pacman-contrib intel-ucode grub efibootmgr git openssh zsh
   genfstab -U /mnt >> /mnt/etc/fstab
   arch-chroot /mnt
}

arch_time() {
  timedatectl
  ln -sf /usr/share/zoneinfo/Canada/Eastern /etc/localtime
  hwclock --systohc        # generates /etc/adjtime
}

arch_locale() {
   sed -i "/en_US.UTF8 UTF8/s/^#//g" /etc/locale.gen
   locale-gen
   echo "LANG=en_US.UTF-8" > /etc/locale.conf
}


arch_partition() {

  cat <<"EOF"
Partitioning...
EFI/boot:	/dev/sda1
root(/):	/dev/sda2
cache:		/dev/sda3
home (/home):	/dev/sda4
EOF

   mkfs.fat -F 32 /dev/sda1             # formatting efi boot partition
   mkfs.ext4 /dev/sda2                  # formatting root partition
   mkswap /dev/sda3                     # creating swap partition

   mount --mkdir /dev/sda2 /mnt         # mounting /
   mount --mkdir /dev/sda1 /mnt/boot    # mounting /boot
   mount --mkdir /dev/sda4 /mnt/home    # mounting /home
   swapon /dev/sda3                     # swap on

}

arch_root() {
   echo "\nEnter Root password"
   passwd
}

arch_enable_sudoers() {
   echo "Setting uip soders" #Uncomment like wheel ALL=(ALL:ALL) ALL"
   read new_userwait
   sed -i "/wheel ALL=(ALL:ALL) ALL/s/^# //g" /etc/sudoers
   #visudo
}

arch_user() {
   echo "Enter Regular User Name\n"
   echo "This user will have sudo access\n"
   read new_username
 #   if [ -d "/home/${new_username}" ]; then
	# echo "exit: that user exists already"
 #   fi
   useradd -m -G wheel -s /bin/bash ${new_username}
}


arch_network_config() {

  echo "Enter hostname:"
  read $new_hostname

  echo $new_hostname > /etc/hostname

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
  #pacman -S --needed --noconfirm grub efibootmgr
  grub-install --target=x86_64 --efi-directory=/boot --bootloader-id=GRUB
  grub-mkconfig -o /boot/grub/grub.cfg
}

arch_system_setup() {
  systemctl enable iwd                     # wifi/dhcp
  systemctl enable systemd-resolved        # dns
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

arch_fonts() {
  pacman -S --needed --noconfirm ttf-dejavu gnu-free-fonts
}

arch_X11() {
	declare -a pacs_X11=(
		xorg-server 
		xorg-xinit 
		xf86-input-libinput 
		xorg-server-common 
		xorg-xclipboard 
		xterm 
		xclip
		dmenu 
		i3
		i3lock
		i3status
		i3blocks
		rofi 
	)
	for value in "${pacs_X11[@]}"
	do
		pacman -S --needed --noconfirm $value

	done
}




install_arch_base() {
    arch_greeting
#    arch_internet
    arch_partition
    arch_base
    arch_fonts
    arch_x11
    arch_time
    arch_locale
    arch_network_config
    arch_root
    arch_enable_sudoers
    arch_user
    arch_bootloader
    arch_system_setup
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

