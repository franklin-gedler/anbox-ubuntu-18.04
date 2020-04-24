#!/bin/bash

ping -c1 google.com &>/dev/null
if [[ $? -ne 0 ]] || [[ "$EUID" != 0 ]]; then
	echo "Este Script requiere sudo o no tienes conexion a internet"
	exit 1
else

	varusr=$(who > /tmp/varusr && awk -F: '{ print $1}' /tmp/varusr | tr -d '[[:space:]]')
	idusr=$(id -u $varusr)

	#cd "$(mktemp -d)"
	TEMPDIR=`mktemp -d`
	cd $TEMPDIR
	apt-get update
	apt install -y git dialog dkms lzip curl build-essential cmake cmake-data debhelper dbus google-mock \
	libboost-dev libboost-filesystem-dev libboost-log-dev libboost-iostreams-dev \
    libboost-program-options-dev libboost-system-dev libboost-test-dev \
    libboost-thread-dev libcap-dev libsystemd-dev libegl1-mesa-dev \
    libgles2-mesa-dev libglm-dev libgtest-dev liblxc1 \
    libproperties-cpp-dev libprotobuf-dev libsdl2-dev libsdl2-image-dev lxc-dev \
    pkg-config protobuf-compiler android-tools-adb android-tools-fastboot

	#Instalo modulos en el kernel
	git clone https://github.com/anbox/anbox-modules.git
	cp anbox-modules/anbox.conf /etc/modules-load.d/
	cp anbox-modules/99-anbox.rules /lib/udev/rules.d/
	cp -rT anbox-modules/ashmem /usr/src/anbox-ashmem-1
	cp -rT anbox-modules/binder /usr/src/anbox-binder-1
	dkms install anbox-ashmem/1
	dkms install anbox-binder/1
	modprobe ashmem_linux
	modprobe binder_linux

	# Descargo y compilo codigo fuente (ver si asi no pide password para iniciar el soft)
	git clone https://github.com/anbox/anbox.git
	cd anbox
	mkdir build
	cd build
	cmake ..
	make

	make install

	# Descargo la imagen de android
	mkdir /var/lib/anbox/
	wget https://build.anbox.io/android-images/2018/07/19/android_amd64.img -O /var/lib/anbox/android.img 2>&1
	cp $TEMPDIR/anbox/scripts/*.sh /usr/local/share/anbox/
	
	# Descargo file
	cd $TEMPDIR
	wget https://raw.githubusercontent.com/franklin-gedler/anbox-ubuntu-18.04/master/anbox-container-manager.service 2>&1
	wget https://raw.githubusercontent.com/franklin-gedler/anbox-ubuntu-18.04/master/anbox-session-manager.service 2>&1
	wget https://raw.githubusercontent.com/franklin-gedler/anbox-ubuntu-18.04/master/anbox.desktop 2>&1
	wget https://github.com/franklin-gedler/anbox-ubuntu-18.04/raw/master/anbox.png 2>&1
	wget https://github.com/franklin-gedler/anbox-ubuntu-18.04/raw/master/anbox.1.gz 2>&1
	wget https://raw.githubusercontent.com/franklin-gedler/anbox-ubuntu-18.04/master/install-playstore.sh 2>&1

	# los muevo a la ruta que corresponde
	cp anbox-container-manager.service /lib/systemd/system/
	cp anbox-session-manager.service /usr/lib/systemd/user/
	cp anbox.desktop /usr/share/applications/
	cp anbox.png /usr/share/pixmaps/
	cp anbox.1.gz /usr/share/man/man1/

	# cargo e inicio los demonios
	systemctl enable /lib/systemd/system/anbox-container-manager.service
	systemctl enable /usr/lib/systemd/user/anbox-session-manager.service
	systemctl start /lib/systemd/system/anbox-container-manager.service
	systemctl start /usr/lib/systemd/user/anbox-session-manager.service

	# ejecuto el script para instalar playstore
	chmod +x install-playstore.sh
	source install-playstore.sh

	# Mje al usuario
	dialog --title "README" --msgbox "Listo . . \n Para completar la instalacion es necesario \n reiniciar el equipo"." \n   Created by Franklin Gedler Support Team" 0 0
	clear
	reboot	

fi