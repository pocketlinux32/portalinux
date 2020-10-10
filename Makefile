#!/usr/bin/make

MAKEPATH := $(dir $(abspath $(firstword $(MAKEFILE_LIST))))
CONFIGS := $(MAKEPATH)configs
DIRS = busybox-1.31.1 linux-4.19.83
USER := $$USER

.SILENT:
.PHONY: all clean distclean clean prereq

all: prereq $(MAKEPATH)output/initrfs.cpio.xz $(MAKEPATH)output/bzImage
	echo "* Todo listo. Instalando..."
	mkdir -p $(MAKEPATH)output
	cp $(MAKEPATH)linux-4.19.83/arch/x86/boot/bzImage $(MAKEPATH)output
	mv $(MAKEPATH)initrfs.cpio.xz $(MAKEPATH)output

prereq:
	echo "Instalador de PortaLinux, Version 0.03"
	echo "(gpl)2020 PocketNES Software, Debajo GPLv3"
	if [ $$(id -u) -ne 0 ]; then \
		echo "* Se necesita elevar privilegios para crear algunos archivos *"; \
		sudo ls; \
		if [ $$? -ne 0 ]; then \
			exit 1; \
		fi; \
	fi
	echo "* Ok. Iniciando compilacion..."

$(MAKEPATH)busybox-1.31.1/busybox: $(CONFIGS)/$(firstword $(DIRS))/.config
	echo "* Compilando busybox-1.31.1..."
	cp $(MAKEPATH)configs/busybox-1.31.1/.config $(MAKEPATH)busybox-1.31.1
	$(MAKE) -C $(MAKEPATH)/busybox-1.31.1

$(MAKEPATH)initramfs/init: $(MAKEPATH)busybox-1.31.1/busybox $(MAKEPATH)init
	echo "* Creando initramfs/"
	for i in bin sbin usr/bin usr/sbin etc dev proc sys; do \
		echo "	$$i"; \
		mkdir -p $(MAKEPATH)initramfs/$$i; \
	done
	echo "	dev/console"
	sudo mknod -m 644 $(MAKEPATH)initramfs/dev/console c 5 1
	echo "	dev/tty"
	sudo mknod -m 644 $(MAKEPATH)initramfs/dev/tty c 5 0
	echo "	dev/null"
	sudo mknod -m 664 $(MAKEPATH)initramfs/dev/null c 1 3
	echo "	bin/busybox"
	cp $< $(MAKEPATH)initramfs/bin/busybox
	echo "	init"
	cp $(MAKEPATH)init $(MAKEPATH)initramfs

$(MAKEPATH)output/initrfs.cpio.xz: $(MAKEPATH)initramfs/init
	echo "* Creando initrfs.cpio.xz..."
	cd $(dir $^) && find . | cpio -o --format=newc | xz --check=crc32 - > $(MAKEPATH)initrfs.cpio.xz

$(MAKEPATH)output/bzImage: $(CONFIGS)/$(lastword $(DIRS))/.config
	echo "* Compilando linux-4.19.83..."
	cp $(MAKEPATH)configs/linux-4.19.83/.config $(MAKEPATH)linux-4.19.83
	$(MAKE) -C $(MAKEPATH)linux-4.19.83 bzImage

clean: $(DIRS)
	echo "* Borrando archivos..."
	echo "	initramfs/"
	rm -rf $(MAKEPATH)initramfs
	for i in $?; do \
		echo "	$$i/"; \
		$(MAKE) -C $(MAKEPATH)$$i clean; \
	done
	echo "	output/"
	rm -rf $(MAKEPATH)output

distclean: clean
	echo "* Borrando configuraciones..."
	for i in $(DIRS); do \
		echo "	$$i"; \
		$(MAKE) -C $(MAKEPATH)$$i distclean; \
	done
