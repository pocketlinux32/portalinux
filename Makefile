#!/usr/bin/make

MAKEPATH := $(dir $(abspath $(firstword $(MAKEFILE_LIST))))
CONFIGDIR := $(MAKEPATH)configs
SRC := $(MAKEPATH)src
OUTPUT := $(MAKEPATH)output
BB := $(SRC)/busybox-1.31.1
LINUX := $(SRC)/linux-4.19.83
INIT := $(MAKEPATH)init
MIN_INIT := $(MAKEPATH)minimal-init
KRNOUT := $(OUTPUT)/bzImage
INTRDOUT := $(OUTPUT)/initrfs.cpio.xz

.SILENT:
.PHONY: all clean distclean clean prereq

all: prereq $(KRNOUT) $(INTRDOUT)
	echo "* Todo listo. Sistema instalado en $(MAKEPATH)output."

prereq:
	echo "Instalador de PortaLinux, Version 0.03"
	echo "2020 PocketNES Software, Debajo GPLv3"
	if [ $$(id -u) -ne 0 ]; then \
		echo "* Se necesita elevar privilegios para crear algunos archivos *"; \
		sudo ls; \
		if [ $$? -ne 0 ]; then \
			exit 1; \
		fi; \
	fi
	cd $(MAKEPATH)
	mkdir -p $(OUTPUT) $(SRC)
	echo "* Ok. Iniciando tarea..."

$(KRNOUT): $(MAKEPATH)linux-4.19.83 $(MAKEPATH)minimal-initrfs $(CONFIGDIR)/.linux-config
	echo "* Compilando Linux kernel..."
	cp $(CONFIGDIR)/.linux-config $(LINUX)/.config
	$(MAKE) -C $(LINUX) 2>/dev/null
	mv $(LINUX)/arch/x86/boot/bzImage $(KRNOUT)

$(LINUX):
	echo "* Descargando Kernel Linux..."
	cd $(SRC)
	wget "https://kernel.org/pub/linux/kernel/v4.x/linux-4.19.83.tar.gz" -O "linux-4.19.83.tar.gz"; \
	gzip -d linux-4.19.83.tar.gz
	tar -xf linux-4.19.83.tar
	rm *.tar
	cd $(MAKEPATH)

$(BB):
	echo "* Descargando BusyBox..."
	cd $(SRC)
	wget "https://busybox.net/downloads/busybox-1.33.0.tar.bz2" -O "busybox-1.33.0.tar.bz2"
	bunzip2 busybox-1.33.0.tar.bz2
	tar -xf busybox-1.33.0.tar
	rm *.tar
	cd $(MAKEPATH)

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
		mkdir -p $(MAKEPATH)minimal-initrfs/$$i; \
	done
	echo "	dev/console"
	sudo mknod -m 644 $(MAKEPATH)initrfs/dev/console c 5 1
	echo "	init"
	cp $(MIN_INIT) $(MAKEPATH)minimal-initrfs/init
	echo "	bin/busybox"
	cp $(BB)/minimal-busybox $(MAKEPATH)minimal-initrfs/bin/busybox

$(BB)/busybox: $(CONFIGDIR)/.busybox-config $(BB)
	echo "* Compilando BusyBox..."
	cp $< $(BB)
	mv $(BB)/.busybox-config $(BB)/.config
	$(MAKE) -C $(BB) 2>/dev/null

$(BB)/minimal-busybox: $(CONFIGDIR)/.minimal-busybox-config $(BB)
	echo "* Compilando BusyBox (min)..."
	cp $< $(BB)
	mv $(BB)/.minimal-busybox-config $(BB)/.config
	$(MAKE) -C $(BB)
	mv $(BB)/busybox $(BB)/minimal-busybox
	$(MAKE) -C $(BB) clean

distclean:
	$(MAKE) -C $(BB) distclean
	rm -rf $(LINUX)
	rm -rf $(BB)
	rm -rf $(MAKEPATH)minimal-initrfs
	rm -rf $(MAKEPATH)initrfs

clean:
	$(MAKE) -C $(BB) clean
	$(MAKE) -C $(LINUX) clean
