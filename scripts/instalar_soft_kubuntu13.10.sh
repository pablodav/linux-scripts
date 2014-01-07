#!/bin/bash
#Version del script = 0.1.7
#Licencia GPL V3
#Fecha de realizado 13 12 2013
#Autores: Pablo Estigarribia
#gusolfraybentos@googlegroups.com
#pablodav@gmail.com
# Ejecute desde una terminal con ./instalar_soft_kubuntu13.10.sh 

codename=`cat /etc/lsb-release | grep CODENAME | cut -d = -f 2`

appsmin=" arista scribus audacity kdenlive gimp inkscape digikam quicksynergy imagination dvdstyler ubuntu-restricted-extras flashplugin-nonfree rekonq network-manager-openvpn vlc shutter apt-offline qapt-deb-installer transmission-qt "
appsinstall=" hydrogen gimp inkscape octave3.2 blender language-pack-es language-pack-kde-es openoffice.org-base qcad gcompris gcompris-sound-es dvdrip tuxpaint ocrad xsane  wine cheese thunderbird thunderbird-locale-es-es filezilla manpages-es deja-dup yakuake kazam mypaint calibre k3b ubuntuone-control-panel-qt " #Aplicaciones a instalar
appsdevel=" kdevelop vim python-virtualenv "
appsremote=" remmina x2goclient ssh x2goserver qweborf "
opcautomatic="n" #Instalación automáticaa del sistema
opcappsinstall="n" #Instalar aplicaciones
opcaddmedibuntu="n" #Add medibuntu repository
opcaddextras="n" #Add extras
opcupgrade="n" #Actualizar sistema
opcaddremote="n" #Agregar apps remotas
opcuseaptoffline="n" # Usar archivo apt-offline
aptofflinefile="archivoaptofflinekubuntu$codename.zip"
opcaptofflinegen="aptofflinegen" #Variable para generar archivo aptoffline


#Added support for precise
if [ $codename != precise ] ; then 
    otherapps=" bookletimposer "
    $appsinstall="$appsinstall $otherapps"
fi


function instalarapps {
    #Actualizo los datos de apt-get
    echo "Actualizar información de apt-get con update"
    sudo apt-get update
    echo "apt-get -f install"
    sudo apt-get -y -f install
    echo "Instalando aplicaciones"$appsinstall""$appsmin""$appsdevel
    sudo apt-fast install -y --force-yes $appsinstall $appsmin $appsdevel
}


function extras {
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

function aplicacionesremotas {
    sudo add-apt-repository ppa:x2go/stable
    sudo apt-fast update
    sudo apt-fast install -y $appsremote
}

function actualizar {
    echo "Actualizo todo el sistema"
    sudo apt-fast update
    sudo apt-fast -y upgrade
}

function aptofflinegenerador {
    echo "inicializando generador apt-offline"
    instalarrequerimientos
    sudo apt-offline set apt.sig --update --upgrade --install-packages $appsinstall $appsdevel $appsmin
    sudo apt-offline get apt.sig --threads 5 --bundle $aptofflinefile
}

function usararchivoaptoffline {
    if [ $aptofflinefile ] ; then
    sudo apt-offline install $aptoffline
    fi
}


function salida {
    echo -e "\n Gracias por Utilizar el script de instalación de aplicaciones útiles para Linux Kubuntu, inicie el 
    script escribiendo $0 $opcaptofflinegen para que genere el archivo offline para usar en otra instalación.
    \n Por errores o sugerencias pablodav@gmail.com. \n" | fmt
    echo "Instalación finalizada. Pulse Enter para terminar"
    read TheEnd
    exit 0
}
 
function instalarrequerimientos {
if [ ! -x /usr/sbin/apt-fast ] && [ ! -x /usr/bin/apt-offline ] ; then
    sudo add-apt-repository ppa:apt-fast/stable
    sudo apt-get update
    sudo apt-get -y install apt-fast
    sudo apt-fast -y install apt-offline
fi
}

case "$1" in
    $opcaptofflinegen) 
        aptofflinegenerador
        salida
    ;;
    'autoinstall')
        echo "Se Instalaran los programas  $appsmin $appsinstall $appsremote $appsdevel y todas las configuraciones automáticamente"
        usararchivoaptoffline
        instalarrequerimientos
        aplicacionesremotas
        extras
        instalarapps
        actualizar
        salida
    ;;
    'manualinstall')
        echo -e "¿Desea instalar las aplicaciones: \n $appsinstall $appsmin $appsdevel ? \n y/n:" | fmt
        read opcappsinstall
        echo "¿Desea agregar los repositorios de medibuntu? y/n:"
        read opcaddextras
        echo "¿Desea actualizar todo el sistema una vez finalizado? y/n:"
        read opcupgrade
        echo "¿Desea agregar apps remotas? y/n:"
        read opcaddremote
    ;;
    'hacercafe')
         echo -e "\n\n Este script le ará un rico Café a Diego y Diego olvidará su amargura!!!"
    ;;
    *)
        echo -e "\n\n Modo de uso: Ejecute el programa con una de estas opciones: \n
        \033[4m$opcaptofflinegen\033[0m: \n
        Para generar un archivo $aptofflinefile con todos los datos de los programas
        a instalar, esto se ejecuta en una máquina sin los programas instalados, así descarga y guarda todo
        en el archivo $aptofflinefile para ser usado luego en otras computadoras. Lo único que tiene que hacer
        para usarlo es tener el archivo $aptofflinefile en el mismo directorio que el script de ejecución $0 \n
        \033[4mautoinstall:\033[0m \n
        Se encargará de usar el archivo $aptofflinefile si existe e instala todos los programas: 
        $appsmin $appsinstall $appsremote $appsdevel \n
        \033[4mmanualinstall:\033[0m \n
        preguntará por las opciones que desea instalar \n\n
        Ejemplo: $0 manualinstall \n\n" | fmt
    ;;
esac


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
fi

salida