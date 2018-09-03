# Beaglebone Black Backup

Design for a secure low-cost reliable backup system

Technologies used: BeagleBoneBlack, BTRFS, Wake-on-Lan

------------------------------------------

Risks we want to protect against: 

* Total hard disk failure with no data recoverable
* Ransom-ware attack with no data recoverable

------------------------------------------ 

What needs to be done:

Daily (1) fully automated (2) trivially recoverable (3) backup on an external
(4) medium that is off-line during the day (5).

(1): Take care that you do not lose more than one day's worth of data.  
(2): If it's fully automated, you cannot forget it and you don't to worry 
about it.  
(3): There are two recovery scenarios: Total loss and loss of single
files.  If only a few single files are lost or deleted, it shall be possible to
recover those without need to recover the whole stuff.  
(4): Obviously. Easier to replace. Easier to take somewhere.  
(5): Not online=no attack surface.

------------------------------------------

Idea:

A beaglebone mini-computer is woken up at night with timer based power. The
beagle bone has connected a 1TB external USB hdd that is formatted with btrfs.
The BBB sends a wake-on-lan packet to our target, starting it up.  We use rsync
over ssh with password-less login to sync the /home partition's content to the
/backup partition of the external hdd. After completion, we create a snapshot
of the subvolume, thus effectively keeping a history of the last 31-days. 

For recovery of single files, you can mount any snapshot as a folder and access
the content of that particular snapshot.

Step (1): Install BBB 
=========

Take 4GB Micro SD-card.

Write debian image to it:

Flasher:
(https://elinux.org/Beagleboard:BeagleBoneBlack_Debian)

https://rcn-ee.com/rootfs/bb.org/testing/2018-02-04/stretch-iot/BBB-blank-debian-9.3-iot-armhf-2018-02-04-4gb.img.xz


Flash the SD-image to the mmc as per the instructions here:

FIXME

Change the passwords (for the debian user and the root user) upon first login.

## Install tools.

    sudo apt update
    
    sudo apt get install wakeonlan btrfs-tools ssh nmap git

    mkdir /BACKUP

## Prepare the external harddrive

Assuming the external drive is /dev/sda

    mkfs.btrfs /dev/sda
    mount -t btrfs /dev/sda /mnt/
    btrfs subvolume create /mnt/btrhome
    umount /mnt

## Install Startup-service 

Configure crontab: 

    #!/bin/bash
    line="@reboot     bash /home/debian/bbbb/bbbb.sh"
    (crontab -l; echo "$line" ) | crontab -

## SSH-setup (only once): 

This requires that an SSH-server is running on TARGET and that root-login via SSH is permitted.

    ssh-keygen -t rsa 
    ssh-copy-id root@${TARGET}
