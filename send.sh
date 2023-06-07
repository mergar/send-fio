#!/bin/sh
# Send FIO statistics to perf server
pgm="${0##*/}"		# Program basename
progdir="${0%/*}"	# Program directory

# options
#
export PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin"
CURR_VERSION="0.1"
USE_TOR=NO
DO_LOG_NET_TRAFFIC=1

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

if [ "${USE_TOR}" = "YES" ]; then
	MAIN_CMD="${MAIN_CMD} nc"
fi

case "${OS}" in
	FreeBSD)
		MAIN_CMD="${MAIN_CMD} pciconf"
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

#
# constants
#
CR=$'\r'
NL=$'\n'


#
# global values
#
checkin_server="https://perf.beeru.online"
send_stats_log="/var/log/send-perf-stats-log"
id_token_file='/var/db/send-perf-stats'
checkin_server_description=${checkin_server}
nc_host=${checkin_server}
nc_port=80
http_header_proxy_auth=""
timeout=10

##
## Procedures
##

echo_begin()
{
	echo -n "$1 ... "
}

echo_end_success()
{
	echo "SUCCESS"
}

echo_err()
{
	echo "$1" >&2
}

log()
{
	echo "[`date "+%Y-%m-%d %H:%M:%S %z"`] $1 $2" >> $send_stats_log
}

fail()
{
	# log error
	log "TERM" "$1 (failure)"
	# let user know
	echo_err "Send-stats failed: $1"
	exit 1
}

nlog()
{
	if [ ${DO_LOG_NET_TRAFFIC} -eq 1 ]; then
		echo "--$(date)--" >> /tmp/send-perf-stats.$1.log
		${TEE_CMD} -a /tmp/send-perf-stats.$1.log
	else
		${CAT_CMD}
	fi
}

# do_http_request: if success returns 0, and prints http.body, otherwise returns 1
do_http_request()
{
	local meth="$1"
	local url="$2"
	local body="$3"
	local content_type="$4"
	local do_log="$5"

	local resp
	local lineno
	local in_header
	local result_count

	local _curl_args=

	if [ -n "${HTTP_PROXY}" ]; then
		url="http://${checkin_server}${url}"
	fi

	# --no-progress-meter 
	_curl_args="-s"

	if [ -n "${content_type}" ]; then
		if [ -z "${_curl_args}" ]; then
			_curl_args="-H \"Content-Type: ${content_type}\""
		else
			_curl_args="${_curl_args} -H \"Content-Type: ${content_type}\""
		fi
	fi

	echo "meth[${meth}] url[${url}] body[${body}] content_type[${content_type}] do_log[${do_log}]" >> /tmp/send.log

	case "${meth}" in
		HEAD)
			if [ -z "${_curl_args}" ]; then
				_curl_args="-I"
			else
				_curl_args="${_curl_args} -I"
			fi
			;;
		GET)
			if [ -z "${_curl_args}" ]; then
				_curl_args="-X GET -I"
			else
				_curl_args="${_curl_args} -X GET -I"
			fi
			;;
		POST)
			if [ -z "${_curl_args}" ]; then
				_curl_args="-X POST"
			else
				_curl_args="${_curl_args} -X POST"
			fi
			;;
	esac

	resp=$( echo "${CURL_CMD} ${_curl_args} \"${checkin_server}${url}\"" | nlog "out" | /bin/sh - | nlog "in" 2>/dev/null )
	_ret=$?
	if [ ${_ret} -ne 0 ]; then
		if [ ${do_log} -ne 0 ]; then
			log "FAIL" "Failed to send data to the host ${nc_host}:${nc_port}, is network or host down?"
		fi
		return 1
	fi

	${CURL_CMD} ${_curl_args} ${url}

	local IFS=${CR}
	lineno=0
	in_header=1
	http_result=""

#	echo "RESP: [$resp]" >> /tmp/respo.log

	for str in ${resp}; do
		echo "STR ${lineno}: [${str}]" >> /tmp/str
	if [ ${lineno} -eq 0 ] ; then
		#if expr "${str}" : "^HTTP/1\.[01] 200 OK$" > /dev/null; then
		#echo "${str}" | ${TR_CMD} -d '\r\n' | ${GREP_CMD} -E -q "^HTTP/1\.[01] 200 OK$"
		_ret=$?
		if [ ${_ret} -eq 0 ]; then
			# ok
			date > /tmp/fufff
			http_result="STATUS=OK"
			true
		else
			if [ ${do_log} -ne 0 ]; then
				log "FAIL" "Failed HTTP query: request='${http_req}' -> response='${str}'"
			fi
			return 2
		fi
	elif [ ${lineno} -ge 1 -a ${in_header} -eq 1 ] ; then
		if [ -z "${str}" ]; then
			in_header=0
			result_count=0
		fi
	else
		if [ $result_count -eq 0 ]; then
			http_result="${str}"
		else
			http_result="${http_result}${NL}${str}"
		fi
		result_count=$(($result_count+1))
	fi

	lineno=$(($lineno+1))
	done
	#echo "${http_result}" >> /tmp/result
	echo "${http_result}"

	return 0
}

extract_field()
{
	# charset of the value, besides alnum covers base64 encoding charset (/+), and single quote
	echo "$1" | ${GREP_CMD} "^${2}=" | ${TAIL_CMD} -1 | ${SED_CMD} -E -e "s/^${2}=([a-zA-Z0-9=/+']+).*/\1/g"
}

do_http_request_check_status()
{
	local body
	local status
	local what="$5"

	# run request
	body=$(do_http_request "$1" "$2" "$3" "$4" 1)

	if [ $? -ne 0 ]; then
		fail "HTTP query failed during ${what}"
	fi

	echo "BODY: ${body}" >> /tmp/body.txt

	# check status
	status=$(extract_field "${body}" "STATUS")

	echo "MY STATUS: ${status}" >> /tmp/status.txt

	case "${status}" in
		OK)
			# pass
			true
			;;
		FAIL)
			log "FAIL" "Got STATUS=FAIL from the server in during ${what}"
			fail "${what} request failed"
			;;
		*)
			fail "Server didn't return the status for ${what}"
			;;
	esac
}

uri_escape()
{
	# RFC 2396
	echo "${1+$@}" | ${SED_CMD} -e '
		s/%/%25/g
		s/;/%3b/g
		s,/,%2f,g
		s/?/%3f/g
		s/:/%3a/g
		s/@/%40/g
		s/&/%26/g
		s/=/%3d/g
		s/+/%2b/g
		s/\$/%24/g
		s/,/%2c/g
		s/ /%20/g
	'
}

parse_http_proxy_string() {
# Handle HTTP proxy services
#
# HTTP_PROXY/http_proxy can take the following form:
#    [http://][username:password@]proxy[:port][/]
# Authentication details may also be provided via HTTP_PROXY_AUTH:
#    HTTP_PROXY_AUTH="basic:*:username:password"
#
# IN:   * HTTP_PROXY or http_proxy
# IN:   * HTTP_PROXY_AUTH
# OUT:  * http_header_proxy_auth
# OUT:  * nc_host
# OUT:  * nc_port

  local PROXY_AUTH_USER
  local PROXY_AUTH_PASS
  local PROXY_HOST
  local PROXY_PORT

  if [ -z "$HTTP_PROXY" -a -n "$http_proxy" ]; then
    HTTP_PROXY=$http_proxy
  fi
  if [ -n "$HTTP_PROXY" ]; then
    # Attempt to resolve any HTTP authentication
    if [ -n "$HTTP_PROXY_AUTH" ]; then
      PROXY_AUTH_USER=$(echo $HTTP_PROXY_AUTH | ${SED_CMD} -E 's/^.+:\*:(.+):.+$/\1/g')
      PROXY_AUTH_PASS=$(echo $HTTP_PROXY_AUTH | ${SED_CMD} -E 's/^.+:\*:.+:(.+)$/\1/g')
    else
      # Check for authentication within HTTP_PROXY
      HAS_HTTP_AUTH=$(echo $HTTP_PROXY | ${SED_CMD} -E 's/^(http:\/\/)?((.+:.+)@)?.+/\3/')
      if [ -n "$HAS_HTTP_AUTH" ]; then
        # Found HTTP authentication details
        PROXY_AUTH_USER=$(echo $HAS_HTTP_AUTH | ${CUT_CMD} -d: -f1)
        PROXY_AUTH_PASS=$(echo $HAS_HTTP_AUTH | ${CUT_CMD} -d: -f2)
      fi
    fi

    # Determine the proxy components
    PROXY_HOST=$(echo $HTTP_PROXY | ${SED_CMD} -E 's/^(http:\/\/)?(.+:.+@)?([^@:]+)(:.+)?/\3/')
    PROXY_PORT=$(echo $HTTP_PROXY | ${SED_CMD} -E 's/^(http:\/\/)?(.+:.+@)?(.+):([0-9]+)/\4/' | ${SED_CMD} -e 's/[^0-9]//g')
    if [ -z "$PROXY_PORT" ]; then
      # Use default proxy port
      PROXY_PORT=3128
    fi
  fi

  # Determine the host/port netcat should connect to
  if [ -n "$PROXY_HOST" -a -n "$PROXY_PORT" ]; then
    nc_host=$PROXY_HOST
    nc_port=$PROXY_PORT
    # Proxy authentication, if required
    if [ -n "$PROXY_AUTH_USER" -a -n "$PROXY_AUTH_PASS" ]; then
      local auth_base64=$(echo -n "$PROXY_AUTH_USER:$PROXY_AUTH_PASS" | ${OPENSSL_CMD} base64)
      http_header_proxy_auth="Basic $auth_base64"
    fi
    return 0
  else
    nc_host=$checkin_server
    nc_port=80
    return 1
  fi
}

test_connection()
{
	local _body _ret

	_body=$( do_http_request "HEAD" "/" "" "" 0 )
	_ret=$?
	if [ ${_ret} -ne 0 -a ${_ret} -ne 2 ]; then
		log "FAIL" "Unable to connect to ${checkin_server_description}"
		fail "Network or host is down?"
	fi
}

setup_proxies() {
	# TOR
	if [ "${USE_TOR}" = "YES" ]; then
	if [ -n "${HTTP_PROXY}" -o -n "${http_proxy}" ]; then
		echo_err "Ignoring HTTP_PROXY since TOR is used"
	fi
	NC="${NC_CMD} -x localhost:9050 -X 5"
		checkin_server_description="${checkin_server_description} (through TOR)"
		return 0
	fi

	# HTTP proxy
	if [ -n "${HTTP_PROXY}" -o -n "${http_proxy}" ]; then
		parse_http_proxy_string
		if [ $? -eq 0 ]; then
			checkin_server_description="${checkin_server_description} (through proxy)"
			return 0
		fi
	fi

	# no proxy
	return 0
}

report_devices() {
  case $(${UNAME}) in
    FreeBSD|DragonFly|MidnightBSD)
      local query_string=""
      local line
      while read line
      do
        local DRIVER=$(echo "${line}" | ${AWK_CMD} -F\@ '{print $1}')
        if [ "0`echo "${line}" | ${AWK_CMD} '{print $5}' | ${AWK_CMD} -F= '{print $1}'`" = "0vendor" ]; then
          local VENDOR=$(echo "${line}" | ${AWK_CMD} '{print $5}' | ${CUT_CMD} -c10-15)
          local DEVICE=$(echo "${line}" | ${AWK_CMD} '{print $6}' | ${CUT_CMD} -c10-15)
          local DEV=$(echo "${DEVICE}${VENDOR}")
        else
          local DEV=$(echo "${line}" | ${AWK_CMD} '{print $4}' | ${CUT_CMD} -c8-15)
        fi
        local CLASS=$(echo "${line}" | ${AWK_CMD} '{print $2}' | ${CUT_CMD} -c9-14)
        query_string=$query_string`echo \&dev[]=${DRIVER}:${DEV}:${CLASS}`
      done << EOT
$(${PCICONF_CMD} -l)
EOT
      echo_begin "Posting device statistics to ${checkin_server_description}"
      do_http_request_check_status "GET" "/scripts/report_devices.php?token=${TOKEN}&key=${KEY}$query_string" \
        "" "" "system devices submission"
      echo_end_success
      log "INFO" "System devices reported to ${checkin_server_description}"
      ;;
    *)
      # Not supported
      ;;
  esac
}


get_id_token()
{
	# Mock
	KEY='08464d7eceb9bac977b57a5ec52a7c56'
	TOKEN='uGUZuCugctTqPFany6tEJGppstv2q9O43jAicvTRepo='
	return 

	if [ -f ${id_token_file} ]; then
		if [ $( ${WC_CMD} -l < ${id_token_file} ) -lt 3 ]; then
			${RM_CMD} -f ${id_token_file}
		fi
	fi

	if [ ! -f ${id_token_file} -o ! -s ${id_token_file} ]; then
		# generate the token file
		echo "Send-perf-stats runs on this system for the first time, generating registration ID"
		IDTOKEN=$( uri_escape $(${OPENSSL_CMD} rand -base64 32 ) )
		if [ $? -ne 0 ]; then
			fail "Failed to generate IDTOKEN"
		fi

		# IDTOKEN="ZYpSdqjlBTPykK56AhIU2%2bANUECAyOwHwPCBKRY95Zk%3d"
		#IDTOKEN="ZYpSdqjlBTPykK56AhIU2%2bANUECAyOwHwPCBKRY95Zk%3d"

		# receive KEY/TOKEN
		local body
		body=$( do_http_request "GET" "/scripts/getid.php?key=${IDTOKEN}" "" "" 1 )
		if [ $? -ne 0 ]; then
			fail "HTTP query failed during key/token generation"
		fi

#		echo "GET ${url}/scripts/getid.php?key=${IDTOKEN}" > /tmp/body.txt
#		echo "${body}" >> /tmp/body.txt

#		KEY=$(extract_field "${body}" "KEY")
#		TOKEN=$(extract_field "${body}" "TOKEN")
#		# validate KEY/TOKEN
#		if [ ${#KEY} -lt 10 -o ${#KEY} -gt 64 -o ${#TOKEN} -lt 10 -o ${#TOKEN} -gt 64 ]; then
#			log "FAIL" "Invalid key/token received for IDTOKEN=${TOKEN}"
#			fail "Invalid key/token combination received from the server"
#		fi
#		log "INFO" "Generated idtoken='${IDTOKEN}', received key=${KEY} and token=${TOKEN}"
#		# save KEY/TOKEN
#		(echo "# This file was auto-generated on $(date),"; \
#		echo "# and contains the Send-perf-stats registration credentials"; \
#		echo "KEY=${KEY}"; echo "TOKEN=${TOKEN}"; echo "VERSION=${CURR_VERSION}") > ${id_token_file} && \
#		${CHOWN} root:wheel ${id_token_file} && \
#		${CHMOD_CMD} 600 ${id_token_file}
#		if [ $? -ne 0 ]; then
#			${RM_CMD} -f ${id_token_file}
#			fail "Failed to create identification file ${id_token_file}"
#		fi
#		log "INFO" "Created identification file ${id_token_file}"
	fi

	# read the token file into the global variables
	. ${id_token_file}
	KEY=$( uri_escape ${KEY} )
	TOKEN=$( uri_escape ${TOKEN} )
	PREV_VERSION="${VERSION}"
	VERSION=""
}

enable_token()
{
	#do_http_request_check_status "GET" "/scripts/enable_token.php?key=${KEY}&token=${TOKEN}" "" "" "token enabling"
	log "INFO" "System enabled"
}

disable_token()
{
	#do_http_request_check_status "GET" "/scripts/disable_token.php?key=${KEY}&token=${TOKEN}" "" "" "token disabling"
	log "INFO" "System disabled"
}

report_system()
{
	local REL=$( uri_escape $( ${UNAME_CMD} -r ) )
	local ARCH=$( ${UNAME_CMD} -m )

	case "${OS}" in
		FreeBSD)
			local line=$(${SYSCTL_CMD} -n hw.model)
			local VEN=$(echo $line | ${CUT_CMD} -d ' ' -f 1)
			local DEV=$(uri_escape $(echo $line | ${CUT_CMD} -d ' ' -f 2-))
			local count=$(${SYSCTL_CMD} -n hw.ncpu)
			;;
		Linux)
			local line=$( ${GREP_CMD} "^model name" /proc/cpuinfo | ${HEAD_CMD} -n1 | ${CUT_CMD} -d ':' -f 2 )
			local VEN=$(echo ${line} | ${AWK_CMD} '{printf $1}' )
			local count=$( grep ^processor /proc/cpuinfo | ${WC_CMD} -l | ${AWK_CMD} '{printf $1}' )
			DEV=$( uri_escape $(echo "${line}" | ${CUT_CMD} -d ' ' -f 2- ))
			;;
	esac
	
	# FIO
	TYPE="fio"
	PROFILE="randread.fio"

	READ_BW_BYTES=$( ${CAT_CMD} ${progdir}/fio/tests/4k/randread-1-2.json | ${JQ_CMD} '.jobs[0].read.bw_bytes' | ${TR_CMD} -d '"' )
	WRITE_BW_BYTES=$( ${CAT_CMD} ${progdir}/fio/tests/4k/randread-1-2.json | ${JQ_CMD} '.jobs[0].write.bw_bytes' | ${TR_CMD} -d '"' )
	RUNTIME=$( ${CAT_CMD} ${progdir}/fio/tests/4k/randread-1-2.json | ${JQ_CMD} '.jobs[0]."job options".runtime' | ${TR_CMD} -d '"' )

	#echo $READ_BW_BYTES
	#echo $WRITE_BW_BYTES
	#echo $RUNTIME
	KB=$(( READ_BW_BYTES / 1024 ))
	MB=$(( READ_BW_BYTES / 1024 / 1024 ))

	#echo "MB per sec: $MB"
	#echo "MB per sec: $MB"


	echo_begin "Posting perf statistics to ${checkin_server_description}"
	do_http_request_check_status "GET" "/scripts/report_system.php?token=${TOKEN}&key=${KEY}&rel=${REL}&arch=${ARCH}&opsys=${OS}&cpus=${count}&vendor=${VEN}&cpu_type=${DEV}&bench_type=${TYPE}&bench_profile=${PROFILE}&fio_bw_mb=${MB}&fio_bw_kb=${KB}" "" "" "OS statistics submission"
	echo_end_success
	log "INFO" "Posted OS statistics to ${checkin_server_description}"
}

report_cpu() {
  local line=$(${SYSCTL_CMD} -n hw.model)
  local VEN=$(echo $line | ${CUT_CMD} -d ' ' -f 1)
  local DEV=$(uri_escape $(echo $line | ${CUT_CMD} -d ' ' -f 2-))
  local count=$(${SYSCTL_CMD} -n hw.ncpu)
  echo_begin "Posting CPU information to ${checkin_server_description}"
  do_http_request_check_status "GET" "/scripts/report_cpu.php?token=${TOKEN}&key=${KEY}&cpus=${count}&vendor=${VEN}&cpu_type=${DEV}" \
      "" "" "CPU information submission"
  echo_end_success
  log "INFO" "Posted CPU information to ${checkin_server_description}"
}

#
#data="/tmp/x5.tgz"
#curl -sS -X POST -H "Content-Type: application/gzip" --data-binary "@$data" ${checkin_server}/scripts/report_system.php?token=ssssssssssssssssss

##
## MAIN: processing begins here
##
# network setup
setup_proxies

echo "Checkin server: ${checkin_server}"
url="${checkin_server}"

_ret=0
test_connection

log "INIT" "Connected to ${checkin_server_description}"

# prepare
get_id_token
ret=$?

#exit 0

# begin
enable_token
report_system


# optional parts
#       report_devices
#       report_cpu
disable_token
