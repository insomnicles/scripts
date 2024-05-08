# scripts

A script for a minimal Arch OS installation following the installation guide 

# Requirements

- ArchOS on a Bootable USB Media

# Installation

1. Boot ArchOS from USB in **UEFI MODE** 
2. iwctl station wlan0 get-networks
3. iwctl station wlan0 connect "your wifi network"
4. fdisk /dev/sda 
    Partition Drive; e.g..
        /dev/sda1[nvme0n1p1]   1Gb    UEFI          /boot
        /dev/sda2[nvme0n1p2]   25%    Linux Ext 4   / 
        /dev/sda3[nvme0n1p3]   4-8Gb  Linux Cache   
        /dev/sda4[nvme0n1p4]   75%    Linux Ext 4   /home
5. Run 
```
  $ bash <(curl -s https://raw.githubusercontent.com/insomnicles/scripts/main/0-install-arch-base-stage-1.sh)
```

