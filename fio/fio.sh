#!/bin/sh
pgm="${0##*/}"          # Program basename
progdir="${0%/*}"       # Program directory

export PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin"

# generic mandatory tools/script
TR_CMD=$( which tr )
if [ -z "${TR_CMD}" ]; then
	echo "no such command: tr"
	exit 1
fi

MAIN_CMD="
mkdir
fio
rm
"

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

MYTEST="${progdir}/randread-1-2.fio"
[ -d ${progdir}/tests ] && ${RM_CMD} -rf ${progdir}/tests
${MKDIR_CMD} -p ${progdir}/tests/4k

[ -d /tmp/test ] && ${RM_CMD} -rf /tmp/test
${MKDIR_CMD} /tmp/test

if [ ! -r ${MYTEST} ]; then
	echo "no such test conf: ${MYTEST}"
	exit 01
fi

${FIO_CMD} --output-format=json --output=${progdir}/tests/4k/randread-1-2.json ${progdir}/randread-1-2.fio
#${FIO_CMD} ${progdir}/randread-1-2.fio
