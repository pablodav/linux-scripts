#!/bin/sh
####################################
#
# Backup to NFS mount script.
#
####################################

# What to backup.
#backup_files="/home /var/spool/mail /etc /root /boot /opt"
backup_files="/etc /var/cache/nagios3 /var/lib/nagios3 /var/lib/nagios /usr/lib/nagios /usr/lib/nagios3"

# Where to backup to.
dest="/home/nagiosadmin/backup/files"

# Create archive filename.
day=$(date +%Y%m%d)
hostname=$(hostname -s)
archive_file="$hostname-$day.tgz"

# Print start status message.
echo "Backing up $backup_files to $dest/$archive_file"
date
echo

# Backup the files using tar.
# Use p to preserve permissions 
tar czfp $dest/$archive_file $backup_files

# Print end status message.
echo
echo "Backup finished"
date

#Delete files older than 1 month
find $dest -type f -mtime +30 -exec rm {} \;

# Long listing of files in $dest to check file sizes.
ls -lh $dest
