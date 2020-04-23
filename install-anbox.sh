
#!/bin/bash

set -e

ping -c1 google.com &>/dev/null
if [[ $? -ne 0 ]] || [[ "$EUID" != 0 ]]; then
	echo "Este Script requiere root o no tienes conexion a internet"
	exit 1
else

	#cd "$(mktemp -d)"
	TEMPDIR=`mktemp -d`
	cd $TEMPDIR
	apt-get update
	apt-get install -y git dkms build-essential lzip curl

	#Instalo modulos en el kernel
	git clone https://github.com/anbox/anbox-modules.git
	cp anbox-modules/anbox.conf /etc/modules-load.d/
	cp anbox-modules/99-anbox.rules /lib/udev/rules.d/
	cp -rT anbox-modules/ashmem /usr/src/anbox-ashmem-1
	cp -rT anbox-modules/binder /usr/src/anbox-binder-1
	dkms install anbox-ashmem/1
	dkms install anbox-binder/1

	# Descargo y compilo codigo fuente
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
fi