SUBDIRS := $(wildcard */.)

.PHONY: all upgrade $(SUBDIRS)

all: $(SUBDIRS)

upgrade: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@
