#!/bin/bash
#Version del script = 0.1.8
#Licencia GPL V3
#Fecha de realizado 19/04/2014
#Autores: Pablo Estigarribia
#gusolfraybentos@googlegroups.com
#pablodav@gmail.com
# Ejecute desde una terminal con ./instalar_soft_kubuntu14.04.sh 

codename=`cat /etc/lsb-release | grep CODENAME | cut -d = -f 2`

appsmin=" arista scribus audacity kdenlive gimp inkscape digikam quicksynergy imagination dvdstyler ubuntu-restricted-extras rekonq network-manager-openvpn vlc shutter apt-offline qapt-deb-installer transmission-qt "
appsinstall=" libreoffice-calc libreoffice-impress hugin-tools hydrogen gimp inkscape qtoctave freemat blender language-pack-es language-pack-kde-es librecad gcompris gcompris-sound-es dvdrip tuxpaint ocrad xsane  wine cheese thunderbird thunderbird-locale-es-es filezilla manpages-es deja-dup yakuake kazam mypaint calibre k3b " #Aplicaciones a instalar
appsdevel=" kdevelop vim python-virtualenv "
appsremote=" remmina x2goclient ssh x2goserver qweborf "
appsextras=" handbrake scratch everpad software-center  "
opcautomatic="n" #Instalación automáticaa del sistema
opcappsinstall="n" #Instalar aplicaciones
opcaddmedibuntu="n" #Add medibuntu repository
opcaddextras="n" #Add extras
opcupgrade="n" #Actualizar sistema
opcaddremote="n" #Agregar apps remotas
opcuseaptoffline="n" # Usar archivo apt-offline
aptofflinefile="archivoaptofflinekubuntu$codename.zip"
opcaptofflinegen="aptofflinegen" #Variable para generar archivo aptoffline
drivers=" epson-escpr brother-cups-wrapper-laser  "
archivesfile="archivesfile.tar"


#Added support for precise
if [ "$codename" == "precise" ] ; then 
    #Fix drivers issues (ubuntu 12.04)
    if [ ! /etc/Wireless/RT2860STA/RT2860STA.dat ] ; then 
        sudo mkdir -p /etc/Wireless/RT2860STA/
        sudo touch /etc/Wireless/RT2860STA/RT2860STA.dat
        sudo service network-manager restart
    fi
else
    otherapps=" bookletimposer zram-config "
    appsinstall="$appsinstall $otherapps"
fi

function instalador() {
    if [ -x /usr/sbin/apt-fast ] ; then 
        paquetes=${!1}
        echo -e "Instalando paquetes: $paquetes " | fmt -c
        sudo apt-fast install -y --force-yes $paquetes
    fi
}

function instaladriversamsung {
    #fuente: http://www.bchemnet.com/suldr/
    sudo wget -O - http://www.bchemnet.com/suldr/suldr.gpg | sudo apt-key add - #Agrega clave
    sudo bash -c 'echo "deb http://www.bchemnet.com/suldr/ debian extra" >> /etc/apt/sources.list.d/samsungdriver.list'
    sudo apt-get update
    echo -e 'Favor utilice Synaptic para buscar drivers que empiezan con suld- \n
    Más información encontrará en http://www.bchemnet.com/suldr/ \n'
}

function instaladriversprinters {
    sudo apt-get install $drivers
}

function instalarapps {
    #Actualizo los datos de apt-get
    echo "Actualizar información de apt-get con update"
    sudo apt-get update
    echo "apt-get -f install"
    sudo apt-get -y -f install
    instalador appsinstall 
    instalador appsmin 
    instalador appsdevel
}


function extras {
    echo "Instalando extras"
#    sudo add-apt-repository -y ppa:maxim-s-barabash/sk1project
    sudo add-apt-repository -y ppa:nvbn-rm/ppa
    sudo add-apt-repository -y ppa:libreoffice/ppa
    sudo apt-fast update
#    sudo apt-fast install -y --force-yes python-sk1
    instalador appsextras
    if [ ! -x /usr/bin/steam ] ; then 
        wget http://media.steampowered.com/client/installer/steam.deb 
        sudo dpkg -i steam.deb
    fi
}

function aplicacionesremotas {
    sudo add-apt-repository -y ppa:x2go/stable
    sudo sed -i 's/trusty/saucy/g' /etc/apt/sources.list.d/x2go-stable-*.list
    sudo apt-fast update
    instalador appsremote
}

function actualizar {
    echo "Actualizo todo el sistema"
    sudo apt-fast update
    sudo apt-fast -y upgrade
}

function aptofflinegenerador {
    echo "inicializando generador apt-offline"
    sudo apt-offline set apt.sig --update --upgrade --install-packages $appsinstall $appsdevel $appsmin
    sudo apt-offline get apt.sig --threads 5 --bundle $aptofflinefile
}

function usararchivoaptoffline {
    if [ $aptofflinefile ] ; then
    sudo apt-offline install $aptofflinefile
    fi
    #Descomprimir cache apt: sudo tar xvf archives.tar -C /
    if [ $archivesfile ] ; then 
    sudo tar xvf $archivesfile -C /
    fi
}

function respaldararchives {
    echo "Archivando cache en $archivesfile, puede copiarlo para reutilizar"
    tar uvfp $archivesfile /var/cache/apt/archives
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
    sudo add-apt-repository -y ppa:apt-fast/stable
    #Temporal workaround to get apt-fast working on trusty thar:
    sudo sed -i 's/trusty/saucy/g' /etc/apt/sources.list.d/apt-fast-stable-*.list
    sudo apt-get update
    sudo apt-get -y install apt-fast
    sudo apt-fast install -y apt-offline
fi
}

function repotemp {
sed 's/http:\/\/archive.ubuntu.com/http:\/\/$repo/g' /etc/apt/sources.list.d/*
sed 's/http:\/\/archive.ubuntu.com/http:\/\/$repo/g' /etc/apt/sources.list
sed 's/http:\/\/uy.archive.ubuntu.com/http:\/\/$repo/g' /etc/apt/sources.list.d/*
sed 's/http:\/\/uy.archive.ubuntu.com/http:\/\/$repo/g' /etc/apt/sources.list
}
function backtoroigin {
sed 's/http:\/\/$repo/http:\/\/archive.ubuntu.com/g' /etc/apt/sources.list.d/*
sed 's/http:\/\/$repo/http:\/\/archive.ubuntu.com/g' /etc/apt/sources.list
sed 's/http:\/\/$repo/http:\/\/uy.archive.ubuntu.com/g' /etc/apt/sources.list.d/*
sed 's/http:\/\/$repo/http:\/\/uy.archive.ubuntu.com/g' /etc/apt/sources.list
}

case "$1" in
    $opcaptofflinegen) 
        instalarrequerimientos
        aptofflinegenerador
        salida
    ;;
    'autoinstall')
        echo "Se Instalaran los programas  $appsmin $appsinstall $appsremote $appsdevel y todas las configuraciones automáticamente"
        instalarrequerimientos
        usararchivoaptoffline
        aplicacionesremotas
        extras
        instalarapps
        actualizar
        respaldararchives
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
    'samsungdriver')
        instaladriversamsung
    ;;
    'driversprinters')
        instaladriversprinters
    ;;
    'respaldararchives' )
        respaldararchives
    ;;
    *)
        echo -e "\n\n Modo de uso: Ejecute el programa con una de estas opciones: \n
        \033[4m$opcaptofflinegen\033[0m: \n
        Para generar un archivo $aptofflinefile con todos los datos de los programas
        a instalar, esto se ejecuta en una máquina sin los programas instalados, así descarga y guarda todo
        en el archivo $aptofflinefile para ser usado luego en otras computadoras. Lo único que tiene que hacer
        para usarlo es tener el archivo $aptofflinefile en el mismo directorio que el script de ejecución $0 \n
        \033[4mrespaldararchives\033[0m: \n
        Puede generar un archivo $archivesfile con esta opción, esto respalda todos los archivos del cache de apt. 
        luego se usa automáticamente si está en el mismo directorio donde se ejecuta eñ script. \n
        \033[4mautoinstall\033[0m: \n
        Se encargará de usar el archivo $aptofflinefile si existe e instala todos los programas: 
        $appsmin $appsinstall $appsremote $appsdevel \n
        \033[4msamsungdriver\033[0m: \n
        Agrega el repositorio de drivers de Samsung: http://www.bchemnet.com/suldr/ \n
        \033[4mdriversprinters\033[0m: \n
        Instala los drivers $drivers \n
        \033[4mmanualinstall\033[0m: \n
        preguntará por las opciones que desea instalar \n\n
        Ejemplo: $0 manualinstall \n\n" | fmt -c 
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
