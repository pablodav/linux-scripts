#!/bin/bash
#Version del script = 0.1.7
#Licencia GPL V3
#Fecha de realizado 13 12 2013
#Autores: Pablo Estigarribia
#gusolfraybentos@googlegroups.com
#pablodav@gmail.com
appsmin=" arista scribus audacity kdenlive gimp inkscape digikam quicksynergy imagination dvdstyler ubuntu-restricted-extras flashplugin-nonfree rekonq network-manager-openvpn vlc shutter apt-offline qapt-deb-installer transmission-qt "
appsinstall=" hydrogen gimp inkscape octave3.2 blender language-support-es openoffice.org-base qcad gcompris gcompris-sound-es dvdrip tuxpaint gnomebaker ocrad xsane  wine cheese thunderbird thunderbird-locale-es-es filezilla manpages-es deja-dup yakuake kazam mypaint calibre k3b bookletimposer ubuntuone-control-panel-qt " #Aplicaciones a instalar
appsdevel=" kdevelop vim python-virtualenv "
appsremote=" remmina x2goclient ssh x2goserver qweborf "
opcautomatic="n" #Instalación automáticaa del sistema
#opcsourcesuy="n" #Agregar repositorios de Uruguay
#opcaptcacher="n" #Agrregar un repositorio apt-cacher
#opcremoveaptcacher="n" #Remover APT cacher
opcappsinstall="n" #Instalar aplicaciones
opcaddmedibuntu="n" #Add medibuntu repository
opcaddextras="n" #Add extras
opcupgrade="n" #Actualizar sistema
opcaddremote="n" #Agregar apps remotas
opcuseaptoffline="n" # Usar archivo apt-offline
aptofflinefile="archivoaptofflinekubuntu1310.zip"
opcaptofflinegen="aptofflinegen" #Variable para generar archivo aptoffline


case "$1" in
    '$opcaptofflinegen') 
    aptofflinegenerador
    salida
    ;;
esac


cd ~
#Algunas preguntas para preparar la instalación
echo -e "Este programa le guiará para realizar la instalación de algunas utilidades en su sistema, puede dejar que realize las configuraciones automáticamente. \n"
echo "¿Desea realizar las configuraciones automáticamente? y/n (para cancelar la ejecución Ctrl+c)"
read opcautomatic



if [ "$opcautomatic" = "y" ] ; then
	echo "Se Instalaran los programas "$appsinstall""$appsmin" y todas las configuraciones automáticamente"
	usararchivoaptoffline
	instalarrequerimientos
	aplicacionesremotas
	extras
	instalarapps
	actualizar
	salida
else
	echo -e "¿Desea instalar las aplicaciones: \n $appsinstall $appsmin $appsdevel ? \n y/n:" | fmt
	read opcappsinstall
	echo "¿Desea agregar los repositorios de medibuntu? y/n:"
	read opcaddextras
	echo "¿Desea actualizar todo el sistema una vez finalizado? y/n:"
	read opcupgrade
	echo "¿Desea agregar apps remotas? y/n:"
	read opcaddremote
fi

if [ "$opcappsinstall" = "y" ] || [ "$opcaddextras" = "y" ] || [ "$opcupgrade" = "y" ] || [ "$opcaddremote" = "y" ] ; then
      instalarrequerimientos
      usararchivoaptoffline
fi

if [ "$opcaddremote" = "y" ] ; then
    aplicacionesremotas
fi

if [ "$opcaddextras" = "y" ] ; then
    extras
fi

if [ "$opcappsinstall" = "y" ] ; then
    instalarapps
fi

if [ "$opcupgrade" = "y" ] ; then
    actualizar
    salida
fi

instalarrequerimientos(){
    if [ ! -x /usr/sbin/apt-fast ] && [ ! -x /usr/sbin/apt-offline] ; then
        echo "Agregar repositorio de apt-fast necesario para trabajar rápido con los repositorios"
        sudo add-apt-repository ppa:apt-fast/stable
        sudo apt-get update
        sudo apt-get -y install apt-fast
        sudo apt-fast -y install apt-offline
    fi
}

instalarapps(){
    #Actualizo los datos de apt-get
    echo "Actualizar información de apt-get con update"
    sudo apt-get update
    echo "apt-get -f install"
    sudo apt-get -y -f install
    echo "Instalando aplicaciones"$appsinstall""$appsmin""$appsdevel
    sudo apt-fast install -y --force-yes $appsinstall $appsmin $appsdevel
}


extras(){
	echo "Instalando extras"
	sudo add-apt-repository ppa:scratch/ppa
	sudo add-apt-repository ppa:stebbins/handbrake-releases
	sudo add-apt-repository	ppa:maxim-s-barabash/sk1project
	sudo add-apt-repository ppa:bjfs/ppa
	sudo apt-fast update
	sudo apt-fast install -y --force-yes python-sk1
	sudo apt-fast install -y --force-yes handbrake-gtk
	sudo apt-fast install -y --force-yes scratch 
}
#Fix drivers issues (ubuntu 12.04)
#	sudo mkdir -p /etc/Wireless/RT2860STA/
#	sudo touch /etc/Wireless/RT2860STA/RT2860STA.dat
#	sudo service network-manager restart

aplicacionesremotas(){
	sudo add-apt-repository ppa:x2go/stable
	sudo apt-fast update
	sudo apt-fast install -y $appsremote
}

actualizar(){
	echo "Actualizo todo el sistema"
	sudo apt-fast update
	sudo apt-fast -y upgrade
}

aptofflinegenerador(){
    instalarrequerimientos
    apt-offline set apt.sig --update --upgrade --install-packages $appsinstall $appsdevel $appsmin
    apt-offline get apt.sig --threads 5 --bundle $aptofflinefile
}

usararchivoaptoffline(){
    if [ $aptofflinefile ] then
    sudo apt-offline install $aptoffline
    fi
}

salida(){
    echo -e "\n Gracias por Utilizar el script de instalación de aplicaciones útiles para Linux Kubuntu, inicie el script escribiendo $0 $opcaptofflinegen 
    \n Por errores o sugerencias pablodav@gmail.com."
    echo "Instalación finalizada. Pulse Enter para terminar"
    read TheEnd
}