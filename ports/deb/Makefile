all: deb

fetch:
	wget https://space-utils.tar.xz

deb:
	mkdir -p root/usr/local/bin root/usr/local/share/spacevm root/usr/local/etc
	cc -o root/usr/local/bin/spacevm-select-item ../../src/spacevm-select-item.c
	strip root/usr/local/bin/spacevm-select-item
	cc -o root/usr/local/bin/spacevm-direct-supported ../../src/direct-supported.c
	strip root/usr/local/bin/spacevm-direct-supported
	cp -a ../../bin/* root/usr/local/bin/
	cp -a ../../share/fio root/usr/local/share/spacevm/
	cp -a ../../share/fio-scripts root/usr/local/share/spacevm/
	cp -a ../../share/fio-subr root/usr/local/share/spacevm/
	cp -a ../../etc/send-fio root/usr/local/etc/
	dpkg-deb -b root .

clean:
	@rm -rf root/usr *.deb

.PHONY: deb
