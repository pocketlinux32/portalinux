#!/usr/bin/make

MPATH := $(dir $(abspath $(firstword $(MAKEFILE_LIST))))

.PHONY: all clean

all: $(MPATH)output/bzImage $(MPATH)output/initramfs $(MPATH)output/rootfs.sb

$(MPATH)mk-init:
	mkdir $(MPATH)output
	touch $(MPATH)mk-init

$(MPATH)components/bb: $(MPATH)mk-init
	make $(MAKE) mpath=$(MPATH) $(MPATH)components/make-routines compile-bb

$(MPATH)minimal-initrfs: $()

$(MPATH)output/bzImage: $(MPATH)mk-init
	make=$(MAKE) mpath=$(MPATH) $(MPATH)components/make-routines compile-linux
