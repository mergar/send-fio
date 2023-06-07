#!/bin/sh
pgm="${0##*/}"          # Program basename
progdir="${0%/*}"       # Program directory

# options
#
export PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin"
BENCH_SRV_URL="https://perf.beeru.online"
BENCH_CONF_URL="${BENCH_SRV_URL}/test.conf"

UNAME_CMD=$( which uname )
if [ ! -x "${UNAME_CMD}" ]; then
	echo "error: no such command: uname"
	exit 1
fi

TR_CMD=$( which tr )
if [ ! -x "${TR_CMD}" ]; then
	echo "error: no such command: tr"
	exit 1
fi

OS=$( ${UNAME_CMD} -s )

# generic mandatory tools/script
MAIN_CMD="
cat
grep
head
mkdir
fio
tail
tee
sysctl
awk
sed
cut
chmod
wc
mv
rm
curl
jq
openssl
whoami
"

case "${OS}" in
	Linux)
		# Linux require -i'', not -i ' '
		sed_delimer=
		;;
	FreeBSD)
		sed_delimer=" "
		;;
esac

for i in ${MAIN_CMD}; do
	mycmd=
	mycmd=$( which ${i} )
	if [ ! -x "${mycmd}" ]; then
		echo "${pgm} error: no such executable dependency/requirement: ${i}"
		exit 1
	fi
	MY_CMD=$( echo ${i} | ${TR_CMD} '\-[:lower:]' '_[:upper:]' )
	MY_CMD="${MY_CMD}_CMD"
	eval "${MY_CMD}=\"${mycmd}\""
done

MY_USER=$( ${WHOAMI_CMD} )
if [ "${MY_USER}" != "root" ]; then
	echo "${pgm} error: needs root privileges, my user: ${MY_USER}"
	exit 1
fi

## FIO_ MACROS/PARAMS
FIO_PARAMS="
DIRECTORY
RUNTIME
BS
IOENGINE
SYNC
DIRECT
NUMJOBS
SIZE
IODEPTH
"

${CURL_CMD} -s -o /tmp/test.conf ${BENCH_CONF_URL} 2>&1 | ${TEE_CMD} -a /tmp/curl.$$
ret=$?

trap "${RM_CMD} -f /tmp/curl.$$" HUP INT ABRT BUS TERM EXIT

if [ ${ret} -ne 0 ]; then
	echo "curl error: ${ret}"
	${CAT_CMD} /tmp/curl.$$
	exit 1
fi

unset TYPE PROFILE
. /tmp/test.conf

if [ -z "${TYPE}" ]; then
	echo "no such benchmark TYPE specified: ${BENCH_CONF_URL}"
	exit 1
fi
if [ -z "${PROFILE}" ]; then
	echo "no such benchmark PROFILE specified: ${BENCH_CONF_URL}"
	exit 1
fi

BENCH_CONFIG="${BENCH_SRV_URL}/${TYPE}/${PROFILE}"

${CURL_CMD} -s -o /tmp/profile.conf.tpl ${BENCH_CONFIG} 2>&1 | ${TEE_CMD} -a /tmp/curl.$$
ret=$?
if [ ${ret} -ne 0 ]; then
	echo "curl error: ${ret}"
	${CAT_CMD} /tmp/curl.$$
	exit 1
fi

TYPE_UPPER=$( echo "${TYPE}" | ${TR_CMD} '[:lower:]' '[:upper:]' )

eval MY_PARAMS="\$${TYPE_UPPER}_PARAMS"

if [ -n "${MY_PARAMS}" ]; then
	for i in ${MY_PARAMS}; do
		eval VAL="\$${TYPE_UPPER}_${i}"
#		echo "X $VAL"
		[ -z "${VAL}" ] && continue
#		sed -i'' "s#%%i%%#${VAL}#g" /tmp/profile.conf.tpl
		${SED_CMD} -i${sed_delimer}'' -Ees:"%%${i}%%":"${VAL}":g /tmp/profile.conf.tpl
	done
fi

${MV_CMD} /tmp/profile.conf.tpl /tmp/profile.fio

#MYTEST="${progdir}/randread-1-2.fio"
[ -d ${progdir}/fio/tests ] && ${RM_CMD} -rf ${progdir}/fio/tests
${MKDIR_CMD} -p ${progdir}/fio/tests/4k

if [ -n "${FIO_DIRECTORY}" -a "${FIO_DIRECTORY}" != "/" ]; then
	[ -d ${FIO_DIRECTORY} ] && ${RM_CMD} -rf /tmp/test
fi
${MKDIR_CMD} ${FIO_DIRECTORY}

echo "${FIO_CMD} --output-format=json --output=${progdir}/fio/tests/4k/randread-1-2.json /tmp/profile.fio"
${FIO_CMD} --output-format=json --output=${progdir}/fio/tests/4k/randread-1-2.json /tmp/profile.fio
_ret=$?

exit ${_ret}
