SRCS = $(wildcard *.c)
OBJS = $(SRCS:.c=.o)
ARCH = $(shell cc -dumpmachine | cut -d- -f1)

ifeq ($(ARCH),arm)
CC = cc
else
CC = arm-linux-gnueabihf-gcc
endif


%.o : %.c
	$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@

all: rs485

rs485: $(OBJS)
	$(CC) -o $@ $(OBJS)

clean:
	rm -f rs485 *.o
