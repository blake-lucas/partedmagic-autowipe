#! /bin/bash
# sync time with NIST's servers
readonly DISKS=$(lsblk -io KNAME,TRAN,TYPE | awk '/sata|nvme/ && /disk/ && !/sr0/ {print $1}')
echo "Updating system time with time.nist.gov..."
ntpdate -u time.nist.gov 2> /dev/null
sleep 1
# create temp bash scripts for each drive because disk verifier can only do 1 at a time via command line
for disk in $DISKS
do
    echo "Creating autoverify script for $disk..."
    echo "python3 /run/br_ram/u/usr/share/diskverifier/diskverifier.py -s -c -d /dev/$disk -p 100" > /tmp/verify-$disk.sh
done
# run disk verifier on each drive
for disk in $DISKS
do
	echo "Running autoverify script for $disk..."
	xfce4-terminal -e "sh /tmp/verify-$disk.sh"
done
echo "Waiting for verification to finish..."
sleep 10

while true; do
  str=`tail --pid=$(ps -eo comm,pid | awk '$1 == "python3" { print $2 }') -f /dev/null 2> /dev/null`
  if [[ $str = "" ]]; then
  echo "Verification finished, copying log files to file server."
  cp /root/diskverifier*.log "/mnt/logshare/"
    break
  fi
  sleep .5
done

# create certificate for wiped drives
hddcheck () {
	local disk="$1"
	local -i ans

	ans=$(cat /sys/block/"$disk"/queue/rotational)

	if ((ans != 0)); then
	disktype="HDD"
	else
	disktype="SSD"
	fi
}
getmethod () {
	local disk="$1"
	local -i ans

	ans=$(cat /sys/block/"$disk"/queue/rotational)

	if ((ans != 0)); then
	method="Overwrite"
    toolused="nwipe version 0.30"
	else
	method="Block erase"
    toolused="hdparm v9.60"
	fi
}
wipecheck () {
	local disk="$1"
	local serial=$(lsblk -no SERIAL /dev/$disk)
	local string="/dev/$disk: OK"
	local logfile=$(ls /root/ | grep $serial)
	
	if grep -xq "$string" "/root/$logfile" ; then
	verified="yes"
	else
	verified="no"
	fi
	
}
# create certificate for wiped drives
for disk in $DISKS
do
	wipecheck "$disk"
	# check if verification has passed for disk
	if [ "$verified" == "yes" ]; then
		# get model, serial, manufacturer, etc
		model=$(lsblk -no MODEL /dev/$disk)
		serial=$(lsblk -no SERIAL /dev/$disk)
		hddcheck "$disk"
		getmethod "$disk"
		certificatename="certificate-$(date '+%Y-%m-%d--%I-%M-%S-%p')-$model-$serial.txt"
		echo "Creating certificate for $disk..."
		#echo "Manufacturer: " >> /root/$certificatename
		echo "Model: $model" >> /root/$certificatename
		echo "Serial Number: $serial" >> /root/$certificatename
		echo "Media Type (i.e., magnetic, flash memory, hybrid, etc.): $(lsblk -no TRAN /dev/$disk | tr [a-z] [A-Z]) $disktype" >> /root/$certificatename
		echo "Media Source (i.e., serial of computer the media came from): " >> /root/$certificatename
		echo "Sanitization Description (i.e., Clear, Purge, Destroy): Clear/Purge via software" >> /root/$certificatename
		echo "Method Used (i.e., degauss, overwrite, block erase, crypto erase, etc.): $method" >> /root/$certificatename
		echo "Tool Used (including version): $toolused" >> /root/$certificatename
		echo "Verification Method (i.e., full, quick sampling, etc.): Full" >> /root/$certificatename
		echo "Post-Sanitization Destination (if known): " >> /root/$certificatename
		echo "Name of Tech: " >> /root/$certificatename
		echo "Position/Title of Tech: " >> /root/$certificatename
		echo "Date: $(date '+%m-%d-%Y')" >> /root/$certificatename
		echo "Location: " >> /root/$certificatename
		echo "Phone or Other Contact Information: " >> /root/$certificatename
		echo "Signature: _____________________" >> /root/$certificatename
		echo "Data Backup (i.e., if data was backed up, and if so, where): " >> /root/$certificatename
	else
		echo "$disk failed verification. no certificate will be generated."
	fi
done
cp /root/certificate*.txt "/mnt/logshare/"
read -rsp $'Log files have been copied. You can shut the computer down now.\nYou can also press any key to close this window and continue.\n' -n1 key