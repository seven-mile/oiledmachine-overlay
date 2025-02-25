#!/bin/sh
# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
# Original script from https://gitweb.gentoo.org/repo/gentoo.git/tree/app-containers/containerd
# =app-containers/containerd-1.7.1-r1::gentoo

. /etc/conf.d/containerd
. /etc/finit.d/scripts/lib.sh

SVCNAME=${SVCNAME:-"containerd"}
RC_SVCNAME=${SVCNAME}

command="/usr/bin/containerd"
pidfile=${pidfile:-"/run/${RC_SVCNAME}.pid"}

start_pre() {
	checkpath "d" "-" "0750" "/var/log/containerd"
	ulimit -n 1048576 -u unlimited
}

start() {
	set -- ${command_args:-""}
	exec "${command}" "$@" 2>"/var/log/${RC_SVCNAME}/${RC_SVCNAME}.log" 1>"/var/log/${RC_SVCNAME}/${RC_SVCNAME}.log"
}

start_pre
start
