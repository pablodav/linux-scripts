#!/bin/bash
#Version del script = 0.1.8
#Licencia GPL V3
#Fecha de realizado 19/04/2014
#Autores: Pablo Estigarribia
#gusolfraybentos@googlegroups.com
#pablodav@gmail.com
#Modified version for automatic installs with preseed
# Ejecute desde una terminal con ./instalar_soft_kubuntu14.04.sh 

codename=`cat /etc/lsb-release | grep CODENAME | cut -d = -f 2`
fecha=`date +%F`
serialnumber=`sudo sh -c 'dmidecode -s system-serial-number'`
hypervisor=`dmesg --notime | grep -i hypervisor | cut -d ':' -f2 | tr -d " \t\n\r"`
httpserver=192.168.3.10

#Estos estan usados por el liceo: ===========================================================================================
languagepack=" myspell-es libreoffice-l10n-es language-pack-es myspell-es "
appsmin=" scribus audacity vlc gstreamer0.10-plugins-bad-multiverse libavcodec-extra-53 apt-offline "
appsinstall=" libreoffice-calc libreoffice-impress hydrogen qtoctave freemat librecad ocrad manpages-es calibre " #Aplicaciones a instalar
appsdevel=" vim ssh "
# ===========================================================================================================================
# Otros no agregados: qupzilla
#Otros programas en uso general =============================================================================================
appstools=" deja-dup "
appschildrens=" gcompris gcompris-sound-es tuxpaint cheese "
appsmultimedia=" arista dvdstyler vlc shutter hydrogen "
appsgraphics=" inkscape digikam kipi-plugins ffmpg-thumbs hugin-tools mypaint "
appsremote=" remmina x2goclient ssh qweborf "
appsremoteppa=" x2goserver "
appsextras=" scratch software-center  "
appsextrasppa=" handbrake everpad "
appskvmsupport=" xserver-xspice xserver-xorg-video-qxl " 
#============================================================================================================================
#It can't be used in preseed as it asks for license:
othersrestricted=" ubuntu-restricted-extras "
opcautomatic="y" #Instalación automáticaa del sistema
opcappsinstall="n" #Instalar aplicaciones
opcaddmedibuntu="n" #Add medibuntu repository
opcaddextras="n" #Add extras
opcupgrade="n" #Actualizar sistema
opcaddremote="n" #Agregar apps remotas
opcuseaptoffline="n" # Usar archivo apt-offline

drivers=" printer-driver-escpr brother-cups-wrapper-laser printer-driver-hpcups printer-driver-hpijs "

#Variables for lightdm script and xrandr script to setup fixed resolution for old displays: 
xrandrscript=/usr/local/bin/xrandrscript.sh
lightdmstartscript=/usr/share/lightdm/lightdm.conf.d/60-xrandrscript.conf



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

    
    
function reportinstalled {
    sudo tar -cf /tmp/$HOSTNAME_$serialnumber_$fecha.tar /var/log/installer
    
}
function instalador() {
    if [ -x /usr/bin/apt-get ] ; then 
        paquetes=${!1}
        echo -e "Instalando paquetes: $paquetes " | fmt -c
        sudo apt-get install -y --force-yes $paquetes
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
    instalador drivers
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
    instalador languagepack
    #Solo en uso fuera de los liceos, uso general: 
    instalador appsmultimedia
    instalador appsextras
    instalador appsremote
    instalador appsgraphics
    instalador appschildrens
    instalador appstools
    #Add spice packages to virtual machines running on kvm: 
    if [[ "$hypervisor" == 'KVM' ]] ; then 
        instalador appskvmsupport
    fi
}

function xubuntuseed {
    # Esto es para agregar cambios personalizados a la configuración por defecto del escritorio xubuntu
    sudo apt-get purge -y abiword gnumeric xchat pidgin gimp
    wget http://$httpserver/netinstall/skel.tar -O /tmp/skel.tar
    sudo tar -xvpf /tmp/skel.tar -C /
}

function customsettings {
    #Custom settings se usa solo para equipos viejos
    #Added old style configuration for lightdm: 
    sudo  ln -s /usr/share/lightdm/lightdm.conf.d /etc/lightdm/lightdm.conf.d
    #A fix to some old displays in high school at Fray Bentos, fix to 1024x768
    #Some useful information comes from: http://askubuntu.com/questions/63681/how-can-i-make-xrandr-customization-permanent
    sudo sh -c "echo '[SeatDefaults]' > $lightdmstartscript"
    # for your login screen, e.g. LightDM (Ubuntu 11.10) or GDM (11.04 or earlier)
    sudo sh -c "echo 'display-setup-script=$xrandrscript' >> $lightdmstartscript"
    # for your desktop session
    sudo sh -c "echo 'session-setup-script=$xrandrscript' >> $lightdmstartscript"
    sudo sh -c "echo 'xrandr --size 1024x768 --rate 60.0' > $xrandrscript"
    sudo chmod +x $xrandrscript
}


#function extras {
    #echo "Instalando extras"
#    sudo add-apt-repository -y ppa:maxim-s-barabash/sk1project
    #sudo add-apt-repository -y ppa:nvbn-rm/ppa
    #sudo add-apt-repository -y ppa:libreoffice/ppa
    #sudo apt-fast update
#   sudo apt-fast install -y --force-yes python-sk1
    #instalador appsextras
    #if [ ! -x /usr/bin/steam ] ; then 
     #   wget http://media.steampowered.com/client/installer/steam.deb 
      #  sudo dpkg -i steam.deb
    #fi
#}

#function aplicacionesremotas {
 #   sudo add-apt-repository -y ppa:x2go/stable
  #  sudo sed -i 's/trusty/saucy/g' /etc/apt/sources.list.d/x2go-stable-*.list
   # sudo apt-fast update
    #instalador appsremote
#}

function actualizar {
    echo "Actualizo todo el sistema"
    sudo apt-get update
    sudo apt-get -y upgrade
}



#function respaldararchives {
#    echo "Archivando cache en $archivesfile, puede copiarlo para reutilizar"
#    tar uvfp $archivesfile /var/cache/apt/archives
#}


function salida {
    echo -e "\n Gracias por Utilizar el script de instalación de aplicaciones útiles para Linux Kubuntu, inicie el 
    script escribiendo $0 $opcaptofflinegen para que genere el archivo offline para usar en otra instalación.
    \n Por errores o sugerencias pablodav@gmail.com. \n" | fmt
    echo "Instalación finalizada. Pulse Enter para terminar"
#    read TheEnd
    exit 0
}
 


function repotemp {
sed 's;http://archive.ubuntu.com;http://$repo;g' /etc/apt/sources.list.d/*
sed 's;http://archive.ubuntu.com;http://$repo;g' /etc/apt/sources.list
sed 's;http://uy.archive.ubuntu.com;http://$repo;g' /etc/apt/sources.list.d/*
sed 's;http://uy.archive.ubuntu.com;http://$repo;g' /etc/apt/sources.list
}
function backtoroigin {
sed 's;http://$repo;http://archive.ubuntu.com;g' /etc/apt/sources.list.d/*
sed 's;http://$repo;http://archive.ubuntu.com;g' /etc/apt/sources.list
}

case "$1" in
    $opcaptofflinegen) 
        salida
    ;;
    'autoinstall')
        echo "Se Instalaran los programas  $appsmin $appsinstall $appsremote $appsdevel y todas las configuraciones automáticamente"
        instalarapps
        instalardriversprinters
        #Xubuntu seed esta en uso solo en los liceos por ahora
        #xubuntuseed 
        #Custom settings se usa solo para equipos viejos
        #customsettings 
        actualizar
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


if [ "$opcappsinstall" = "y" ] ; then
    instalarapps
fi

if [ "$opcupgrade" = "y" ] ; then
    actualizar
fi

salida
