#!/bin/sh
# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# Original script from https://gitweb.gentoo.org/repo/gentoo.git/tree/sys-fs/cryptsetup
# =sys-fs/cryptsetup-2.6.1:0/12::gentoo

SVCNAME=${SVCNAME:-"dmcrypt"}

. /etc/conf.d/dmcrypt
. /etc/finit.d/scripts/lib.sh

# We support multiple dmcrypt instances based on $SVCNAME
conf_file="/etc/conf.d/${SVCNAME}"

# Get splash helpers if available.
if [ -e /sbin/splash-functions.sh ] ; then
	. /sbin/splash-functions.sh
fi

# Setup mappings for an individual target/swap
# Note: This relies on variables localized in the main body below.
dm_crypt_execute() {
	local dev ret mode foo source_dev

	if [ -z "${target}" -a -z "${swap}" ] ; then
		return
	fi

	# Set up default values.
	: ${dmcrypt_key_timeout:=1}
	: ${dmcrypt_max_timeout:=300}
	: ${dmcrypt_retries:=5}
	: ${wait:=5}

	# Handle automatic look up of the source path.
	if [ -z "${source}" -a -n "${loop_file}" ] ; then
		source=$(losetup --show -f "${loop_file}")
	fi
	case ${source} in
	*=*)
		i=0
		while [ ${i} -lt ${wait} ]; do
			if source_dev=$(blkid -l -t "${source}" -o "device") ; then
				source="${source_dev}"
				break
			fi
			: $((i += 1))
			einfo "waiting for source \"${source}\" for ${target}..."
			sleep 1
		done
		;;
	esac
	if [ -z "${source}" ] || [ ! -e "${source}" ] ; then
		ewarn "source \"${source}\" for ${target} missing, skipping..."
		return
	fi

	if [ -n "${header}" ] ; then
		header_opt="--header=${header}"

		i=0
		while [ ! -e "${header}" ] && [ ${i} -lt ${wait} ] ; do
			: $((i += 1))
			einfo "Waiting for header ${header} to appear for ${target} ${i}/${dmcrypt_max_timeout} ..."
			sleep 1
		done
		if [ ${i} -gt ${wait} ] || [ ${i} -eq ${wait} ] ; then
			ewarn "Waited ${i} times for header file ${header}. Aborting ${target}."
			return
		fi
	else
		header_opt=""
	fi

	if [ -n "${target}" ] ; then
		# let user set options, otherwise leave empty
		: ${options:=' '}
	elif [ -n "${swap}" ] ; then
		if cryptsetup ${header_opt} isLuks "${source}" 2>/dev/null ; then
			ewarn "The swap you have defined is a LUKS partition. Aborting crypt-swap setup."
			return
		fi
		target="${swap}"
		# swap contents do not need to be preserved between boots, luks not required.
		# suspend2 users should have initramfs's init handling their swap partition either way.
		: ${options:='-c aes -h sha1 -d /dev/urandom'}
		: ${pre_mount:='mkswap ${dev}'}
	fi

	if [ -n "${loop_file}" ] ; then
		dev="/dev/mapper/${target}"
		ebegin "  Setting up loop device ${source}"
		losetup "${source}" "${loop_file}"
	fi

	# cryptsetup:
	# open   <device> <name>      # <device> is $source
	# create <name>   <device>    # <name>   is $target
	local arg1="create" arg2="${target}" arg3="${source}"
	if cryptsetup ${header_opt} isLuks "${source}" 2>/dev/null ; then
		arg1="open"
		arg2="${source}"
		arg3="${target}"
	fi

	# Older versions reported:
	#	${target} is active:
	# Newer versions report:
	#	${target} is active[ and is in use.]
	if cryptsetup ${header_opt} status "${target}" | grep -E -q ' is active' ; then
		einfo "dm-crypt mapping ${target} is already configured"
		return
	fi
	splash svc_input_begin "${SVCNAME}" >/dev/null 2>&1

	# Handle keys
	if [ -n "${key}" ] ; then
		read_abort() {
			# some colors
			local ans savetty resettty
			[ -z "${NORMAL}" ] && eval $(eval_ecolors)
			einfon "  $1? (${WARN}yes${NORMAL}/${GOOD}No${NORMAL}) "
			shift
			# This is ugly as s**t.  But POSIX doesn't provide `read -t`, so
			# we end up having to implement our own crap with stty/etc...
			savetty=$(stty -g)
			resettty='stty ${savetty}; trap - EXIT HUP INT TERM'
			trap 'eval "${resettty}"' EXIT HUP INT TERM
			stty -icanon
			stty min 0 time "$(( $2 * 10 ))"
			ans=$(dd count=1 bs=1 2>/dev/null) || ans=''
			eval "${resettty}"
			if [ -z "${ans}" ] ; then
				printf '\r'
			else
				echo
			fi
			case ${ans} in
				[yY]) return 0;;
				*) return 1;;
			esac
		}

		# Notes: sed not used to avoid case where /usr partition is encrypted.
		mode=${key##*:} && ( [ "${mode}" = "${key}" ] || [ -z "${mode}" ] ) && mode=reg
		key=${key%:*}
		case "${mode}" in
		gpg|reg)
			# handle key on removable device
			if [ -n "${remdev}" ] ; then
				# temp directory to mount removable device
				local mntrem="${RC_SVCDIR}/dm-crypt-remdev.$$"
				if [ ! -d "${mntrem}" ] ; then
					if ! mkdir -p "${mntrem}" ; then
						ewarn "${source} will not be decrypted ..."
						einfo "Reason: Unable to create temporary mount point '${mntrem}'"
						return
					fi
				fi
				i=0
				einfo "Please insert removable device for ${target}"
				while [ ${i} -lt ${dmcrypt_max_timeout} ] ; do
					foo=""
					if mount -n -o ro "${remdev}" "${mntrem}" 2>/dev/null >/dev/null ; then
						# keyfile exists?
						if [ ! -e "${mntrem}${key}" ] ; then
							umount -n "${mntrem}"
							rmdir "${mntrem}"
							einfo "Cannot find ${key} on removable media."
							read_abort "Abort" ${dmcrypt_key_timeout} && return
						else
							key="${mntrem}${key}"
							break
						fi
					else
						[ -e "${remdev}" ] \
							&& foo="mount failed" \
							|| foo="mount source not found"
					fi
					: $((i += 1))
					read_abort "Stop waiting after $i attempts (${foo})" -t 1 && return
				done
			else    # keyfile ! on removable device
				if [ ! -e "${key}" ] ; then
					ewarn "${source} will not be decrypted ..."
					einfo "Reason: keyfile ${key} does not exist."
					return
				fi
			fi
			;;
		*)
			ewarn "${source} will not be decrypted ..."
			einfo "Reason: mode ${mode} is invalid."
			return
			;;
		esac
	else
		mode=none
	fi
	ebegin "  ${target} using: ${header_opt} ${options} ${arg1} ${arg2} ${arg3}"
	if [ "${mode}" = "gpg" ] ; then
		: ${gpg_options:='-q -d'}
		# gpg available ?
		if command -v gpg >/dev/null ; then
			i=0
			while [ ${i} -lt ${dmcrypt_retries} ] ; do
				# paranoid, don't store key in a variable, pipe it so it stays very little in ram unprotected.
				# save stdin stdout stderr "values"
				timeout ${dmcrypt_max_timeout} gpg ${gpg_options} "${key}" 2>/dev/null | \
					cryptsetup ${header_opt} --key-file - ${options} ${arg1} ${arg2} ${arg3}
				ret=$?
				# The timeout command exits 124 when it times out.
				[ ${ret} -eq 0 -o ${ret} -eq 124 ] && break
				: $(( i += 1 ))
			done
			eend ${ret} "failure running cryptsetup"
		else
			ewarn "${source} will not be decrypted ..."
			einfo "Reason: cannot find gpg application."
			einfo "You have to install app-crypt/gnupg first."
			einfo "If you have /usr on its own partition, try copying gpg to /bin ."
		fi
	else
		if [ "${mode}" = "reg" ] ; then
			cryptsetup ${header_opt} ${options} -d "${key}" ${arg1} ${arg2} ${arg3}
			ret=$?
			eend ${ret} "failure running cryptsetup"
		else
			cryptsetup ${header_opt} ${options} ${arg1} ${arg2} ${arg3}
			ret=$?
			eend ${ret} "failure running cryptsetup"
		fi
	fi
	if [ -d "${mntrem}" ] ; then
		umount -n "${mntrem}" 2>/dev/null >/dev/null
		rmdir "${mntrem}" 2>/dev/null >/dev/null
	fi
	splash svc_input_end "${SVCNAME}" >/dev/null 2>&1

	if [ ${ret} -ne 0 ] ; then
		cryptfs_status=1
	else
		if [ -n "${pre_mount}" ] ; then
			dev="/dev/mapper/${target}"
			eval ebegin \""    pre_mount: ${pre_mount}"\"
			eval "${pre_mount}" > /dev/null
			ewend $? || cryptfs_status=1
		fi
	fi
}

# Lookup optional bootparams
get_bootparam_val() {
	# We're given something like:
	#    foo=bar=cow
	# Return the "bar=cow" part.
	case $1 in
	*=*)
		echo "${1#*=}"
		;;
	esac
}
