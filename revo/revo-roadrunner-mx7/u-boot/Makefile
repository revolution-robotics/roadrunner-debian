# Makefile: Generate U-Boot script image
#
DESTDIR ?= ../../../output

.SUFFIXES: .sh .scr

.sh.scr:
	mkimage -T script -C none -n '$(basename $@) script' -d $< $@

SRCS = $(wildcard *.sh)
OBJS = $(SRCS:.sh=.scr)

.PHONY: all clean

all: $(OBJS)

install: $(OBJS)
	install -m 0644 $(OBJS) $(DESTDIR)

deploy:
	-sudo mdel c:boot.scr >/dev/null 2>&1
	sudo mcopy -n $(OBJS) c:
	sync

clean:
	rm -f $(OBJS)
