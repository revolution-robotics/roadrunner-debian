SRCS = $(wildcard *.c)
OBJS = $(SRCS:.c=.o)
ARCH = $(shell cc -dumpmachine | cut -d- -f1)

ifeq ($(ARCH),arm64)
CC = cc
else
CC = aarch64-linux-gnu-gcc
endif

%.o : %.c
	$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@

all: brcm_patchram_plus

brcm_patchram_plus: $(OBJS)
	$(CC) $(CFLAGS) $(CPPFLAGS)  $(LDFLAGS) -o $@ $< $(LDLIBS)

clean:
	rm -f brcm_patchram_plus *.o

.PHONY:	all install clean
