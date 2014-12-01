#!/bin/bash
# nagios_import.sh
# Thanks to http://linuxsysadmin.wikispaces.com/Importing+hosts+from+Microsoft+Excel+to+Nagios,+Icinga+etc.
# Modifications done by Pablo Estigarribia.  (just added ALIAS, REMOVED HOSTGROUPS and IMAGE, as it can be added with usage of
# nagios template (use line), so don't need to specify it each time, import for a set of hosts that use same template. I use to work
# with /etc/nagios3/conf.d/templates.cfg to define each one of them.
#
#
# Use input.csv with this format:
# HOST_NAME;DESCRIPTION HERE;IPADDRESS;PARENT;NOTES;NOTES_URL
# REMMEMBER!: you must create the parents in other file .cfg for nagios with or without this script, so you can import them later.
# Your hosts.template must have correct use of template config for nagios. 
#
# once complete:
#cat hosts.cfg >> /etc/nagios3/conf.d/hosts.cfg  # this depends on how and where your configuration is saved

NAGIOSCONFDIR=/etc/nagios3/conf.d
file=$1

function checkping() {
   ping -c 2 $NAME
   if [[ $? -eq 0 ]] ; then 
       PINGRESULT="OK"
   else 
       #ping failed
       echo "Ping failed to $NAME"
       PINGRESULT="FAIL"
	   ping -c 2 $ADDRESS
	   if [[ $? -eq 0 ]] ; then 
           PINGRESULT="OK"
	   fi
   fi
}

function addhostconfig() {
   checkping
   #Add if only ping test is ok
   if [[ "$PINGRESULT" == "OK" ]] ; then 
       cat hosts.template | sed -e "s,TEMP_NAME,$NAME," -e "s,TEMP_ALIAS,$ALIAS," -e "s,TEMP_IP,$ADDRESS," \
	   -e "s,TEMP_PARENTS,$PARENTS," -e "s,TEMP_NOTES,$NOTES," -e "s,TEMP_URLNOTES,$NOTESURL," >> hosts.cfg
   fi
}

cat $file | while read line;
do
echo "${line}"
NAME=`echo ${line} | cut -d\; -f1`
ALIAS=`echo ${line} | cut -d\; -f2`
ADDRESS=`echo ${line} | cut -d\; -f3`
PARENTS=`echo ${line} | cut -d\; -f4`
NOTES=`echo ${line} | cut -d\; -f5`
NOTESURL=`echo ${line} | cut -d\; -f6`
#HOSTGROUPS=`echo ${line} | cut -d\; -f5`
#IMAGE=`echo ${line} | cut -d\; -f3`

#Check if name is found in configuration
grep -q -i $NAME $NAGIOSCONFDIR/*
    if [[ $? -eq 0 ]] ; then
        # do nothing as it already is configured
        echo "nameserver found"
    else
	 # Start configuring new host
        echo "nameserver not found, start configuring"
        addhostconfig
	fi

done
#
# Example for hosts.template file:
# define host{
#        use cctv-template
#        host_name TEMP_NAME
#        alias TEMP_ALIAS
#        address TEMP_IP
#        parents TEMP_PARENTS
#        notes  TEMP_NOTES
#        notes_url      TEMP_URLNOTES
#        }
# Example of template for use line: 
# define host{
#        name                    cctv-template
#        use                     generic-host
#        hostgroups              cctv,cctv-cameras
#        icon_image              webcamera.png
#        statusmap_image         webcamera.png
#        register                0
#}
#
#After you have created the hosts.cfg, you can rename it and copy to your nagios configuration. 

