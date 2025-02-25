#!/bin/sh
# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# Original script obtained from https://gitweb.gentoo.org/repo/gentoo.git/tree/www-servers/varnish

. /etc/finit.d/scripts/varnishd-lib.sh

start_pre() {
	checkconfig || return 1
}

start() {
	set -- -F -j "unix,user=varnish" -P "${VARNISHD_PID}" -f "${CONFIGFILE}" ${VARNISHD_OPTS}
	exec "${command}" "$@"
}

start_pre
start
