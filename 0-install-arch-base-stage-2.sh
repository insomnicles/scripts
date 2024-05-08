#!/bin/bash

ARCH_HOSTNAME=$1
ARCH_ROOT_PASSWD=$2
ARCH_USERNAME=$3
ARCH_USER_PASSWD=$4
ARCH_WIFI_NETWORK=$5
ARCH_WIFI_NETWORK_PASSWD=$6

#
# x11() {
# 	declare -a pacs_X11=(
#     ttf-dejavu 
#     gnu-free-fonts
# 		xorg-server 
# 		xorg-xinit 
# 		xf86-input-libinput 
# 		xorg-server-common 
# 		xorg-xclipboard 
# 		xorg-wayland
# 		xterm 
# 		xclip
# 		dmenu 
# 		i3-wm
# 		i3-status
#     xfce4-terminal
# 		firefox
# 	)
# 	for value in "${pacs_X11[@]}"
# 	do
# 		pacman -S --needed --noconfirm $value
# 	done
# }

internet() {
   # ethernet should work out of the box
   # mobile requires mbctrl
   #WIFI=`iwctl device list |grep wlan0 | wc -l`
   #if [ ${WIFI} -eq 1 ]; then 
     # printf "\n\nSetting up Wireless Network\n"
     # iwctl station wlan0 get-networks
     # echo "Enter Wifi Access Point Name\n"
     # read name
     #iwctl station wlan0 connect ${ARCH_WIFI_NETWORK} -p ${ARCH_WIFI_NETWORK_PASSWD}
   #fi

   printf "\n\nSetting up Resolv.conf\n" 
   cp /etc/resolv.conf /etc/resolv.conf-bak
   rm -f /etc/resolv.conf
   cd /etc
   ln -sf ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
}

install_arch_base_stage2() {
  echo $ARCH_HOSTNAME
  echo $ARCH_ROOT_PASSWD
  echo $ARCH_USERNAME
  echo $ARCH_USER_PASSWD
  echo $ARCH_WIFI_NETWORK
  echo $ARCH_WIFI_NETWORK_PASSWD

#  x11
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

install_arch_base_stage2 
#2> /root/install-stage2-error.log > /root/install-stage2.log

