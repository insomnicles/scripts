#!/bin/bash
#
#   Installation script for base ARCH Linux Installation 
#    - include base packages
#              base X11 packages
#    roughly follows the Installation Guide 
#
ARCH_VERSION=2024-05-01
TIME_ZONE="Canada/Eastern"
LOCALE="en_US.UTF-8 UTF-8"
BASE_PACS=""
X11_PACS="ttf-dejavu gnu-free-fonts xorg-server xorg-xinit xf86-input-libinput xorg-server-common xorg-xclipboard xterm xclip dmenu i3-wm xfce4-terminal firefox"
SYSTEMD_ENABLED="iwd systemd-resolved systemd-timesyncd sshd"

greeting() {

  cat <<EOF

Run script by: 
bash <(curl -s https://raw.githubusercontent.com/insomnicles/scripts/main/0-install-base.sh)  

-----------------------------------------------------------------

Hi, Arch Linux Install Begins.

ARCH VERSION: ${ARCH_VERSION}

Requirements
  1. Bootable USB with ARCH iso
  2. Boot to USB ***in UEFI mode**
  3. partitioned disk using fdisk as follows:
        /dev/sda1[nvme0n1p1]   1Gb    UEFI          /boot
        /dev/sda2[nvme0n1p2]   25%    Linux Ext 4   / 
        /dev/sda3[nvme0n1p3]   4-8Gb  Linux Swap 
        /dev/sda4[nvme0n1p4]   75%    Linux Ext 4   /home

  Continue only if the above are satisfied.

  Press any key to continue. Ctrl-C to exit.

EOF
read cont

}

get_network_inputs() {

  if [ "${WLAN}" -eq 1 ]; then 
    printf "\n\nEnter wifi network:"
    iwctl station wlan0 get-networks
    read inp_wifi

    printf "\n\nEnter wifi password:"
    read inp_wifi_passwd

    export ARCH_WIFI_NETWORK=${inp_wifi}
    export ARCH_WIFI_NETWORK_PASSWD=${inp_wifi_passwd}
  fi

  printf "\n\nEnter hostname:"
  read inp_hostname
  export ARCH_HOSTNAME=${inp_hostname}
}

config_wifi() {
  if [ "${WLAN}" -eq 1 ]; then 
     iwctl station wlan0 connect ${ARCH_WIFI_NETWORK} -p ${ARCH_WIFI_NETWORK_PASSWD}
  fi
}

create_partitions(){

  cat <<"EOF"
Which partition do you want to setup: 
nvme0n1p [Desktop]
sda      [Laptop]

Type One of the above exactly: 
EOF
   read dsk

   mkfs.fat -F 32 /dev/${dsk}1             # formatting efi boot partition
   mkfs.ext4 /dev/${dsk}2                  # formatting root partition
   mkswap /dev/${dsk}3                     # creating swap partition

   mount --mkdir /dev/${dsk}2 /mnt         # mounting /
   mount --mkdir /dev/${dsk}1 /mnt/boot    # mounting /boot
   mount --mkdir /dev/${dsk}4 /mnt/home    # mounting /home
   swapon /dev/${dsk}3                     # swap on
}

install_base_packages() {
   pacstrap -K /mnt base linux linux-firmware sof-firmware iwd man-db man-pages texinfo neovim vi base-devel sudo pacman-contrib intel-ucode grub efibootmgr git openssh zsh 
   genfstab -U /mnt >> /mnt/etc/fstab
}

config_network() {
  echo $ARCH_HOSTNAME > /mnt/etc/hostname
  if [ "${WLAN}" -eq 1 ]; then 
    cat << "EOF" > /mnt/etc/systemd/network/25-wireless.network
[Match]
Name=wlan0

[Network]
DHCP=yes
IgnoreCarrierLoss=3s
EOF

  mkdir -p /mnt/etc/iwd
  cat << "EOF" > /mnt/etc/iwd/main.conf
[General]
EnableNetworkConfiguration=true
EOF
  fi

  printf "\n\nSetting up Resolv.conf\n" 
  cp /mnt/etc/resolv.conf /mnt/etc/resolv.conf-bak
  rm -f /mnt/etc/resolv.conf
  cd /mnt/etc
  ln -sf ../run/systemd/resolve/stub-resolv.conf resolv.conf
}

config_time() {
  arch-chroot /mnt ln -sf /usr/share/zoneinfo/${TIME_ZONE} /etc/localtime
  arch-chroot /mnt hwclock --systohc
}

config_locale() {
  #sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /mnt/etc/locale.gen
  sed -i 's/#${LOCALE}/${LOCALE}/' /mnt/etc/locale.gen
  arch-chroot /mnt locale-gen
  echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
}

install_x11_packages() {
  arch-chroot /mnt pacman -S --noconfirm ${X11_PACS}
  #ttf-dejavu gnu-free-fonts xorg-server xorg-xinit xf86-input-libinput xorg-server-common xorg-xclipboard xterm xclip dmenu i3-wm xfce4-terminal firefox
}

config_users() {
  printf "\nChange Root Password\n"
  arch-chroot /mnt passwd

  printf "\nCreating Sudoers Group\n"
  sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /mnt/etc/sudoers

  printf "\nEnter non-root (sudo) username\n"
  read inp_username
  useradd -m -G wheel -s /bin/bash ${inp_username}
  printf "\n\nUser Password\n"
  passwd ${inp_username}
}

config_systemd() {
  arch-chroot /mnt systemctl enable ${SYSTEMD_ENABLED}
}

install_bootloader() {
  arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
  arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
}

cleanup() {
  cp /root/*.log /mnt/root
}

bye() {
  cat <<"EOF"

Installation complete!

- remove USB 
- reboot the system or type reboot

EOF
}

install_arch_base() {
   greeting

   get_network_inputs

   config_wifi

   create_partitions

   install_base_packages
   
   config_network

   config_time
   
   config_locale

   install_x11_packages

   config_users

   config_systemd

   install_bootloader

   cleanup

   bye
}

install_arch_base 2> ./install-error.log | tee ./install-output.log 

