#!/usr/bin/make

MPATH := $(dir $(abspath $(firstword $(MAKEFILE_LIST))))
PKGS := glibc-2.32 ncurses-6.2 nano-5.4

.PHONY: all clean

all: $(MPATH)output/bzImage $(MPATH)output/initramfs.cpio.xz $(MPATH)output/rootfs.sb

$(MPATH)mk-init:
	mkdir $(MPATH)output
	touch $(MPATH)mk-init

$(MPATH)components/bb: $(MPATH)mk-init
	make=$(MAKE) mpath=$(MPATH) $(MPATH)components/make-routines compile-bb

$(MPATH)minimal-initrfs: $(MPATH)components/bb
	make=$(MAKE) mpath=$(MPATH) $(MPATH)components/make-routines create-minimal-initrfs

$(MPATH)output/bzImage: $(MPATH)minimal-initrfs
	make=$(MAKE) mpath=$(MPATH) $(MPATH)components/make-routines compile-linux

$(MPATH)output/initramfs.cpio.xz: $(MPATH)components/bb
	cd $(MPATH)output; \
	sudo $(MPATH)components/mkinitrd --busybox $(MPATH)components/bb --init $(MPATH)components/init --compression xz

$(MPATH)output/rootfs.sb: $(MPATH)components/bb
	make=$(MAKE) mpath=$(MPATH) $(MPATH)components/make-routines compile-pkgs $(PKGS); \
	make=$(MAKE) mpath=$(MPATH) $(MPATH)components/make-routines create-rootfs $(PKGS)

clean:
	rm -rf $(MPATH)src/linux* $(MPATH)output $(MPATH)minimal-initrfs $(MPATH)rootfs.sb $(MPATH)mk-init $(MPATH)components/*bb
	for i in $(PKGS); do \
		rm -rf $(MPATH)src/$$i/build; \
	done
