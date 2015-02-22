#!/bin/bash
#Script to create an ubuntu netinstaller for independent installers. 
#Documentation: https://help.ubuntu.com/community/Installation/Netboot 
# https://wiki.debian.org/DebianInstaller/Preseed
# http://www.debian.org/releases/stable/i386/apb.html
#
# Used doc: https://help.ubuntu.com/community/Installation/LocalNet
# Section: Basic: Hands-On Interactive Network Server Edition Install 
# dhcpd with tftp-hpa. and Advanced: Hands-Off, Preseeded Network Server Install
#
#Experience: Installed many computers at secondary school in Fray Bentos 2014. 

debrequirements=" dhcp3-server "

instalador(){
    if [ -x /usr/bin/apt-get ] ; then 
        paquetes=${!1}
        echo -e "Instalando paquetes: $paquetes " | fmt -c
        sudo apt-get install -y --force-yes $paquetes
    fi
}

install_requirements(){
    #Similar a: apt-get install dhcp3-server
    instalador debrequirements
}



#Instalar requerimientos

#Configurar dhcp3

#Configurar tftpd  y archivos tftpd

