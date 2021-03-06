#!/bin/bash
# Backup home directory from a remote host that is identified
# by its MAC address to /BACKUP and snapshot it, assuming that
# it is a btrfs-formatted drive.
# (c) Stefan Schroeder 2018

USER=pi

################################################################

MACFILE=/home/$USER/bbbb/mac.txt 

if [ $EUID -ne 0 ] ; then
	echo "You are not root. Giving up."
	exit
fi

if [ -z $(which btrfs) ] ; then
	echo "Missing btrfs-tools. Giving up."
	exit
fi

if [ ! -f $MACFILE ] ; then
	echo "Missing mac-address file. Giving up."
	exit
fi

date 
echo "START $0" 

echo "Wait some time for the network and the disk to spin up."
sleep 30

if [ ! -d /BACKUP ] ; then
	mkdir /BACKUP
else
	echo "Directory /backup already exists. Good."
fi

MAC=$(cat $MACFILE | tr [a-z] [A-Z])
if [ -z $MAC ] ;then
	echo "Cannot find MAC address in mac.txt"
	exit
fi

wakeonlan $MAC

sleep 30

TARGET=$(nmap -sP 192.168.0.0/24 | grep -B2 $MAC | head -1 |awk '{print $6}' | tr -d "[()]")

if [ -z $TARGET ] ; then
	echo "Cannot find target $MAC on local network."
	exit
fi

if $(mount | grep -q BACKUP) ; then 
    echo "Already mounted." 
else 
    mount -t btrfs -o compress=lzo -o subvol=btrhome /dev/sda /BACKUP 
    sleep 3
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

rsync -avz --exclude "*Cache" \
	--exclude "*cache" \
	--exclude "*Trash" \
	--exclude "*.thumbnails" \
	--exclude "*.Crash Reports" \
	--exclude "*.temporary" \
	-e "ssh -o StrictHostkeyChecking=no" root@${TARGET}:/home /BACKUP 

# Usually only day-snapshot.
today_day=$(date +%d) 
SNAP=/BACKUP/SNAPSHOT-$today_day

# But every 1st is going to be monthly as well.
if [ $today_day -eq 1 ] ; then
	today=$(date +%m-%d) 
	SNAP=/BACKUP/SNAPSHOT-$today
fi

if [ -d $SNAP ] ; then
    echo "Deleting existing snapshot $SNAP"
    btrfs subvol delete $SNAP
fi

btrfs subvolume snapshot /BACKUP/ $SNAP

btrfs device stats /BACKUP
btrfs filesystem df /BACKUP

umount /BACKUP

# Is somebody logged in remotely?
logged_in_remote=$(ssh root@${TARGET} 'who')
if [ -z "$logged_in_remote" ] ; then
	echo "Nobody is logged in. Can shutdown remote host."
	ssh root@${TARGET} 'shutdown -h now'
else
	echo "Somebody is logged in remotely. Refusing shutdown of remote host."
fi

sleep 1

date
echo "END $0" 
/bin/sync

# Is somebody logged in locally?
logged_in_local="$(who)"
if [ -z "$logged_in_local" ] ; then
	echo "Nobody is logged in. Can shutdown local host."
	/sbin/shutdown -h 
else
	echo "Somebody is logged in. Refusing shutdown of local host."
	echo "it is: $logged_in_local"
fi
