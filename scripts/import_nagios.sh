#!/bin/sh
# nagios_import.sh
# Thanks to http://linuxsysadmin.wikispaces.com/Importing+hosts+from+Microsoft+Excel+to+Nagios,+Icinga+etc.
# Modifications done by Pablo Estigarribia.  (just added ALIAS, REMOVED HOSTGROUPS and IMAGE, as it can be added from use in
# nagios template, so don't need to specify it each time, import for a set of hosts that use same template. I use to work
# with /etc/nagios3/conf.d/templates.cfg to define each one of them.
#
# Use input.csv with this format:
# HOST_NAME;DESCRIPTION HERE;IPADDRESS;PARENT
# REMMEMBER!: you must create the parents in other file .cfg for nagios, so you can import them later.
#
# once complete:
#cat hosts.cfg >> /etc/nagios3/conf.d/hosts.cfg  # this depends on how and where your configuration is saved

file=$1
cat $file | while read line;
do
echo "${line}"
NAME=`echo ${line} | cut -d\; -f1`
ALIAS=`echo ${line} | cut -d\; -f2`
ADDRESS=`echo ${line} | cut -d\; -f3`
PARENTS=`echo ${line} | cut -d\; -f4`
#HOSTGROUPS=`echo ${line} | cut -d\; -f5`
#IMAGE=`echo ${line} | cut -d\; -f3`

cat hosts.template | sed -e "s/TEMP_NAME/$NAME/" -e "s/TEMP_ALIAS/$ALIAS/" -e "s/TEMP_IP/$ADDRESS/" -e \
"s/TEMP_HOSTGROUPS/$HOSTGROUPS/" -e "s/TEMP_PARENTS/$PARENTS/" >> hosts.cfg
done
#
# Example for hosts.template file:
# define host{
#        use cctv-template
#        host_name TEMP_NAME
#        alias TEMP_ALIAS
#        address TEMP_IP
#        parents TEMP_PARENTS
#        }
