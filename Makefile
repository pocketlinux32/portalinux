#!/usr/bin/make

MAKEPATH := $(dir $(abspath $(firstword $(MAKEFILE_LIST))))
CONFIGDIR := $(MAKEPATH)configs
BB := $(MAKEPATH)busybox-1.31.1
LINUX := $(MAKEPATH)linux-4.19.83
INIT := $(MAKEPATH)init
MIN_INIT := $(MAKEPATH)minimal-init
OUTPUT := $(MAKEPATH)/output
KRNOUT := $(OUTPUT)/bzImage
INTRDOUT := $(OUTPUT)/initrfs.cpio.xz

.SILENT:
.PHONY: all clean distclean clean prereq

all: prereq $(KRNOUT) $(INTRDOUT)
	echo "* Todo listo. Sistema instalado en $(MAKEPATH)output."

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
	mkdir -o $(MAKEPATH)output
	echo "* Ok. Iniciando tarea..."

$(KRNOUT): $(MAKEPATH)minimal-initrfs $(CONFIGDIR)/.linux-config
	echo "* Compilando Linux kernel..."
	cp $(CONFIGDIR)/.linux-config $(LINUX)
	$(MAKE) -C $(LINUX) 2>/dev/null
	mv $(LINUX)/arch/x86/boot/bzImage $(OUTPUT)

$(INTRDOUT): $(INIT) $(BB)/busybox
	echo "* Creando initrfs/"
	mkdir -p $(MAKEPATH)initrfs
	for i in bin dev proc sys sbin usr/bin usr/sbin; do \
		echo "	$$i"; \
		mkdir -p $(MAKEPATH)initrfs/$$i; \
	done
	echo "	dev/console"
	sudo mknod -m 644 $(MAKEPATH)initrfs/dev/console c 5 1
	echo "	dev/tty"
	sudo mknod -m 644 $(MAKEPATH)initrfs/dev/tty c 5 0
	echo "	dev/null"
	sudo mknod -m 664 $(MAKEPATH)initrfs/dev/null c 1 3
	echo "	init"
	cp $(INIT) $(MAKEPATH)initrfs
	echo "	bin/busybox"
	cp $(BB)/busybox $(MAKEPATH)initrfs
	cd $(MAKEPATH)initrfs
	find . | cpio -o --format=newc | xz --check=crc32 - > $(INTRDOUT)

$(MAKEPATH)minimal-initrfs: $(MIN_INIT) $(BB)/minimal-busybox
	echo "* Creando minimal-initrfs/"
	for i in bin dev proc sys sbin; do \
		echo "	$$i"; \
	fi
	echo "	init"
	cp $(MIN_INIT) $(MAKEPATH)minimal-initrfs/init
	echo "	bin/busybox"
	cp $(BB)/minimal-busybox $(MAKEPATH)minimal-initrfs/bin/busybox

$(BB)/busybox: $(CONFIGDIR)/.busybox-config
	echo "* Compilando BusyBox..."
	cp $< $(BB)
	$(MAKE) -C $(BB) 2>/dev/null

$(BB)/minimal-busybox: $(CONFIGDIR)/.minimal-busybox-config
	echo "* Compilando BusyBox (min)..."
	cp $< $(BB)
	$(MAKE) -C $(BB) 2>/dev/null
	$(MAKE) -C $(BB) clean
