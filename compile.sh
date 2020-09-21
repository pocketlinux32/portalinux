#!/bin/sh

#PortaLinux script de Instalacion, v0.02
#2020 PocketNES Software, Debajo GPLv3

compile(){
	echo "Compilando $1..."
	cd "$1"
	if [ "$2" = "--with-configure-flags" ]; then
		mkdir build && cd build
		../configure $3
	elif [ ! -f "../configs/$1/.config" ]; then
		echo "No se encontro el archivo. Provando predeterminado"
		make defconfig
	else
		cp "../configs/$1/.config" .
	fi
	make
	cd ..
}

create_initrd(){
	echo "Creating Initramfs..."
	if [ ! -f initramfs/init ]; then
		for files in bin sbin usr/bin usr/sbin lib etc root opt tmp dev proc sys; do
			mkdir -p initramfs/$files
		done
	else
		echo "Esto ya existe, saltando..."
		return
	fi
	mv busybox-1.31.1/busybox initramfs/bin
	if [ $(id -u) -ne 0 ]; then
		echo "Necesitas ser root para crear un initramfs. Saliendo..."
		exit 1
	else
		mknod -m 644 initramfs/dev/tty c 5 0
		mknod -m 640 initramfs/dev/console c 5 1
		mknod -m 664 initramfs/dev/null c 1 3
	fi
	cp init initramfs
	chmod 777 initramfs/init
}

echo "PortaLinux, script de Instalacion"
echo "Version v0.02, 2020 PocketNES Software, Debajo GPLv3"
if [ -d output ]; then
	rm -rf output
fi
if [ ! -f busybox-1.31.1/busybox ]; then
	compile busybox-1.31.1
fi
create_initrd
compile linux-4.19.83
printf "Done. Installing..."
mkdir "output"
cp linux-4.19.83/arch/x86/boot/bzImage output
printf "Done.\n"
cd linux-4.19.83 && make distclean
cd ../busybox-1.31.1 && make distclean
