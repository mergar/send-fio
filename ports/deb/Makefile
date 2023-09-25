all: deb

fetch:
	wget https://space-utils.tar.xz

deb:
	mkdir -p root/usr/local/bin root/usr/local/share/spacevm root/etc
	cc -o root/usr/local/bin/spacevm-select-item ../../src/spacevm-select-item.c
	strip root/usr/local/bin/spacevm-select-item
	cp -a ../../bin/* root/usr/local/bin/
	cp -a ../../share/fio-scripts root/usr/local/share/spacevm/
	cp -a ../../share/fio-subr root/usr/local/share/spacevm/
	cp -a ../../etc/spacevm-perf-fio.conf root/etc/spacevm-perf-fio.conf.sample
	#dpkg-deb -b root .

clean:
	@rm -rf root/etc root/usr

.PHONY: deb
