---
type: blog
title: PXE Booting
draft: false
categories: it
date: 2011-04-01T14:49:00+02:00
---
> Disclaimer: This is a VERY old article. I wrote it over 10 years ago when I was working as a system administrator for a small online store.
>
> Many of the setup processes described look terrible now. ​​In today's reality, I would use other tools to set up and maintain such a service.

I have a bootable USB flash drive that contains several tools for loading live systems. Knoppix, Slax, Alkid, Windows XP SP3 distribution, and so on.

One day, I arrived at work without this flash drive. That’s when the idea came to use the built-in feature of most network cards—network booting, also known as PXE technology.

The idea is that when a computer boots up, the network card's bootloader activates, connects to a DHCP server, receives boot instructions via TFTP, and loads the bootloader into memory. This brings up a selection menu for OS boot options over the network. After selecting an OS, it is loaded via NFS or SAMBA.

We'll need a DHCP server, a TFTP server, and either NFS or SAMBA servers.

I already had the first two servers—they were set up on FreeBSD 8.1, which acts as our gateway to the external world. This is one downside: network booting requires significant bandwidth, and when a system starts booting over the network, it might slow down data exchange between other clients and the gateway.

The systems we'll use for booting are Trinity, Partition Magic, FreeBSD booting, and CloneZilla. The most advanced users might ask: why so many similar distributions that perform almost the same tasks?

Here’s the answer—the Unix way. Each task requires its own tool. Trinity is an excellent tool for solving Windows-related problems. Partition Magic is a full-fledged Linux distro for identifying and solving complex issues. FreeBSD booting provides a minimal environment to start a FreeBSD installation. CloneZilla is a ready-made tool for cloning already-installed systems.

Now that the goals are clear, let's implement this.

### Setting up the DHCP Server

The first thing we need is a DHCP server. On FreeBSD, this is `ics-dhcp`, which can be installed using the ports system:

```shell
cd /usr/ports/net/ics-dhcp
make install clean
```

I use `webmin` for configuration, but you can also configure it via the config files.

Here’s my configuration file:

```shell
# dhcpd.conf

default-lease-time 86400;
max-lease-time 864000;

log-facility local7;

subnet 192.168.1.0 netmask 255.255.255.0 {
	next-server 192.168.1.201;
	filename "pxelinux.0";
	range 192.168.1.1 192.168.1.127;
	option domain-name-servers 192.168.1.201;
	option domain-name "mega-lex.local";
	option routers 192.168.1.201;
	option broadcast-address 192.168.1.255;
	default-lease-time 86400;
	max-lease-time 864000;
<-- Skipped -->
```

The line `filename "pxelinux.0"` is of interest here. What it is and where it came from will be explained below. For now, just note that this is the executable code for the network bootloader.

### Setting up the TFTP Server

Next, we need a TFTP server, which is included by default. It can be enabled by uncommenting the relevant line in `/etc/inetd.conf`. You can also configure its root directory there.

### Creating the Bootloader

The third step involves creating the bootloader specified in the configuration for the subnet `192.168.1.0/24`.

Essentially, this involves copying some slightly modified files from a standard Linux/Unix bootloader. There’s even a dedicated project, `syslinux`, from which you can download everything you need.

We’re interested in the bootloader itself and a few files responsible for forming the menu and additional bootloader functions. These files include `gpxelinux.0`, `pxelinux.0`, `vesamenu.c32`, `reboot.c32`, and `chain.c32`.

In the TFTP server’s root folder, create a directory called `pxeboot.cfg` and inside it, a file named `default` with the following content:

```shell
ui vesamenu.c32
# Load image display support
menu title Utilities
# Menu title
menu background wall.png
# Background image

label Boot from first hard disk
# Displayed item
localboot 0x80
# Boot from the first hard disk
  TEXT HELP
  * Skip any loaded OSs. Boot from the First Boot Device.
  * Default
  ENDTEXT

label Clonezilla Live
MENU LABEL Clonezilla Live
KERNEL clone/vmlinuz1
APPEND initrd=clone/initrd1.img boot=live live-config noswap nolocales edd=on nomodeset ocs_live_run="ocs-live-general"  ocs_live_extra_param="" ocs_live_keymap="" ocs_live_batch="no" ocs_lang="" vga=788 nosplash fetch=http://192.168.1.127/filesystem.squashfs
# Note: In this case, the boot occurs via HTTP from another local network machine, not the DHCP server
  TEXT HELP
  * Clonezilla live version: 1.2.6-59-i686. (C) 2003-2011, NCHC, Taiwan
  * Disclaimer: Clonezilla comes with ABSOLUTELY NO WARRANTY
  ENDTEXT

label pmagic
MENU LABEL Partition Magic
LINUX pmagic/bzImage
APPEND initrd=pmagic/initramfs edd=off noapic load_ramdisk=1 prompt_ramdisk=0 rw vga=791 loglevel=0 max_loop=256
# Standard boot via TFTP
  TEXT HELP
  * Partition Magic Linux - Partition Tool
  * Disclaimer: Sometimes used by administrators.
  ENDTEXT

label linux
menu label PLOP Linux
kernel ploplinux/kernel/bzImage
append initrd=ploplinux/kernel/initramfs.gz vga=1 nfsmount=192.168.1.201:/usr/home/still/tftpboot/ploplinux
# Example boot using NFS
  TEXT HELP
  * PLOP Linux
  * Disclaimer: Security tool
  ENDTEXT

label freebsd
menu label FreeBSD 8.2 Install
pxe boot/pxeboot
# Start FreeBSD installation
  TEXT HELP
  * Tool for installing FreeBSD
  * Disclaimer: Mainly used for gateways.
  ENDTEXT

label reboot
menu label Reboot
kernel reboot.c32
# Reboot command
  TEXT HELP
  * Do nothing. Just reboot...
  ENDTEXT

PROMPT 1
# Default option selection
TIMEOUT 100
# Timeout before boot
```

### Directory Structure

The resulting directory structure looks like this:

```shell
tftpboot
|-pxelinux.0
|-vesamenu.c32
|-reboot.c32
|-chain.c32
|-gpxelinux.0
|--clone
|  |-initrd1
|  ˪-vmlinuz1.img
|--pmagic
|  |-bzImage
|  ˪-initramfs
|--ploplinux
|  ˪-kernel
|    |-bzImage
|    ˪-initramfs
˪--boot
   ˪-pxeboot
```

All the mentioned images are either on a properly configured system (NFS, HTTP) or in the TFTP server folder.

And that's it! :-)
