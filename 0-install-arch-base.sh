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

  if [ "${WLAN}" -eq 1 ]; then 
    printf "\n\nEnter wifi network:"
    iwctl station wlan0 get-networks
    read inp_wifi

    printf "\n\nEnter wifi password:"
    read inp_wifi_passwd

    export ARCH_WIFI_NETWORK=${inp_wifi}
    export ARCH_WIFI_NETWORK_PASSWD=${inp_wifi_passwd}
  fi

  printf "\nEnter hostname:"
  read inp_hostname
  export ARCH_HOSTNAME=${inp_hostname}
}

config_wifi() {
  if [ "${WLAN}" -eq 1 ]; then 
     iwctl station wlan0 connect ${ARCH_WIFI_NETWORK} -p ${ARCH_WIFI_NETWORK_PASSWD}
  fi

  echo -e "\nTesting internet connection..."
  $(ping -c 3 archlinux.org &>/dev/null) || (echo "Not Connected to Network!" && exit 1)
  echo "Connected to the Internet." && sleep 3
}

create_partitions(){

  if [ "${UEFI_MODE}" -eq 1 ]; then
    lsblk 
    cat <<"EOF"
Enter the device you want to Install Arch on:
Type One of the above exactly: 
EOF
    read DEV
    IN_DEVICE=/dev/${DEV}

    #DEVICE_SIZE=sfdisk -s $IN_DEVICE
    DEVICE_SIZE_GB=`lsblk | awk '{ print $4 }' | cut -d G -f 1`
    MEM_SIZE_GB=`free -g -h -t | grep Mem | awk '{print $2}' |cut -dG -f 1`

    #MEM_SIZE_KB=`cat /proc/meminfo |grep MemTotal | cut -d ":" -f 2 | cut -d "k" -f 1 | awk '{$1=$1};1'`  # in KB / 343

    $PART_BOOT_SIZE=1

    echo $MEM_SIZE_GB
    printf "UEFI: ${PART_UEFI_SIZE} Gb\n
            SWAP: ?\n
            ROOT: ? \n
            HOME: remaining \n"

    echo "Enter Swap Partition Size in Gb"
    read PART_SWAP_SIZE

    echo "Enter Root Partition Size in Gb"
    read PART_ROOT_SIZE

    if [[ $IN_DEVICE =~ nvme ]]; then
      PART_BOOT="${IN_DEVICE}p1"
      PART_ROOT="${IN_DEVICE}p2"
      PART_SWAP="${IN_DEVICE}p3" 
      PART_HOME="${IN_DEVICE}p4"
    elif [[ $IN_DEVICE == 'sda' ]]; then
      PART_BOOT="${IN_DEVICE}1"
      PART_ROOT="${IN_DEVICE}2"
      PART_SWAP="${IN_DEVICE}3"  
      PART_HOME="${IN_DEVICE}4" 
    else
      echo "Device not recognized" && exit
    fi

    sgdisk -Z "$IN_DEVICE"
    sgdisk -n 1::+"$PART_BOOT_SIZE" -t 1:ef00 -c 1:EFI "$IN_DEVICE"
    sgdisk -n 2::+"$PART_ROOT_SIZE" -t 2:8300 -c 2:ROOT "$IN_DEVICE"
    sgdisk -n 3::+"$PART_SWAP_SIZE" -t 3:8200 -c 3:SWAP "$IN_DEVICE"
    sgdisk -n 4 -c 4:HOME "$IN_DEVICE"
    #sgdisk -n 4::+"$PART_HOME_SIZE" -t 3:8300 -c 4:HOME "$IN_DEVICE"
  fi 

   mkfs.fat -F 32 ${PART_BOOT}
   mkfs.ext4 ${PART_ROOT}
   mkswap ${PART_SWAP}
   mkfs.ext4 ${PART_HOME}

   mount --mkdir ${PART_ROOT} /mnt          # mounting /
   mount --mkdir ${PART_BOOT} /mnt/boot     # mounting /boot
   mount --mkdir ${PART_HOME /mnt/home      # mounting /home
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
  sed -i 's/#${LOCALE}/${LOCALE}/' /mnt/etc/locale.gen
  arch-chroot /mnt locale-gen
  echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
}

install_x11_packages() {
  arch-chroot /mnt pacman -S --noconfirm ${X11_PACS}
}

config_users() {
  printf "\nChange Root Password\n"
  arch-chroot /mnt passwd

  printf "\nCreating Sudoers Group\n"
  sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /mnt/etc/sudoers

  printf "\nEnter non-root (sudo) username\n"
  read inp_username
  arch-chroot /mnt useradd -m -G wheel -s /bin/bash ${inp_username}

  printf "\nUser Password\n"
  arch-chroot /mnt passwd ${inp_username}
}

config_systemd() {
  printf "\nSetting up Systemd\n"
  arch-chroot /mnt systemctl enable ${SYSTEMD_ENABLED}
}

kernel_modules() {

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
   # greeting
   # boot_mode
   # get_network_inputs
   # config_wifi
   create_partitions
   # install_base_packages
   # config_network
   # config_time
   # config_locale
   # install_x11_packages
   # config_users
   # config_systemd
   # kernel_modules
   # install_bootloader
   # cleanup
   # bye
}

install_arch_base 2> ./install-error.log 

