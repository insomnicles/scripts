# Scripts

A script for a minimal Arch OS installation following the installation guide 

# Requirements

- ArchOS on a Bootable USB Media

# Installation

1. Boot ArchOS from USB in **UEFI MODE** 
2. Connect to Internet; e.g.
```
    $ iwd station wlan0 connect homewifi
```
3. Run (note the spaces)
```
    $ bash <(curl -s https://raw.githubusercontent.com/insomnicles/scripts/main/arch-base-install.sh)
```

