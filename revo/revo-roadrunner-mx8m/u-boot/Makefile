# Makefile: Generate U-Boot script image
#
DESTDIR ?= ../../../output

.SUFFIXES: .sh .scr

.sh.scr:
	mkimage -A arm -T script -C none -n '$(basename $@) script' -d $< $@

SRCS = $(wildcard *.sh)
OBJS = $(SRCS:.sh=.scr)

.PHONY: all clean

all: $(OBJS)

install: $(OBJS)
	install -m 0644 $(OBJS) $(DESTDIR)

clean:
	rm -f $(OBJS)
