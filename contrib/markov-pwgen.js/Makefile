NAME = $(shell jq .name package.json)

ifneq ($(NVM_BIN),)
BINDIR = $(NVM_BIN)
else
BINDIR = /usr/bin
endif

LIBDIR = $(subst /bin,/lib,$(BINDIR))

all: index.js dictionary.js
	@npm install

dictionary.js: $(DICT)
	./filter-dictionary.rb $(DICT)

install: all
	@npm install -g

uninstall:
	rm -f $(BINDIR)/$(NAME)
	rm -rf $(LIBDIR)/node_modules/$(NAME)

clean:
	rm -rf node_modules dictionary.js *~
