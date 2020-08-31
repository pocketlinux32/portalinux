#!/bin/sh

#PortaLinux script de Instalacion, v0.01
#2020 PocketNES Software, Debajo GPLv3

PL_PATH="$(pwd)"

compile(){
	echo "Compilando $1..."
	cd "$PL_PATH/$1"
	if [ "$3" = "--with-configure-flags" ]; then
		mkdir build && cd build
		../configure $4
	elif [ ! -f "$PL_PATH/configs/$1/.config" ]; then
		echo "No se encontro el archivo. Provando predeterminado"
		make defconfig
	else
		cp "$PL_PATH/configs/$1/.config" .
	fi
	make
}

create_initrd(){
	echo "Creating Initramfs..."
	if [ ! -f "$PL_PATH/initramfs/init" ]; then
		for files in bin sbin usr/bin usr/sbin lib etc root opt tmp; do
			mkdir -p "$PL_PATH/initramfs/$files"
		done
	else
		echo "Esto ya existe, saltando..."
		return
	fi
	mv "$PL_PATH/busybox-1.31.1/busybox" "$PL_PATH/initramfs/bin"
	if [ $(id -u) -ne 0 ]; then
		echo "Necesitas ser root para crear un initramfs. Saliendo..."
		exit 1
	else
		chroot "$PL_PATH/initramfs" "/bin/busybox --install -s"
		echo "#!/bin/busybox sh" > "$PL_PATH/initramfs/init"
		mknod -m 644 tty c 5 0
		mknod -m 640 console c 5 1
Â		mknod -m 664 null c 1 3
	fi
	cat "$PL_PATH/init" >> "$PL_PATH/initramfs/init"
	chmod 777 "$PL_PATH/initramfs/init"
}

echo "PortaLinux, script de Instalacion"
echo "Version v0.01, 2020 PocketNES Software, Debajo GPLv3"
echo "$PL_PATH"
if [ -d "$PL_PATH/output" ]; then
	rm -rf "$PL_PATH/output"
fi
compile busybox-1.31.1
create_initrd
compile linux-4.19.83
printf "Done. Installing..."
mkdir "$PL_PATH/output"
cp "$PL_PATH/linux-4.19.83/arch/x86/boot/bzImage" "$PL_PATH/output"
printf "Done.\n"
cd "$PL_PATH/linux-4.19.83" && make distclean
cd "$PL_PATH/busybox-1.31.1" && rm distclean

