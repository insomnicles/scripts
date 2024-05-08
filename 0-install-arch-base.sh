#!/bin/bash

ARCH_VERSION=2024-04-01

greeting() {

cat <<"EOF"

Run script by: 
bash <(curl -s https://raw.githubusercontent.com/insomnicles/scripts/main/0-install-base.sh)  

-----------------------------------------------------------------

Hi, Arch Linux Install Begins.

-----------------------------------------------------------------

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

get_inputs() {
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

wifi_setup() {
  WLAN=`iwctl device list |grep wlan0 | wc -l`
  if [ "${WLAN}" -eq 1 ]; then 
     iwctl station wlan0 connect ${ARCH_WIFI_NETWORK} -p ${ARCH_WIFI_NETWORK_PASSWD}
  fi
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

network_config() {

  echo $ARCH_HOSTNAME > /etc/hostname

  cat << "EOF" > /mnt/etc/systemd/network/25-wireless.network
[Match]
Name=wlan0

[Network]
DHCP=yes
IgnoreCarrierLoss=3s
EOF

mkdir /mnt/etc/iwd
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

create_stage2_script() {
  cat << EOF > /mnt/root/0-install-arch-base-stage-2.sh
#!/bin/bash

# Time setup
ln -sf /usr/share/zoneinfo/Canada/Eastern /etc/localtime
hwclock --systohc        # generates /etc/adjtime

# Locale setpu
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# More Packages
pacman -S --noconfirm ttf-dejavu gnu-free-fonts xorg-server xorg-xinit xf86-input-libinput xorg-server-common xorg-xclipboard xterm xclip dmenu i3-wm xfce4-terminal firefox

# Change Root Passowrd
echo "root:${ARCH_ROOT_PASSWD}" | chpasswd

# Create Sudoers Group
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Create non-root user w. sudo access
useradd -m -G wheel -s /bin/bash $ARCH_USERNAME
echo "${ARCH_USERNAME}:${ARCH_USER_PASSWD}" | chpasswd

# Setting up Daemons
systemctl enable iwd systemd-resolved systemd-timesyncd sshd

# Setup Bootloader
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

EOF
}

arch_install_complete() {
  cat <<"EOF"
Installation complete!

- remove USB 
- reboot the system or type reboot

EOF
}

install_arch_base() {
   greeting
   get_inputs
   wifi_setup
   partition_setup
   install_base_packages
   network_config
   create_stage2_script
   arch-chroot /mnt /root/0-install-arch-base-stage-2.sh
   rm /mnt/root/0-install-arch-base-stage-2.sh
   arch_install_complete
}

install_arch_base 

