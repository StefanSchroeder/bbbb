#!/bin/bash

touch /tmp/bbbb.lock

date 
echo "START $0" 

if [ -z $(which btrfs) ] ; then
	echo "Missing btrfs-tools. Giving up."
	exit
fi

if [ ! -d /BACKUP ] ; then
	mkdir /BACKUP
else
	echo "Directory /backup already exists. Good."
fi

MAC=$(cat /home/debian/bbbb/mac.txt | tr [a-z] [A-Z])
if [ -z $MAC ] ;then
	echo "Cannot find MAC address in mac.txt"
	exit
fi

wakeonlan $MAC

sleep 30

TARGET=$(nmap -sP 192.168.0.0/24 | grep -B2 $MAC | head -1 |awk '{print $6}' | tr -d "[()]")

if [ -z $TARGET ] ; then
	echo "Cannot find target $TARGET"
	exit
fi

if $(mount | grep -q BACKUP) ; then 
    echo "Already mounted." 
else 
    mount -t btrfs -o compress=lzo -o subvol=btrhome /dev/sda /BACKUP 
fi

if ping -c 1 $TARGET 
then 
    echo "Host $TARGET is UP. Good." 
else 
    echo "Host DOWN. Giving up." 
    exit -1 
fi

if [ ! -d /BACKUP/home ] ; then
    echo "ERROR: HDD not mounted. Giving up." 
    exit
fi

rsync -avz --exclude "*cache" --exclude "*Trash" -e "ssh" root@192.168.0.138:/home /BACKUP 

today=$(date +%Y-%m-%d) 
# CHECK EXISTENCE FIRST
SNAP=/BACKUP/SNAPSHOT-$today

if [ -d $SNAP ] ; then
    echo "Deleting existing snapshot $SNAP"
    btrfs subvol delete $SNAP
fi

btrfs subvolume snapshot /BACKUP/ $SNAP

btrfs device stats /BACKUP
btrfs filesystem df /BACKUP

umount /BACKUP

# Is somebody logged in?
logged_in=$(ssh root@${TARGET} 'who')
if [ -z $logged_in ] ; then
	echo "Nobody is logged in. Can shutdown."
	# ssh root@${TARGET} 'shutdown -h now'
else
	echo "Somebody is logged in. Cannot shutdown."
fi

sleep 10

date
echo "END $0" 

rm /tmp/bbbb.lock

sync

shutdown -h now

