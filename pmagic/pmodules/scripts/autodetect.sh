#! /usr/bin/env bash
#Define colors to be used when echoing output
readonly NC=$(tput sgr0)
readonly BOLD=$(tput bold)
readonly BLACK=$(tput setaf 0)
readonly RED=$(tput setaf 1)
readonly GREEN=$(tput setaf 2)
readonly YELLOW=$(tput setaf 3)
readonly BLUE=$(tput setaf 4)
readonly MAGENTA=$(tput setaf 5)
readonly CYAN=$(tput setaf 6)
readonly WHITE=$(tput setaf 7)

readonly DISKS=$(lsblk -io KNAME,TRAN,TYPE | awk '/sata|nvme/ && /disk/ && !/sr0/ {print $1}')

#Get usb drive path
IFS=$'\n'
for mtabline in `cat /etc/mtab`; do 
  device=`echo $mtabline | cut -f 1 -d ' '`
  udevline=`udevadm info -q path -n $device 2>&1 |grep usb` 
  if [ $? == 0 ] ; then
	devpath=`echo $mtabline | cut -f 2 -d ' '`
	#echo "$devpath"
  fi
done

#copy scripts to live linux install to allow for removing usb
mkdir -p /tmp/tools
chmod +x "$devpath/tools/" -R
cp -r "$devpath/tools/"* /tmp/tools/
chmod +x /tmp/tools/ -R

ssdcount="0"
ssdcheck () {
    local disk="$1"
    local -i ans

    ans=$(cat /sys/block/"$disk"/queue/rotational)

    if ((ans == 0)); then
	echo "${BOLD}${YELLOW}$disk is ssd${NC}"
	let "ssdcount = ssdcount + 1"
    else
	echo "${BOLD}${YELLOW}$disk is hdd${NC}"
    fi
}
for disk in $DISKS
do
    echo "${CYAN}${BOLD}Checking if $disk is ssd or hdd..."
    ssdcheck "$disk"
done
#if SSDs are found this will start tuxnukem to wipe them. tuxnukem also runs a check for hdds at the end and boots into nwipe if they are found.
if ((ssdcount == 0)); then
	echo "${CYAN}${BOLD}No SSDs found. Booting into nwipe...${NC}"
	mkdir -p /home/partedmagic/.config/autostart
	cp "/tmp/tools/autoverify-nwipe.sh" /tmp/autoverify-nwipe.sh
	cp "/tmp/tools/autoverify-nwipe.desktop" /home/partedmagic/.config/autostart/
	chmod +x /tmp/autoverify-nwipe.sh
	chmod +x /home/partedmagic/.config/autostart/autoverify-nwipe.desktop
	sleep 5
	exit 0
else
	echo "${CYAN}${BOLD}SSDs found. Starting tuxnukem to wipe them...${NC}"
	sleep 5
	sh "/tmp/tools/tuxnukem" -a
fi