#!/bin/bash
# author: Pablo Estigarribia
# license: GPLv3
# This script adds hosts to munin, you can schedule it to just maintain a csv file with the values needed. 
# it needs 2 template files to configure

MUNINTEMPLATESNMPFILE=/usr/local/share/munin/munin.template.snmp 
MUNINTEMPLATEFILE=/usr/local/share/munin/munin.template 
MUNINCONFDIR=/etc/munin/munin-conf.d
HOSTSFILE=/etc/hosts
SNMPCOMMUNITY=public
SNMPVERSION=2c
file=$1

function checksnmp() {
   snmpstatus -c $SNMPCOMMUNITY -v $SNMPVERSION $NAME
   if [[ $? -eq 0 ]] ; then 
       SNMPRESULT="OK"
   else 
       #ping failed
       echo "SNMP failed to $NAME"
       SNMPRESULT="FAIL"
       #exit "Error with SNMP"
   fi
}

function checkping() {
   ping -c 2 $NAME
   if [[ $? -eq 0 ]] ; then 
       PINGRESULT="OK"
   else 
       #ping failed
       echo "Ping failed to $NAME"
       PINGRESULT="FAIL"
   fi
}

function addtohosts() {
        grep -q -i $NAME $HOSTSFILE
        if [[ $? -eq 0 ]] ; then
            # do nothing as it already is configured
            echo "nameserver found in hosts file, do nothing"
        else
            # Start configuring new host
            echo "nameserver not found, start adding to hosts"
            echo "$IP    $NAME" >> $HOSTSFILE
        fi
}

function addmuninplugins() {
   if [[ "$TYPE" == "SNMP" ]] ; then 
       checksnmp
       if [[ "$SNMPRESULT" == "OK" ]] ; then 
           munin-node-configure --shell --snmp $NAME | xargs -L 1 xargs -t
		   cat $MUNINTEMPLATESNMPFILE | sed -e "s,TEMP_GROUP,$GROUP," -e "s,TEMP_NAME,$NAME," >> $MUNINCONFDIR/$GROUP_FILE
       fi
   fi 
}

function addhostconfig() {
   checkping
   if [[ "$PINGRESULT" == "OK" ]] ; then 
       if [[ "$TYPE" == "LINUX" ]] ; then 
       echo "Add if only ping test"
       munin-node-configure --shell $NAME | xargs -L 1 xargs -t
       cat $MUNINTEMPLATEFILE | sed -e "s,TEMP_GROUP,$GROUP," -e "s,TEMP_NAME,$NAME," >> $MUNINCONFDIR/$GROUP_FILE
	   fi
   fi
}

# Reads file with csv values: GROUP;NAME;IP;TYPE 
# if TYPE is SNMP it will configure plugins for SNMP
cat $file | while read line;
    do
    echo "${line}"
    GROUP=`echo ${line} | cut -d\; -f1`
    NAME=`echo ${line} | cut -d\; -f2`
    IP=`echo ${line} | cut -d\; -f3`
    TYPE=`echo ${line} | cut -d\; -f4`
    GROUP_FILE=$GROUP.hosts.conf
	
    #Check if name is found in configuration
    grep -q -i $NAME $MUNINCONFDIR/*
    if [[ $? -eq 0 ]] ;
        then
        # do nothing as it already is configured
        echo "nameserver found"
    else
        # Start configuring new host
        echo "nameserver not found, start configuring"
        addtohosts
        addmuninplugins
        addhostconfig
    fi

done

service munin-node restart


