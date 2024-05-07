#!/bin/bash

# TODO
#  microcode install

ARCH_VERSION=2024-04-01

greeting() {

cat <<"EOF"

-----------------------------------------------------------------

Hi, Arch Linux Install Begins.

-----------------------------------------------------------------

ARCH VERSION: ${ARCH_VERSION}

Requirements
  1. bootable USB with ARCH iso
  2. Boot to Distro USB to root login prompt
  3. iwctl wlan0 station get-networks
  4. iwctl wlan0 station connect "wifi-access-point-name"
  5. partitioned disk as shown:
        Partitioning...
        /dev/sda1[nvme0n1p1]   1Gb    UEFI          /boot
        /dev/sda2[nvme0n1p2]   25%    Linux Ext 4   / 
        /dev/sda3[nvme0n1p3]   4-8Gb  Linux Cache   
        /dev/sda4[nvme0n1p4]   75%    Linux Ext 4   /home
  6. bash < (curl -s https://raw.githubusercontent.com/insomnicles/scripts/main/0-install-base.sh)

  Continue only if the above have been done correctly.

  Press any key to continue. Ctrl-C to exit.
EOF
read cont

}

partition_setup() {

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

download_stage2_script() {
   curl -s https://raw.githubusercontent.com/insomnicles/scripts/main/0-install-arch-base-stage-1.sh > /mnt/root/0-install-arch-base-stage-1.sh
   curl -s https://raw.githubusercontent.com/insomnicles/scripts/main/0-install-arch-base-stage-2.sh > /mnt/root/0-install-arch-base-stage-2.sh
   chmod +x /mnt/root/0-install-arch-base-stage-1.sh
   chmod +x /mnt/root/0-install-arch-base-stage-2.sh
}

get_parameters() {
  printf "\n\nEnter hostname:"
  read inp_hostname

  printf "\n\nEnter root password:"
  read inp_root_passwd

  printf "\n\nEnter user name:"
  read inp_username

  printf "\n\nEnter ${username} password:"
  read inp_user_passwd

  printf "\n\nEnter wifi network:\n"
  #iwctl wlan0 get-networks
  read inp_wifi

  printf "\n\nEnter wifi password:\n"
  read inp_wifi_passwd

  export ARCH_HOSTNAME=${inp_hostname}
  export ARCH_ROOT_PASSWD=${inp_root_passwd}
  export ARCH_USERNAME=${inp_username}
  export ARCH_USER_PASSWD=${inp_user_passwd}
  export ARCH_WIFI_NETWORK=${inp_wifi}
  export ARCH_WIFI_NETWORK_PASSWD=${inp_wifi_passwd}
}

install_arch_base_stage1() {
   greeting
   get_parameters
   partition_setup
   install_base_packages
   download_stage2_script
   arch-chroot /mnt bash /root/0-install-arch-base-stage-2.sh $ARCH_HOSTNAME $ARCH_ROOT_PASSWD $ARCH_USERNAME $ARCH_USER_PASSWD $ARCH_WIFI_NETWORK $ARCH_WIFI_NETWORK_PASSWD
   #rm /mnt/root/0-install-arch-base-stage-2.sh
   #reboot
}

install_arch_base_stage1 
