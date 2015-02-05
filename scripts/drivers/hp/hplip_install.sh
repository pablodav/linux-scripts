#!/bin/bash
#Installer for hp printers
#It uses tar file. 
#Needs the files downloaded.
#Hp 3.15.2
#Ubuntu 14.04
HP_VERSION=3.15.2
TAR_FILE=hplip-$HP_VERSION.tar.gz
DOWNLOAD_LINK=http://prdownloads.sourceforge.net/hplip/$TAR_FILE
SETUP_FOLDER=hplip-$HP_VERSION

#Install Requirements
sudo apt-get install --assume-yes avahi-utils libcups2 cups libcups2-dev cups-bsd cups-client libcupsimage2-dev libdbus-1-dev build-essential ghostscript openssl libjpeg-dev libsnmp-dev libtool libusb-1.0-0-dev wget policykit-1 policykit-1-gnome python3-dbus python3-gi python3-dev python3-notify2 python3-imaging python3-pyqt4 gtk2-engines-pixbuf python3-dbus.mainloop.qt python3-lxml python3 libsane libsane-dev sane-utils xsane

#Uncompress tar file
tar xfz $TAR_FILE

cd $SETUP_FOLDER

#BUILD
./configure --with-hpppddir=/usr/share/ppd/HP --libdir=/usr/lib64 --prefix=/usr --enable-udev-acl-rules --enable-qt4 --disable-libusb01_build --enable-doc-build --disable-cups-ppd-install --disable-foomatic-drv-install --disable-foomatic-ppd-install --disable-hpijs-install --disable-udev_sysfs_rules --disable-policykit --enable-cups-drv-install --enable-hpcups-install --enable-network-build --enable-dbus-build --enable-scan-build --enable-fax-build
make

#Install
sudo make install
sudo usermod -a -G lp $USER