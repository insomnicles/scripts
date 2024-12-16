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

BASE_PACS="base linux linux-firmware sof-firmware util-linux iwd man-db man-pages texinfo neovim vi base-devel sudo pacman-contrib intel-ucode grub efibootmgr git openssh zsh"
X11_PACS="ttf-dejavu gnu-free-fonts xorg-server xorg-xinit xf86-input-libinput xorg-server-common xorg-xclipboard xterm xclip dmenu i3-wm xfce4-terminal firefox"

SYSTEMD_ENABLED="iwd systemd-resolved systemd-timesyncd sshd"

greeting() {

  cat <<EOF

Welcome to Arch ${ARCH_VERSION} OS Installation.

Press any key to continue. Ctrl-C to exit.

EOF
read cont
}

boot_mode() {
  if [[ ! -d /sys/firmware/efi/efivars ]]; then
    echo "Not in UEFI Mode: boot into UEFI mode"
    exit
  fi
}

get_network_inputs() {
  printf "\nEnter hostname:"
  read inp_hostname
  export ARCH_HOSTNAME=${inp_hostname}
}

config_wifi() {
  echo -e "\nTesting internet connection..."
  $(ping -c 3 archlinux.org &>/dev/null) || (echo "Not Connected to Network!" && exit 1)
  echo "Connected to the Internet." && sleep 3
}

create_partitions(){

    lsblk | grep 'disk' 
    cat <<"EOF"
Enter the disk you want to install Arch on:
Type One of the above exactly: 
EOF
   read DEV
   IN_DEVICE=/dev/${DEV}
   if [[ $IN_DEVICE =~ nvme ]]; then
     PART_BOOT="${IN_DEVICE}p1"
     PART_ROOT="${IN_DEVICE}p2"
     PART_SWAP="${IN_DEVICE}p3" 
     PART_HOME="${IN_DEVICE}p4"
   elif [[ $IN_DEVICE =~ 'sd' ]]; then
     PART_BOOT="${IN_DEVICE}1"
     PART_ROOT="${IN_DEVICE}2"
     PART_SWAP="${IN_DEVICE}3"  
     PART_HOME="${IN_DEVICE}4" 
   else
     echo "Device not recognized" && exit
   fi

   cat <<"EOF"

Do you want to 
1. create all new partitions?
2. keep existing partitions (root partition will be eraased)?

EOF
   read INST_TYPE

   if [ ${INST_TYPE} -eq 1 ]; then 
      printf "\nCreating all new partions\n"
   	#DEVICE_SIZE=sfdisk -s $IN_DEVICE
	    DEVICE_SIZE_GB=`lsblk | grep 'sda\|nvme' | awk '{ print $4 }' | cut -d G -f 1`
    	MEM_SIZE_GB=`free -g -h -t | grep Mem | awk '{print $2}' |cut -dG -f 1`
    	PART_BOOT_SIZE=1

    	printf "\nDevice Size: "
    	lsblk | grep 'sda\|nvme' 
	cat <<EOF
Memory Size: $MEM_SIZE_GB
UEFI: ${PART_BOOT_SIZE} Gb
SWAP: ?
ROOT: ? 
HOME: all space remaining 
EOF
      echo "Enter Swap Partition Size in Gb"
	    read PART_SWAP_SIZE

      echo "Enter Root Partition Size in Gb"
      read PART_ROOT_SIZE

      sgdisk -Z "$IN_DEVICE"
      sgdisk -n 1::+"$PART_BOOT_SIZE"G -t 1:ef00 -c 1:EFI "$IN_DEVICE"
      sgdisk -n 2::+"$PART_ROOT_SIZE"G -t 2:8300 -c 2:ROOT "$IN_DEVICE"
      sgdisk -n 3::+"$PART_SWAP_SIZE"G -t 3:8200 -c 3:SWAP "$IN_DEVICE"
      sgdisk -n 4 -c 4:HOME "$IN_DEVICE"
      #sgdisk -n 4::+"$PART_HOME_SIZE" -t 3:8300 -c 4:HOME "$IN_DEVICE"
   elif [ ${INST_TYPE} -eq 2 ]; then
      printf "\nUsing Existing Partitions\n"
   else 
     printf "\n Command Not Recognized. Exiting."
   fi

   mkfs.fat -F 32 ${PART_BOOT}
   mkfs.ext4 ${PART_ROOT}
   mkswap ${PART_SWAP}

   if [ ${INST_TYPE} -eq 1 ]; then
	   mkfs.ext4 ${PART_HOME}
   fi

   mount --mkdir ${PART_ROOT} /mnt          # mounting /
   mount --mkdir ${PART_BOOT} /mnt/boot     # mounting /boot
   mount --mkdir ${PART_HOME} /mnt/home     # mounting /home
   swapon ${PART_SWAP}                      # swap on
}


install_base_packages() {
   pacstrap -K /mnt ${BASE_PACS}
   genfstab -U /mnt >> /mnt/etc/fstab
}

config_network() {
  cat <<EOF > /mnt/etc/hostname
$ARCH_HOSTNAME
localhost   127.0.0.1
EOF

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
  sed -i 's/#${LOCALE}/${LOCALE}/g' /mnt/etc/locale.gen
  arch-chroot /mnt locale-gen
  echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
}

install_x11_packages() {
  arch-chroot /mnt pacman -S --noconfirm ${X11_PACS}
}

config_systemd() {
  printf "\nSetting up Systemd\n"
  arch-chroot /mnt systemctl enable ${SYSTEMD_ENABLED}
}

config_users() {

  sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /mnt/etc/sudoers

  printf "\nEnter non-root (sudo) username:\n"
  read inp_username
  #arch-chroot /mnt useradd -m -G wheel -s /bin/bash ${inp_username}
  arch-chroot /mnt useradd -m -G wheel -s /bin/bash ${inp_username}

  # added
  arch-chroot /mnt

  printf "\nEnter user ${inp_username} password twice\n"
  #arch-chroot /mnt passwd ${inp_username}
  passwd ${inp_username}

  printf "\nEnter root password twice\n"
  #arch-chroot /mnt passwd
  passwd

}

kernel_modules() {
 echo "Kernel Modules"
 sed -i 's/^HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems resume fsck)/' /etc/mkinitcpio.conf 
 mkinitcpio --config=/etc/mkinitcpio.conf
}

install_bootloader() {
  echo "Creating Bootloader"
  arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
  arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
}

cleanup() {
  echo "Saving Logs"
  me=$(basename "$0")
  cp $me /mnt/root
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
   boot_mode
   get_network_inputs
   config_wifi
   create_partitions
   install_base_packages
   config_network
   config_time
   config_locale
   install_x11_packages
   config_systemd
   config_users
   kernel_modules
   install_bootloader
   cleanup
   bye
}

install_arch_base 2> ./install-error.log 

