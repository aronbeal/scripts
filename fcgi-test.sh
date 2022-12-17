#!/bin/bash
##
# Performs fcgi tests of php container.
# This is to help check the php-fpm service is up and running.  This is currently local-only
# and cannot be executed from the production container.
set -e

. $(dirname $0)/common.sh

usage() {
	cat <<HELP_USAGE
Performs various fcgi calls to the php container.
This is to help check the php-fpm service is up and running and to get php-fpm status.
For debugging only, not meant for regular developer use.  This is
currently local-only and cannot be executed from the production container.

Usage:
  $0 [flag]

Where flag is one of:
  -c  Invokes a script that will clear the php-fpm cache.  The file phpfpm_opcache_reset.php
      must already exist in the public folder of the project. This is for debugging php-fpm cache.
  -h  Shows this help text.
  -p  Perform an fcgi ping test in both containers.
  -s  Perform an fcgi status call in both containers.
  -t  Invokes a script from php-cgi context to test opcache.  The file phpfpm_opcache_test.php
      must already exist in the public folder of the project.  This is for debugging
      php-fpm cache.  The file is configured to return either 'foo' or 'bar', changing its
      contents to change the value it returns each time it is invoked.  If the opcache is stale,
      the value will stay either at 'foo' or 'bar', rather than changing.

HELP_USAGE
}

call_fcgi() {
	[[ -z ${1} ]] && fail "${FUNCNAME[0]} requires an env var string argument."
	echo ''
	docker compose exec php bash -c "${1} cgi-fcgi -bind -connect 127.0.0.1:9000" || fail "Could not execute fcgi command"
	echo ''
}

do_ping_test() {
	echo "php: Ping"
	call_fcgi 'SCRIPT_NAME=/ping SCRIPT_FILENAME=/ping REQUEST_METHOD=GET';
}

do_status_check() {
	echo "php: Status check"
	call_fcgi 'SCRIPT_NAME=/status SCRIPT_FILENAME=/status QUERY_STRING=full REQUEST_METHOD=GET'
}

do_execute_test_dot_php() {
	file="/srv/api/public/phpfpm_opcache_test.php"
	echo "php: Executing ${file} on the server, if it exists."
    call_fcgi "SCRIPT_NAME=$(basename ${file}) SCRIPT_FILENAME=${file} REQUEST_METHOD=GET"
}

do_cache_clear() {
	file="/srv/api/public/phpfpm_opcache_reset.php"
	echo "php: Cache clear."
	call_fcgi "SCRIPT_NAME=$(basename ${file}) SCRIPT_FILENAME=${file} REQUEST_METHOD=GET"
}

call_method=false
while getopts "chpst" o; do
	case "${o}" in
	c)
		call_method='do_cache_clear'
		;;
	h)
		usage
		exit 0
		;;
	p)
		call_method='do_ping_test'
		;;
	s)
		call_method='do_status_check'
		;;
	t)
		call_method='do_execute_test_dot_php'
		;;
	*)
		usage
		exit 1
		;;
	esac
done

shift $((OPTIND - 1))

if ! is_service_running "php"; then
	fail "Running the cs fixer without a running stack is not yet supported"
fi

# Invoke the method set by getopts.
[[ ${call_method} == 'do_ping_test' ]] && do_ping_test
[[ ${call_method} == 'do_status_check' ]] && do_status_check
[[ ${call_method} == 'do_execute_test_dot_php' ]] && do_execute_test_dot_php
[[ ${call_method} == 'do_cache_clear' ]] && do_cache_clear
echo "Done"
