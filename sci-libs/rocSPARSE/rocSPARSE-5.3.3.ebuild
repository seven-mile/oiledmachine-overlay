# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

AMDGPU_TARGETS_COMPAT=(
	gfx803
	gfx900_xnack_minus
	gfx906_xnack_minus
	gfx908_xnack_minus
	gfx90a_xnack_minus
	gfx90a_xnack_plus
	gfx1030
)
PYTHON_COMPAT=( python3_{9..11} )
LLVM_MAX_SLOT=15 # See https://github.com/RadeonOpenCompute/llvm-project/blob/rocm-5.3.3/llvm/CMakeLists.txt
ROCM_SLOT="$(ver_cut 1-2 ${PV})"
ROCM_VERSION="${PV}"

inherit cmake edo flag-o-matic llvm python-any-r1 toolchain-funcs rocm

SRC_URI="
https://github.com/ROCmSoftwarePlatform/rocSPARSE/archive/rocm-${PV}.tar.gz
	-> rocSPARSE-${PV}.tar.gz
	test? (
https://sparse.tamu.edu/MM/SNAP/amazon0312.tar.gz
	-> ${PN}_amazon0312.tar.gz
https://sparse.tamu.edu/MM/Muite/Chebyshev4.tar.gz
	-> ${PN}_Chebyshev4.tar.gz
https://sparse.tamu.edu/MM/FEMLAB/sme3Dc.tar.gz
	-> ${PN}_sme3Dc.tar.gz
https://sparse.tamu.edu/MM/Williams/webbase-1M.tar.gz
	-> ${PN}_webbase-1M.tar.gz
https://sparse.tamu.edu/MM/Bova/rma10.tar.gz
	-> ${PN}_rma10.tar.gz
https://sparse.tamu.edu/MM/JGD_BIBD/bibd_22_8.tar.gz
	-> ${PN}_bibd_22_8.tar.gz
https://sparse.tamu.edu/MM/Williams/mac_econ_fwd500.tar.gz
	-> ${PN}_mac_econ_fwd500.tar.gz
https://sparse.tamu.edu/MM/Williams/mc2depi.tar.gz
	-> ${PN}_mc2depi.tar.gz
https://sparse.tamu.edu/MM/Hamm/scircuit.tar.gz
	-> ${PN}_scircuit.tar.gz
https://sparse.tamu.edu/MM/Sandia/ASIC_320k.tar.gz
	-> ${PN}_ASIC_320k.tar.gz
https://sparse.tamu.edu/MM/GHS_psdef/bmwcra_1.tar.gz
	-> ${PN}_bmwcra_1.tar.gz
https://sparse.tamu.edu/MM/HB/nos1.tar.gz
	-> ${PN}_nos1.tar.gz
https://sparse.tamu.edu/MM/HB/nos2.tar.gz
	-> ${PN}_nos2.tar.gz
https://sparse.tamu.edu/MM/HB/nos3.tar.gz
	-> ${PN}_nos3.tar.gz
https://sparse.tamu.edu/MM/HB/nos4.tar.gz
	-> ${PN}_nos4.tar.gz
https://sparse.tamu.edu/MM/HB/nos5.tar.gz
	-> ${PN}_nos5.tar.gz
https://sparse.tamu.edu/MM/HB/nos6.tar.gz
	-> ${PN}_nos6.tar.gz
https://sparse.tamu.edu/MM/HB/nos7.tar.gz
	-> ${PN}_nos7.tar.gz
https://sparse.tamu.edu/MM/DNVS/shipsec1.tar.gz
	-> ${PN}_shipsec1.tar.gz
https://sparse.tamu.edu/MM/Cote/mplate.tar.gz
	-> ${PN}_mplate.tar.gz
https://sparse.tamu.edu/MM/Bai/qc2534.tar.gz
	-> ${PN}_qc2534.tar.gz
https://sparse.tamu.edu/MM/Chevron/Chevron2.tar.gz
	-> ${PN}_Chevron2.tar.gz
https://sparse.tamu.edu/MM/Chevron/Chevron3.tar.gz
	-> ${PN}_Chevron3.tar.gz
https://sparse.tamu.edu/MM/Chevron/Chevron4.tar.gz
	-> ${PN}_Chevron4.tar.gz
	)
"

DESCRIPTION="Basic Linear Algebra Subroutines for sparse computation"
HOMEPAGE="https://github.com/ROCmSoftwarePlatform/rocSPARSE"
LICENSE="MIT"
KEYWORDS="~amd64"
IUSE="benchmark system-llvm test r3"
REQUIRED_USE="
	${ROCM_REQUIRED_USE}
"
SLOT="${ROCM_SLOT}/${PV}"
RDEPEND="
	!sci-libs/rocSPARSE:0
	!system-llvm? (
		sys-libs/llvm-roc-libomp:=
		~sys-libs/llvm-roc-libomp-${PV}:${ROCM_SLOT}
	)
	dev-util/rocm-compiler:${ROCM_SLOT}[system-llvm=]
	~dev-util/hip-${PV}:${ROCM_SLOT}[rocm]
	~sci-libs/rocPRIM-${PV}:${ROCM_SLOT}[rocm(+)]
	system-llvm? (
		sys-libs/libomp:${LLVM_MAX_SLOT}
	)
"
DEPEND="
	${RDEPEND}
"
BDEPEND="
	>=dev-util/cmake-3.5
	sys-devel/gcc[fortran]
	test? (
		$(python_gen_any_dep '
			dev-python/pyyaml[${PYTHON_USEDEP}]
		')
		>=dev-cpp/gtest-1.11.0
	)
	benchmark? (
		app-admin/chrpath
	)
	~dev-util/rocm-cmake-${PV}:${ROCM_SLOT}
"
RESTRICT="
	!test? (
		test
	)
"
S="${WORKDIR}/rocSPARSE-rocm-${PV}"
PATCHES=(
	"${FILESDIR}/${PN}-5.3.3-remove-matrices-unpacking.patch"
	"${FILESDIR}/${PN}-5.6.0-includes.patch"
	"${FILESDIR}/${PN}-5.4.3-fma-fix.patch"
	"${FILESDIR}/${PN}-5.6.0-path-changes.patch"
)

python_check_deps() {
	if use test; then
		python_has_version "dev-python/pyyaml[${PYTHON_USEDEP}]"
	fi
}

pkg_setup() {
	llvm_pkg_setup # For LLVM_SLOT init.  Must be explicitly called or it is blank.
	python-any-r1_pkg_setup
	rocm_pkg_setup
}

src_prepare() {
	# Removing the GIT dependency.
	sed \
		-e "/find_package(Git/d" \
		-i \
		cmake/Dependencies.cmake \
		|| die

	cmake_src_prepare

	#
	# The tests need download data from
	# https://sparse.tamu.edu (or other mirror site).
	# [You] need to check the MD5.
	# [You] need to ynpack the data and convert them into csr format.
	#
	# This process is handled default by ${S}/cmake/ClientMatrices.cmake,
	# but should be the responsibility of portage.
	#
	if use test; then
		mkdir -p "${BUILD_DIR}/clients/matrices"
	# Compile and use the mtx2csr converter. Do not use any optimization
	# flags, because it causes error!
		edo $(tc-getCXX) deps/convert.cpp -o deps/convert
		find \
			"${WORKDIR}" \
			-maxdepth 2 \
			-regextype \
			grep \
				-E \
				-regex ".*/(.*)/\1\.mtx" \
				-print0 |
		while IFS= read -r -d '' mtxfile; do
			local destination="${BUILD_DIR}/clients/matrices/"$(basename -s '.mtx' "${mtxfile}")".csr"
			ebegin "Converting ${mtxfile} to ${destination}"
			deps/convert "${mtxfile}" "${destination}"
			eend $?
		done
	fi
	rocm_src_prepare
}

src_configure() {
	addpredict /dev/kfd
	addpredict /dev/dri/

# Fix for
# local memory (403200) exceeds limit (65536) in function '_Z10bsr_gatherILj4ELj64ELj2EifEv20rocsparse_direction_T2_PKS1_PKT3_PS4_S1_'
	replace-flags '-O0' '-O1'

	export HIP_PLATFORM="amd"
	local mycmakeargs=(
		-DAMDGPU_TARGETS="$(get_amdgpu_flags)"
		-DBUILD_CLIENTS_BENCHMARKS=$(usex benchmark ON OFF)
		-DBUILD_CLIENTS_SAMPLES=OFF
		-DBUILD_CLIENTS_TESTS=$(usex test ON OFF)
		-DBUILD_FILE_REORG_BACKWARD_COMPATIBILITY=OFF
		-DCMAKE_INSTALL_INCLUDEDIR="include/rocsparse"
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}${EROCM_PATH}"
		-DCMAKE_SKIP_RPATH=ON
		-DHIP_COMPILER="clang"
		-DHIP_PLATFORM="amd"
		-DHIP_RUNTIME="rocclr"
	)
	export CC="${HIP_CC:-hipcc}"
	export CXX="${HIP_CXX:-hipcc}"
	cmake_src_configure
}

src_test() {
	check_amdgpu
	cd "${BUILD_DIR}/clients/staging" || die
	LD_LIBRARY_PATH="${BUILD_DIR}/library" \
	edob ./${PN,,}-test
}

src_install() {
	cmake_src_install
	if use benchmark; then
		cd "${BUILD_DIR}" || die
		dobin clients/staging/rocsparse-bench
	fi
	rocm_mv_docs
	rocm_fix_rpath
}

# OILEDMACHINE-OVERLAY-STATUS:  build-needs-test
# OILEDMACHINE-OVERLAY-EBUILD-FINISHED:  NO
