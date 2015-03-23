#!/bin/bash
# Script to create an ubuntu netinstaller for independent installers. 
#Documentation: https://help.ubuntu.com/community/Installation/Netboot 
#https://wiki.debian.org/DebianInstaller/Preseed
#https://www.debian.org/releases/stable/i386/ch04s06.html.en
#http://www.debian.org/releases/stable/i386/apb.html
#
#Used doc: https://help.ubuntu.com/community/Installation/LocalNet
#https://help.ubuntu.com/stable/installation-guide/en.i386/ch04s05.html
#Section: Basic: Hands-On Interactive Network Server Edition Install 
#dhcpd with tftp-hpa. and Advanced: Hands-Off, Preseeded Network Server Install
#
#Experience: Installed many computers at secondary school at my town (pablodav)
#I'm trying to use markup format for comments
# Notas importantes.
#Para hacer las cosas más fáciles voy a precisar reemplazar la dirección ip del servidor en el futuro de forma automática,
#En este ejemplo se usará siempre 192.168.3.10 como ip de servidor tftp, nfs, dhcp, http con mirror. 

debrequirements=" dhcp3-server debmirror tftpd-hpa git nfs-kernel-server nginx "
TFTPIPADDRESS=""
DHCPDNSSERVERS=""
dhcpconfigfile=/etc/dhcp/dhcpd.conf
tftpdir=/var/lib/tftpboot/

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

backupfile(){
    file=${!1}
    sudo cp $file $file.bak
}
    
last_message(){
echo -e "Temporalmente este script fue pensado para funcionar con un servidor con ip 192.168.3.10 static"
echo -e "Por favor configurar $dhcpconfigfile con su rango e ip de servidor local \n" 
}
# Configurar tftpd  y archivos tftpd


# Instalar requerimientos
install_requirements

## Clonar el repo princial, Temporalmente es este: 
git clone https://github.com/pablodav/linux-scripts.git
## Moverse al directorio con los archivos del instalador
cd linux-scripts/netinstall-ubuntu/

# Configurar dhcp3
# ------------
#### Backup - Copy dhcpd.conf

backupfile dhcpconfigfile
cp dhcp3/dhcpd.conf /etc/dhcp/dhcpd.conf


# Configurar tftpd  y archivos tftpd
# ------------
### Uncompress tftp installers (i386, amd64)

#This section: https://www.debian.org/releases/stable/i386/ch04s05.html.en
#then for preparing the files: https://www.debian.org/releases/stable/i386/ch04s05.html.en#tftp-images
#push file var\lib\tftpboot\ubuntu-installer\i386\boot-screens\txt.cfg for installers. 
sudo tar -xzf var/lib/tftpboot/netbootamd64.tar.gz -C $tftpdir
#### Usamos por defecto la configuración de i386 para el archivo de txt.cfg por eso va último.
sudo tar -xzf var/lib/tftpboot/netboot.tar.gz -C $tftpdir


#### Fix permissions to tftpboot
sudo chown root:nogroup -R $tftpdir
sudo chmod o+rx -R $tftpdir

### Copy tftp configuration
#Para hacer las cosas más fáciles voy a precisar reemplazar la dirección ip del servidor en el futuro de forma automática,
#En este ejemplo se usará siempre 192.168.3.10 como ip de servidor tftp, nfs, dhcp, http con mirror. 
sudo rsync -rh --force --chown=root:nogroup var/lib/tftpboot/ubuntu-installer/i386/ $tftpdir/ubuntu-installer/i386/


# Configurar debmirror
# ---------
### Copiar archivo

### Programar cron


# Configurar servidor web
# ----------

### Copiar archivo etc

### Copiar archivos en html 


# Finalizando
last_message