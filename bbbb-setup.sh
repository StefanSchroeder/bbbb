#!/bin/bash

exit

MAC=$(cat /home/debian/bbbb/mac.txt | tr [a-z] [A-Z])
if [ -z $MAC ] ;then
	echo "Cannot find MAC address in mac.txt. Check this out:"
	nmap -sP 192.168.0.0/24 
	exit
fi

#TARGET=$(nmap -sP 192.168.0.0/24 | grep -B2 $MAC | head -1 |awk '{print $6}' | tr -d "[()]")

#ssh-keygen -t rsa 
#ssh-copyid root@${TARGET}


#mkfs.btrfs /dev/sda
#mount -t btrfs /dev/sda /mnt/
#btrfs subvolume create /mnt/btrhome
#umount /mnt

#line="@reboot     /usr/local/bin/bbbb.sh"
#(crontab -l; echo "$line" ) | crontab -

