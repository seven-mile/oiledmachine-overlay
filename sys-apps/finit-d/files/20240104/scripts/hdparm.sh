#!/bin/sh
# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# Original script from https://gitweb.gentoo.org/repo/gentoo.git/tree/sys-apps/hdparm
# =sys-apps/hdparm-9.65-r2::gentoo

. /etc/conf.d/hdparm
. /etc/finit.d/scripts/lib.sh

do_hdparm() {
	local e=
	eval e=\$${extra_args}
	[ -z "${args}${all_args}${e}" ] && return 0

	if [ -n "${args:=${all_args} ${e}}" ] ; then
		local orgdevice=$(readlink -f "${device}")
		if [ -b "${orgdevice}" ] ; then
			ebegin "Running hdparm on ${device}"
			hdparm ${args} "${device}" > /dev/null
			eend $?
		fi
	fi
}

scan_nondevfs() {
	# non-devfs compatible system
	local device

	for device in /dev/hd* /dev/sd* /dev/cdrom* ; do
		[ -e "${device}" ] || continue
		case "${device}" in
			*[0-9]) continue ;;
			/dev/hd*)  extra_args="pata_all_args" ;;
			/dev/sd*)  extra_args="sata_all_args" ;;
			*)         extra_args="_no_xtra_args" ;;
		esac

		# check that the block device really exists by
		# opening it for reading
		local errmsg= status= nomed=1
		errmsg=$(export LC_ALL=C ; : 2>&1 <"${device}")
		status=$?
		case ${errmsg} in
		    *": No medium found") nomed=0;;
		esac
		if [ -b "${device}" ] && [ "${status}" = "0" -o "${nomed}" = "0" ] ; then
			local conf_var="${device##*/}_args"
			eval args=\$${conf_var}
			do_hdparm
		fi
	done
}

start() {
	if get_bootparam "nohdparm" ; then
		ewarn "Skipping hdparm init as requested in kernel cmdline"
		return 0
	fi

	scan_nondevfs
}

start
