#!/bin/bash

echo "Comando 1: Actualizando los paquetes del sistema"
apt update -y && apt upgrade -y
sleep 2

echo "Comando 2: Instalando grub2, wimtools, y ntfs-3g"
apt install grub2 wimtools ntfs-3g -y
sleep 2

echo "Comando 3: Obteniendo el tamaño del disco en GB y convirtiendo a MB"
disk_size_gb=$(parted /dev/sda --script print | awk '/^Disk \/dev\/sda:/ {print int($3)}')
disk_size_mb=$((disk_size_gb * 1024))
sleep 2

echo "Comando 4: Calculando el tamaño de la partición (25% del tamaño total)"
part_size_mb=$((disk_size_mb / 4))
sleep 2

echo "Comando 5: Creando la tabla de particiones GPT"
parted /dev/sda --script -- mklabel gpt
sleep 2

echo "Comando 6: Creando la primera partición"
parted /dev/sda --script -- mkpart primary ntfs 1MB ${part_size_mb}MB
sleep 2

echo "Comando 7: Creando la segunda partición"
parted /dev/sda --script -- mkpart primary ntfs ${part_size_mb}MB $((2 * part_size_mb))MB
sleep 2

echo "Comando 8: Informando al kernel de los cambios en la tabla de particiones"
partprobe /dev/sda
sleep 30

echo "Comando 9: Informando al kernel de los cambios en la tabla de particiones (Repetición 2)"
partprobe /dev/sda
sleep 30

echo "Comando 10: Informando al kernel de los cambios en la tabla de particiones (Repetición 3)"
partprobe /dev/sda
sleep 30

echo "Comando 11: Formateando la primera partición como NTFS"
mkfs.ntfs -f /dev/sda1
sleep 2

echo "Comando 12: Formateando la segunda partición como NTFS"
mkfs.ntfs -f /dev/sda2
sleep 2

echo "NTFS partitions created"
sleep 2

echo "Comando 13: Modificando la tabla de particiones con gdisk"
echo -e "r\ng\np\nw\nY\n" | gdisk /dev/sda
sleep 2

echo "Comando 14: Montando la primera partición en /mnt"
mount /dev/sda1 /mnt
sleep 2

echo "Comando 15: Preparando el directorio para el disco de Windows"
cd ~
mkdir windisk
sleep 2

echo "Comando 16: Montando la segunda partición en windisk"
mount /dev/sda2 windisk
sleep 2

echo "Comando 17: Instalando GRUB en /mnt"
grub-install --root-directory=/mnt /dev/sda
sleep 2

echo "Comando 18: Editando la configuración de GRUB"
cd /mnt/boot/grub

cat <<EOF > grub.cfg
menuentry "windows installer" {
	insmod ntfs
	search --set=root --file=/bootmgr
	ntldr /bootmgr
	boot
}
EOF
sleep 2

echo "Comando 19: Cambiando a directorio /root/windisk"
cd /root/windisk
sleep 2

echo "Comando 20: Creando directorio winfile"
mkdir winfile
sleep 2

echo "Comando 21: Descargando la ISO de Windows 10"
wget -O win10.iso --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" https://t.ly/swrq1
sleep 2

echo "Comando 22: Montando la ISO de Windows 10 en winfile"
mount -o loop win10.iso winfile
sleep 2

echo "Comando 23: Copiando archivos de la ISO a /mnt"
rsync -avz --progress winfile/* /mnt
sleep 2

echo "Comando 24: Desmontando winfile"
umount winfile
sleep 2

echo "Comando 25: Descargando virtio.iso"
wget -O virtio.iso https://shorturl.at/lsOU3
sleep 2

echo "Comando 26: Montando virtio.iso en winfile"
mount -o loop virtio.iso winfile
sleep 2

echo "Comando 27: Creando directorio /mnt/sources/virtio"
mkdir /mnt/sources/virtio
sleep 2

echo "Comando 28: Copiando archivos de virtio.iso a /mnt/sources/virtio"
rsync -avz --progress winfile/* /mnt/sources/virtio
sleep 2

echo "Comando 29: Cambiando a directorio /mnt/sources"
cd /mnt/sources
sleep 2

echo "Comando 30: Creando archivo cmd.txt"
touch cmd.txt
sleep 2

echo "Comando 31: Añadiendo comandos a cmd.txt"
echo 'add virtio /virtio_drivers' >> cmd.txt
sleep 2

echo "Comando 32: Actualizando boot.wim con wimlib-imagex"
wimlib-imagex update boot.wim 2 < cmd.txt
sleep 2

echo "Comando 33: Reiniciando el sistema"
reboot
