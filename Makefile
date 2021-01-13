#!/usr/bin/make

MAKEPATH := $(dir $(abspath $(firstword $(MAKEFILE_LIST))))
CONFIGDIR := $(MAKEPATH)configs
SRC := $(MAKEPATH)src
OUTPUT := $(MAKEPATH)output
SQFS_ROOT := $(MAKEPATH)rootfs.sb
BB := $(SRC)/busybox-1.33.0
LINUX := $(SRC)/linux-4.19.83
PKGS_SRC := $(SRC)/glibc-2.32 $(SRC)/ncurses-6.2 $(SRC)/nano-5.4
INIT := $(MAKEPATH)init
MIN_INIT := $(MAKEPATH)minimal-init
COMP_BB := $(MAKEPATH)bb
KRNOUT := $(OUTPUT)/bzImage
INTRDOUT := $(OUTPUT)/initrfs.cpio.xz
SQFSOUT := $(OUTPUT)/rootfs.sb

.SILENT:
.PHONY: all clean distclean prereq minimum

all: prereq $(KRNOUT) $(INTRDOUT) $(SQFSOUT)
	echo "* Todo listo. Sistema instalado en $(OUTPUT)"

minimum: prereq $(KRNOUT) $(INTRDOUT)
	echo "* Todo listo. Sistema instalado en $(OUTPUT)"

prereq:
	echo "Compilador de PortaLinux, Version 0.04"
	echo "2020 PocketNES Software, Debajo GPLv3"
	if [ $$(id -u) -ne 0 ]; then \
		echo "* Se necesita elevar privilegios para crear algunos archivos *"; \
		sudo ls; \
		if [ $$? -ne 0 ]; then \
			exit 1; \
		fi; \
	fi
	cd $(MAKEPATH); \
	mkdir -p $(OUTPUT) $(SRC) $(COMP_BB)
	echo "* Ok. Iniciando tarea..."

$(KRNOUT): $(CONFIGDIR)/.linux-config $(LINUX) $(MAKEPATH)minimal-initrfs
	echo "* Compilando Linux kernel..."
	cp $< $(LINUX)/.config
	$(MAKE) -C $(LINUX) 2>/dev/null
	mv $(LINUX)/arch/x86/boot/bzImage $(KRNOUT)

$(LINUX):
	echo "* Descargando Kernel Linux..."
	cd $(SRC); \
	wget "https://kernel.org/pub/linux/kernel/v4.x/linux-4.19.83.tar.gz" -O "linux-4.19.83.tar.gz"; \
	gzip -d linux-4.19.83.tar.gz; \
	tar -xf linux-4.19.83.tar; \
	rm *.tar; \

$(INTRDOUT): $(INIT) #$(COMP_BB)/static-busybox
	echo "* Creando initrfs/"
#	mkdir -p $(MAKEPATH)initrfs
#	for i in bin dev proc sys sbin usr/bin usr/sbin; do \
#		echo "	$$i"; \
#		mkdir -p $(MAKEPATH)initrfs/$$i; \
#	done
#	echo "	dev/console"
#	sudo mknod -m 644 initrfs/dev/console c 5 1
#	echo "	dev/tty"
#	sudo mknod -m 644 initrfs/dev/tty c 5 0
#	echo "	dev/null"
#	sudo mknod -m 664 initrfs/dev/null c 1 3
#	echo "	init"
#	cp $(INIT) $(MAKEPATH)initrfs
#	echo "	bin/busybox"
#	cp $(COMP_BB)/static-busybox $(MAKEPATH)initrfs/bin/busybox
	cd $(MAKEPATH)initrfs; \
	find . | cpio -o --format=newc | xz --check=crc32 - > $(INTRDOUT)

$(MAKEPATH)minimal-initrfs: $(MIN_INIT) $(COMP_BB)/minimal-busybox
	echo "* Creando minimal-initrfs/"
	for i in bin dev proc sys sbin; do \
		echo "	$$i"; \
		mkdir -p minimal-initrfs/$$i; \
	done
	echo "	dev/console"
	sudo mknod -m 644 minimal-initrfs/dev/console c 5 1
	echo "	init"
	cp $(MIN_INIT) minimal-initrfs/init
	echo "	bin/busybox"
	cp $(COMP_BB)/minimal-busybox $(MAKEPATH)minimal-initrfs/bin/busybox

$(COMP_BB)/static-busybox: $(CONFIGDIR)/.static-busybox-config $(BB)
	echo "* Compilando BusyBox (static)..."
	cp $< $(BB)/.config
	$(MAKE) -C $(BB)
	mv $(BB)/busybox $(COMP_BB)/static-busybox
	$(MAKE) -C $(BB) clean

$(COMP_BB)/minimal-busybox: $(CONFIGDIR)/.minimal-busybox-config $(BB)
	echo "* Compilando BusyBox (min)..."
	cp $< $(BB)/.config
	$(MAKE) -C $(BB)
	mv $(BB)/busybox $(COMP_BB)/minimal-busybox
	$(MAKE) -C $(BB) clean

$(SQFSOUT): $(SQFS_ROOT)
	mksquashfs $(SQFS_ROOT) $(SQFSOUT) -comp xz -b 1024K -always-use-fragments

$(SQFS_ROOT)/bin/busybox: $(PKGS_SRC) $(BB)/busybox
	echo "Creando estructura de rootfs.sb..."
	for dirs in bin dev sbin proc sys opt/initramfs usr/bin usr/sbin usr/lib; do \
		echo "	$$dirs"; \
		mkdir -p $(SQFS_ROOT)/$$dirs; \
	done
	for pkg in $(PKGS_SRC); do \
		mkdir $$pkg/build; \
	done
	echo "* Compilando Glibc 2.32..."; \
	cd $(SRC)/glibc-2.32/build; \
	../configure --host=i686-pocket-linux-gnu --target=i686-pocket-linux-gnu --prefix=/usr --disable-multilib --with-sysroot=/; \
	$(MAKE); \
	$(MAKE) install DESTDIR=$(SQFS_ROOT)
	echo "Compilando NcursesW 6.2..."; \
	cd $(SRC)/ncurses-6.2/build; \
	../configure --host=i686-pocket-linux-gnu --prefix=/usr --enable-widec; \
	$(MAKE); \
	$(MAKE) install DESTDIR=$(SQFS_ROOT)
	echo "* Compilando Nano 5.4..."; \
	cd $(SRC)/nano-5.4/build; \
	../configure --host=i686-pocket-linux-gnu --prefix=/usr; \
	$(MAKE); \
	$(MAKE) install DESTDIR=$(SQFS_ROOT)
	echo "* Instaando BusyBox..."; \
	cp $(BB)/busybox $(SQFS_ROOT)/bin; \
	sudo chroot $(SQFS_ROOT) /bin/busybox --install -s

$(BB)/busybox: $(CONFIGDIR)/.busybox-config $(BB)
	echo "* Compilando BusyBox..."
	cp $< $(BB)/.config
	$(MAKE) -C $(BB)

distclean:
	$(MAKE) -C $(BB) distclean
	$(MAKE) -C $(NANO) distclean
	rm -rf $(LINUX)
	rm -rf $(MAKEPATH)minimal-initrfs
	rm -rf $(MAKEPATH)initrfs
#	for i in $(PKGS); do rm -rf $$i/build; done

clean:
	$(MAKE) -C $(BB) clean
	$(MAKE) -C $(LINUX) clean
	$(MAKE) -c $(NANO) clean
