
all:
	./src/make.sh

install:
	docker build -t archlinux . --no-cache

clean:
	chmod -R +w rootfs 2> /dev/null | true
	rm -rf rootfs Dockerfile var

