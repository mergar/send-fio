BRAND=spacevm
PREFIX?=/usr/local
SHARE_DIR?=share
SCRIPT_SHARE_DIR?=${BRAND}
BINDIR?=bin
CC?=cc
OSTYPE?= uname -s
STRIP=strip
RM="rm"
RMDIR=rmdir
CP="cp"
INSTALL=install
MKDIR=mkdir
CFLAGS?= -static -O2

all: bin

clean:
	$(RM) -f bin/${BRAND}-select-item

install: bin install_share install_etc
	${MKDIR} -p $(PREFIX)/$(BINDIR)
	${INSTALL} -m 0755 bin/${BRAND}-select-item $(PREFIX)/$(BINDIR)
	${INSTALL} -m 0755 bin/${BRAND}-perf-fio-fioloop $(PREFIX)/$(BINDIR)
	${INSTALL} -m 0755 bin/${BRAND}-perf-fio-run $(PREFIX)/$(BINDIR)
	${INSTALL} -m 0755 bin/${BRAND}-perf-fio-send $(PREFIX)/$(BINDIR)

deinstall:
	${MKDIR} -p $(PREFIX)$(BINDIR)
	${RM} -f \
		${PREFIX}/${BINDIR}/${BRAND}-select-item \
		$(PREFIX)/$(BINDIR)/${BRAND}-perf-fio-fioloop \
		$(PREFIX)/$(BINDIR)/${BRAND}-perf-fio-run \
		$(PREFIX)/$(BINDIR)/${BRAND}-perf-fio-send
	${RM} -rf \
		${PREFIX}/${SHARE_DIR}/${SCRIPT_SHARE_DIR}/fio \
		${PREFIX}/${SHARE_DIR}/${SCRIPT_SHARE_DIR}/fio-scripts \
		${PREFIX}/${SHARE_DIR}/${SCRIPT_SHARE_DIR}/fio-subr
	@${RMDIR} ${PREFIX}/${SHARE_DIR}/${SCRIPT_SHARE_DIR} || true
	${RM} -f ${PREFIX}/etc/send-fio/*.conf.sample
	@${RMDIR} -f ${PREFIX}/etc/send-fio

${BRAND}-select-item:
	${CC} -o bin/${BRAND}-select-item $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) $(LIBS) src/${BRAND}-select-item.c

bin: ${BRAND}-select-item
	${STRIP} bin/${BRAND}-select-item

install_etc:
	${INSTALL} -d ${PREFIX}/etc
	${CP} -a etc/send-fio ${PREFIX}/etc/

install_share:
	${INSTALL} -d ${PREFIX}/${SHARE_DIR}
	${INSTALL} -d ${PREFIX}/${SHARE_DIR}/${SCRIPT_SHARE_DIR}
	${CP} -a share/fio ${PREFIX}/${SHARE_DIR}/${SCRIPT_SHARE_DIR}
	${CP} -a share/fio-scripts ${PREFIX}/${SHARE_DIR}/${SCRIPT_SHARE_DIR}
	${CP} -a share/fio-subr ${PREFIX}/${SHARE_DIR}/${SCRIPT_SHARE_DIR}

.PHONY: all clean install deinstall
