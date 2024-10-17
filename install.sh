#!/bin/bash

# Actualización e instalación de paquetes
echo "Actualizando y mejorando el sistema..."
apt update -y && apt upgrade -y || { echo "Error al actualizar el sistema"; exit 1; }
sleep 2

echo "Instalando grub2, wimtools y ntfs-3g..."
apt install grub2 wimtools ntfs-3g -y || { echo "Error al instalar los paquetes necesarios"; exit 1; }
sleep 2

# Obtener tamaño del disco
echo "Obteniendo el tamaño del disco..."
disk_size_gb=$(parted /dev/sda --script print | awk '/^Disk \/dev\/sda:/ {print int($3)}')
disk_size_mb=$((disk_size_gb * 1024))
sleep 2

# Calcular tamaño de la partición
echo "Calculando el tamaño de la partición (25% del disco)..."
part_size_mb=$((disk_size_mb / 4))
sleep 2

# Crear tabla de particiones GPT
echo "Creando tabla de particiones GPT..."
parted /dev/sda --script -- mklabel gpt || { echo "Error al crear la tabla GPT"; exit 1; }
sleep 2

# Crear particiones
echo "Creando la primera partición..."
parted /dev/sda --script -- mkpart primary ntfs 1MB ${part_size_mb}MB || { echo "Error al crear la primera partición"; exit 1; }
sleep 2

echo "Creando la segunda partición..."
parted /dev/sda --script -- mkpart primary ntfs ${part_size_mb}MB $((2 * part_size_mb))MB || { echo "Error al crear la segunda partición"; exit 1; }
sleep 2

# Informar al kernel de los cambios en la tabla de particiones
echo "Informando al kernel sobre los cambios de partición..."
partprobe /dev/sda
sleep 5
partprobe /dev/sda
sleep 5
partprobe /dev/sda
sleep 5

# Verificar si las particiones están disponibles
echo "Verificando la disponibilidad de las particiones..."
while ! ls /dev/sda1; do
  echo "Esperando a que /dev/sda1 esté disponible..."
  sleep 2
done

while ! ls /dev/sda2; do
  echo "Esperando a que /dev/sda2 esté disponible..."
  sleep 2
done

# Formatear particiones
echo "Formateando la primera partición como NTFS..."
mkfs.ntfs -f /dev/sda1 || { echo "Error al formatear /dev/sda1"; exit 1; }
sleep 2

echo "Formateando la segunda partición como NTFS..."
mkfs.ntfs -f /dev/sda2 || { echo "Error al formatear /dev/sda2"; exit 1; }
sleep 2

echo "Particiones NTFS creadas con éxito"
sleep 2

# Modificar tabla de particiones con gdisk
echo "Modificando la tabla de particiones con gdisk..."
echo -e "r\ng\np\nw\nY\n" | gdisk /dev/sda || { echo "Error al modificar la tabla de particiones"; exit 1; }
sleep 2

# Montar la primera partición
echo "Montando la partición /dev/sda1 en /mnt..."
mount /dev/sda1 /mnt || { echo "Error al montar /dev/sda1"; exit 1; }
sleep 2

# Preparar el directorio para el disco de Windows
echo "Preparando el directorio para el disco de Windows..."
cd ~
mkdir -p windisk || { echo "Error al crear el directorio windisk"; exit 1; }
sleep 2

# Montar la segunda partición
echo "Montando la partición /dev/sda2 en windisk..."
mount /dev/sda2 windisk || { echo "Error al montar /dev/sda2"; exit 1; }
sleep 2

# Instalar GRUB
echo "Instalando GRUB en /mnt..."
grub-install --root-directory=/mnt /dev/sda || { echo "Error al instalar GRUB"; exit 1; }
sleep 2

# Editar la configuración de GRUB
echo "Editando la configuración de GRUB..."
cd /mnt/boot/grub || { echo "Error al cambiar al directorio /mnt/boot/grub"; exit 1; }
cat <<EOF > grub.cfg
menuentry "windows installer" {
	insmod ntfs
	search --set=root --file=/bootmgr
	ntldr /bootmgr
	boot
}
EOF
sleep 2

# Preparar archivos de Windows
echo "Preparando archivos de Windows..."
cd /root/windisk || { echo "Error al cambiar al directorio /root/windisk"; exit 1; }
mkdir -p winfile || { echo "Error al crear el directorio winfile"; exit 1; }
sleep 2

# Descargar la ISO de Windows 10
echo "Descargando la ISO de Windows 10..."
wget -O win10.iso --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, como Gecko) Chrome/91.0.4472.124 Safari/537.36" https://bit.ly/3zOJiyE || { echo "Error al descargar la ISO de Windows 10"; exit 1; }
sleep 2

# Montar la ISO de Windows 10
echo "Montando la ISO de Windows 10..."
mount -o loop win10.iso winfile || { echo "Error al montar win10.iso"; exit 1; }
sleep 2

# Copiar archivos de la ISO a /mnt
echo "Copiando archivos de la ISO de Windows 10 a /mnt..."
rsync -avz --progress winfile/* /mnt || { echo "Error al copiar archivos de la ISO"; exit 1; }
sleep 2

# Desmontar la ISO de Windows
echo "Desmontando winfile..."
umount winfile || { echo "Error al desmontar winfile"; exit 1; }
sleep 2

# Descargar virtio.iso
echo "Descargando virtio.iso..."
wget -O virtio.iso https://shorturl.at/lsOU3 || { echo "Error al descargar virtio.iso"; exit 1; }
sleep 2

# Montar virtio.iso
echo "Montando virtio.iso..."
mount -o loop virtio.iso winfile || { echo "Error al montar virtio.iso"; exit 1; }
sleep 2

# Crear directorio /mnt/sources/virtio
echo "Creando directorio /mnt/sources/virtio..."
mkdir -p /mnt/sources/virtio || { echo "Error al crear el directorio /mnt/sources/virtio"; exit 1; }
sleep 2

# Copiar archivos de virtio.iso
echo "Copiando archivos de virtio.iso a /mnt/sources/virtio..."
rsync -avz --progress winfile/* /mnt/sources/virtio || { echo "Error al copiar archivos de virtio.iso"; exit 1; }
sleep 2

# Cambiar a directorio /mnt/sources
echo "Cambiando al directorio /mnt/sources..."
cd /mnt/sources || { echo "Error al cambiar al directorio /mnt/sources"; exit 1; }
sleep 2

# Crear y modificar archivo cmd.txt
echo "Creando archivo cmd.txt..."
touch cmd.txt || { echo "Error al crear cmd.txt"; exit 1; }
sleep 2

echo "Añadiendo contenido a cmd.txt..."
echo 'add virtio /virtio_drivers' >> cmd.txt
sleep 2

# Actualizar boot.wim
echo "Actualizando boot.wim con wimlib-imagex..."
wimlib-imagex update boot.wim 2 < cmd.txt || { echo "Error al actualizar boot.wim"; exit 1; }
sleep 2

# Reiniciar sistema
echo "Reiniciando el sistema..."
reboot
