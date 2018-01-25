
ssh-keygen -t rsa 
ssh-copyid root@192.168.0.177

mkfs.btrfs /dev/sda
mount -t btrfs /dev/sda /mnt/
btrfs subvolume create /mnt/btrhome
umount /mnt

line="@reboot     /usr/local/bin/bbbb.sh"
(crontab -l; echo "$line" ) | crontab -

