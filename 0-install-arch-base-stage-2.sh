#!/bin/bash

# 
# TODO
#  - microcode install
# BUGS:
#  - hwclock?????

ARCH_VERSION=2024-04-01

greeting() {

cat <<"EOF"

-----------------------------------------------------------------

Hi, Arch Linux Install **Stage 2**

-----------------------------------------------------------------

ARCH VERSION: ${ARCH_VERSION}

Requirements
  1. Stage 1 of Install was successfull.

Press any key to continue. Ctrl C to exit.
EOF

}

fonts() {
 pacman -S --needed --noconfirm ttf-dejavu gnu-free-fonts
}

x11() {
	declare -a pacs_X11=(
		xorg-server 
		xorg-xinit 
		xf86-input-libinput 
		xorg-server-common 
		xorg-xclipboard 
		xorg-wayland
		xterm 
		xclip
		dmenu 
		i3-wm
		i3-status
    xfce4-terminal
		firefox
	)
	for value in "${pacs_X11[@]}"
	do
		pacman -S --needed --noconfirm $value
	done
}


time() {
   ln -sf /usr/share/zoneinfo/Canada/Eastern /etc/localtime
   hwclock --systohc        # generates /etc/adjtime
}

locale() {
   sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
   locale-gen
   echo "LANG=en_US.UTF-8" > /etc/locale.conf
}

root_user() {
   printf "\nEnter Root password"
   passwd
}

#v TODO: isudo in interactive mode
sudoers() {
   printf "Setting uip soders"
   sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
}

nonroot_user() {
   printf "Enter Regular User Name\n"
   printf "This user will have sudo access\n"
   read new_username
   useradd -m -G wheel -s /bin/bash ${new_username}
   printf "Enter ${new_username} password\n"
   passwd ${new_username}
}


network_config() {
  echo "Enter hostname:"
  read new_hostname
  echo $new_hostname > /etc/hostname

cat << "EOF" > /etc/systemd/network/25-wireless.network
[Match]
Name=wlan0

[Network]
DHCP=yes
IgnoreCarrierLoss=3s
EOF

  mkdir /etc/iwd
cat << "EOF" > /etc/iwd/main.conf
[General]
EnableNetworkConfiguration=true
EOF

}

internet() {
   # ethernet should work out of the box
   # mobile requires mbctrl
   iwctl station wlan0 get-networks
   echo "Enter Wifi Access Point Name\n"
   read name
   iwctl station wlan0 connect ${name}
   mv /etc/resolv.conf /etc/resolv.conf-bak
   ln -sf ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
}


bootloader() {
  #pacman -S --needed --noconfirm grub efibootmgr
  grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
  grub-mkconfig -o /boot/grub/grub.cfg
}

system_setup() {
  systemctl enable iwd                     # wifi/dhcp
  systemctl enable systemd-resolved        # dns
  systemctl enable systemd-timesyncd
  systemctl enable sshd
}

arch_install_complete() {
  cat <<"EOF"
Installation complete!

- remove USB 

- reboot the system or type reboot

EOF
}

install_arch_base_stage2() {
   greeting
   fonts
   x11
   time
   locale
   network_config
   root_user
   sudoers
   nonroot_user
   system_setup
   internet
   bootloader
   install_complete
}

install_arch_base_stage2

