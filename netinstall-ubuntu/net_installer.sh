#!/bin/bash
#Script to create an ubuntu netinstaller for independent installers. 
#Documentation: https://help.ubuntu.com/community/Installation/Netboot 
# https://wiki.debian.org/DebianInstaller/Preseed
# https://www.debian.org/releases/stable/i386/ch04s06.html.en
# http://www.debian.org/releases/stable/i386/apb.html
#
# Used doc: https://help.ubuntu.com/community/Installation/LocalNet
# https://help.ubuntu.com/stable/installation-guide/en.i386/ch04s05.html
# Section: Basic: Hands-On Interactive Network Server Edition Install 
# dhcpd with tftp-hpa. and Advanced: Hands-Off, Preseeded Network Server Install
#
#Experience: Installed many computers at secondary school at my town (pablodav)

debrequirements=" dhcp3-server debmirror tftpd-hpa "
TFTPIPADDRESS=""
DHCPDNSSERVERS=""

instalador(){
    if [ -x /usr/bin/apt-get ] ; then 
        #Define variable with value of $parameter1
        paquetes=${!1}
        #Show packages and format output
        echo -e "Instalando paquetes: $paquetes " | fmt -c
        sudo apt-get install -y --force-yes $paquetes
    fi
}

install_requirements(){
    #Similar a: apt-get install dhcp3-server
    instalador debrequirements
}

configure_files(){

}

# Instalar requerimientos
install_requirements

# Configurar dhcp3
#### Backup - Copy dhcpd.conf

# Configurar tftpd  y archivos tftpd
# Uncompress tftp installers (i386, amd64)

# This section: https://www.debian.org/releases/stable/i386/ch04s05.html.en
# then for preparing the files: https://www.debian.org/releases/stable/i386/ch04s05.html.en#tftp-images
# push file var\lib\tftpboot\ubuntu-installer\i386\boot-screens\txt.cfg for installers. 

# Configurar debmirror

