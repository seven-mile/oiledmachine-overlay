#!/bin/sh
# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# Original script from https://gitweb.gentoo.org/repo/gentoo.git/tree/sys-power/cpupower
# =sys-power/cpupower-5.18::gentoo

. /etc/conf.d/cpupower
. /etc/finit.d/scripts/lib.sh

SVCNAME=${SVCNAME:-"cpupower"}

CPUFREQ_SYSFS="/sys/devices/system/cpu/cpufreq"

change() {
	local c ret=0 opts="$1"
	if [ -n "$opts" ] ; then
		ebegin "Running cpupower -c all frequency-set ${opts}"
			cpupower -c all frequency-set ${opts} >/dev/null 2>&1
			: $(( ret += $? ))
		eend ${ret}

		if [ -d "${CPUFREQ_SYSFS}" ] && [ -n "${SYSFS_EXTRA}" ] ; then
			c=1
			einfo "Setting extra options: ${SYSFS_EXTRA}"
			if cd "${CPUFREQ_SYSFS}" ; then
				local o v
				for o in ${SYSFS_EXTRA} ; do
					v=${o#*=}
					o=${o%%=*}
					echo ${v} > ${o} || break
				done
				c=0
			fi
			eend ${c}
			: $(( ret += c ))
		fi
	fi

	return ${ret}
}
