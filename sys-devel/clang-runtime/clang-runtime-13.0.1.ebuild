# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit multilib-build

DESCRIPTION="Meta-ebuild for clang runtime libraries"
HOMEPAGE="https://clang.llvm.org/"
LICENSE="metapackage"
SLOT="$(ver_cut 1-3)"
KEYWORDS="
amd64 arm arm64 ~ppc ppc64 ~riscv ~sparc x86 ~amd64-linux ~ppc-macos ~x64-macos
"
IUSE+=" +compiler-rt libcxx openmp +sanitize"
REQUIRED_USE="
	sanitize? (
		compiler-rt
	)
"
RDEPEND="
	compiler-rt? (
		~sys-libs/compiler-rt-${PV}:${SLOT}
		sanitize? (
			~sys-libs/compiler-rt-sanitizers-${PV}:${SLOT}
		)
	)
	libcxx? (
		>=sys-libs/libcxx-${PV}[${MULTILIB_USEDEP}]
	)
	openmp? (
		sys-libs/libomp:${PV%%.*}[${MULTILIB_USEDEP}]
	)
"
SRC_URI=""
