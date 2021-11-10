# partedmagic-autowipe
This is a series of custom scripts used to automatically and securely erase HDD, SSD, and NVMe drives according to the standards laid out in [NIST 800-88](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-88r1.pdf).

This was built for and tested with Parted Magic 02-28-2021. In order to use this you will need to flash the Parted Magic ISO to a USB then copy these files to the USB. Once the files have been copied, update tools/fileserver.cfg with the SMB share path, username of an account that has access, password, and domain. This is where the log files will be saved (you can run without if you do not need to keep log/certificate files). If this was done correctly, the boot menu should have option 1a. Auto on it:
![image](https://user-images.githubusercontent.com/92932337/141137780-346e2ab9-5d46-469f-b88d-abd57ee5f6ef.png)
After selecting Auto Parted Magic will run pmagic/pmodules/scripts/autodetect.sh to determine if there is any SSD/NVMe drives attached. If there is, it will start tools/tuxnukem to wipe them. This is completely automatic and usually takes around 30 seconds to start. Once tuxnukem is finished it will check for any HDDs. If it finds HDDs it will run tools/autoverify-nwipe.sh to wipe them with 3 passes then verify the disk is all 0s with the diskverifier package (this uses a modified version to append disk serial and date/time to log file names). Once verification has finished you should see this output in the terminal:
![image](https://user-images.githubusercontent.com/92932337/141139245-95e382aa-93f2-4a6f-8452-139772419849.png)
Each drive that was successfully wiped will have a certificate generated. Here is an example of one (lines with # require manual entry):

Model: SanDisk_SD8SBAT256G1122

Serial Number: 154223400303

Media Type (i.e., magnetic, flash memory, hybrid, etc.): SATA SSD

#Media Source (i.e., serial of computer the media came from): 

Sanitization Description (i.e., Clear, Purge, Destroy): Clear/Purge via software

Method Used (i.e., degauss, overwrite, block erase, crypto erase, etc.): Block erase

Tool Used (including version): hdparm v9.60

Verification Method (i.e., full, quick sampling, etc.): Full

#Post-Sanitization Destination (if known): Recycled/given to X

#Name of Tech: 

#Position/Title of Tech: 

Date: 11-09-2021

#Location: 1234 Place this was run Ave, 125721 MN

#Phone or Other Contact Information: 

#Signature: _____________________ (signed by lead tech if printed off for customer)

#Data Backup (i.e., if data was backed up, and if so, where): 

In the same log folder should be a diskverifier-current-date-disk-serialnumber.log, nwipe-current-date.log, and tuxnukem-current-date.log. These files should also be backed up for future reference.

# Open Source Licenses
* DISKNUKEM: [ISC License](https://github.com/tslight/disknukem)
* Disk Verifier: [GNU General Public License version 3.0](https://www.hamishmb.com/html/diskverifier.php#:~:text=however%20it%20is%20still%20open-source%20and%20released%20under%20the%20GNU%20GPLv3)
* dcfldd: [GNU General Public License version 2.0](https://sourceforge.net/projects/dcfldd/)
