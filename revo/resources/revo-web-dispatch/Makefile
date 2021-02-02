all: revo-web-dispatch compress

revo-web-dispatch: revo-web-dispatch.go
	go build -ldflags="-s -w" revo-web-dispatch.go
	rm -f .compress

compress:
	upx --brute revo-web-dispatch
	touch .compress

clean:
	rm -f .compress revo-web-dispatch
