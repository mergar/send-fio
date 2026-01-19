all: deb

fetch:
	wget https://space-utils.tar.xz

deb:
	mkdir -p root/usr/local/bin root/usr/local/share/myb root/usr/local/etc
	cc -o root/usr/local/bin/myb-select-item ../../src/myb-select-item.c
	strip root/usr/local/bin/myb-select-item
	cc -o root/usr/local/bin/myb-direct-supported ../../src/direct-supported.c
	strip root/usr/local/bin/myb-direct-supported
	cp -a ../../bin/* root/usr/local/bin/
	cp -a ../../share/fio root/usr/local/share/myb/
	cp -a ../../share/fio-scripts root/usr/local/share/myb/
	cp -a ../../share/fio-subr root/usr/local/share/myb/
	cp -a ../../etc/send-fio root/usr/local/etc/
	dpkg-deb -b root .

clean:
	@rm -rf root/usr *.deb

.PHONY: deb
