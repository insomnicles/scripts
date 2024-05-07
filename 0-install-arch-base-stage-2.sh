#!/bin/bash

HOSTNAME=$1
ROOT_PASSWD=$2
USERNAME=$3
USER_PASSWD=$4
WIFI_NETWORK=$5


x11() {
	declare -a pacs_X11=(
    ttf-dejavu 
    gnu-free-fonts
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

time_setup() {
   ln -sf /usr/share/zoneinfo/Canada/Eastern /etc/localtime
   hwclock --systohc        # generates /etc/adjtime
}

locale_setup() {
   sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
   locale-gen
   echo "LANG=en_US.UTF-8" > /etc/locale.conf
}

root_user() {
   # printf "\n\nEnter Root password\n"
   # passwd
   usermod --password $ROOT_PASSWD root
}

#v TODO: isudo in interactive mode
sudoers() {
    printf "\n\nSetting up sudoers wheel group\n"
   sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
}

nonroot_user() {
   # printf "\n\nEnter Regular User Name (user will have sudo access):\n"
   # read new_username
   #useradd -m -G wheel -s /bin/bash ${new_username}
   #printf "\n\nEnter ${new_username} password\n"
   #passwd ${new_username}
   
   useradd -m -G wheel -s /bin/bash $USERNAME
   usermod --password $USER_PASSWD $USERNAME
}


network_config() {
  # echo "\n\nEnter hostname:\n"
  # read new_hostname
  #echo $new_hostname > /etc/hostname
  echo $HOSTNAME > /etc/hostname

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
   WIFI=`iwctl device list |grep wlan0 | wc -l`
   if [ ${WIFI} -eq 1 ]; then 
     # printf "\n\nSetting up Wireless Network\n"
     # iwctl station wlan0 get-networks
     # echo "Enter Wifi Access Point Name\n"
     # read name
     iwctl station wlan0 connect ${WIFI_NETWORK}
   fi

   printf "\n\nSetting up Resolv.conf\n" 
   cp /etc/resolv.conf /etc/resolv.conf-bak
   rm -f /etc/resolv.conf
   cd /etc
   ln -sf ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
}


bootloader() {
  #pacman -S --needed --noconfirm grub efibootmgr
  print "\n\n Setting up Bootloader\n"
  grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
  grub-mkconfig -o /boot/grub/grub.cfg
}

system_setup() {
  print "\n\n Setting up Daemons\n"
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
  echo $HOSTNAME
  echo $ROOT_PASSWD
  echo $USERNAME
  echo $USER_PASSWD
  echo $WIFI_NETWORK
  exit

  x11
  time_setup
  locale_setup
  network_config
  root_user
  sudoers
  nonroot_user
  system_setup
  internet
  bootloader
  arch_install_complete
}

install_arch_base_stage2 2> /root/install-stage2-error.log > /root/install-stage2.log

