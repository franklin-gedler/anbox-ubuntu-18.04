# anbox-ubuntu-18.04

Script para la instalacion del anbox en Ubuntu 18.04 a su vez instala la imagen android con al playstore instalada

- Para instalar apps manualmente abre terminal:

$ adb install path_to_file.apk

- Para ver el estado del service:
sudo systemctl status anbox-container-manager.service
o
sudo service anbox-container-manager status

luego de finalizar la instlacion y reiniciar el equipo, debes abrir el anbox y dentro del android:

settings//apps//

Darles permisos a google play services y google play store
