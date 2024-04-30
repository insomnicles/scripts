#!/bin/bash

# TODO
#  - microcode install

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

epilogue() {

  cat <<"EOF"

  Stage 1 of installation complete.

  Continue to Stage 2:

  ./0-install-arch-base-stage-2.sh

EOF
}


install_arch_base_stage1() {
   greeting
   partition_setup
   install_base_packages
   epilogue
   arch-chroot /mnt
}

install_arch_base_stage1

