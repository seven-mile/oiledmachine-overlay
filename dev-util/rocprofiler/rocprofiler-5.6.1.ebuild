# Copyright 2023 Orson Teodoro <orsonteodoro@hotmail.com>
# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

AMDGPU_TARGETS_COMPAT=(
	gfx900
	gfx906
	gfx908
	gfx90a
	gfx1030
)

LLVM_MAX_SLOT=16
PYTHON_COMPAT=( python3_{10..11} )
ROCM_SLOT="$(ver_cut 1-2 ${PV})"

inherit cmake flag-o-matic llvm python-any-r1 rocm

SRC_URI="
https://github.com/ROCm-Developer-Tools/${PN}/archive/rocm-${PV}.tar.gz
	-> ${P}.tar.gz
"

DESCRIPTION="Callback/Activity Library for Performance tracing AMD GPU's"
HOMEPAGE="https://github.com/ROCm-Developer-Tools/rocprofiler.git"
LICENSE="
	MIT
	BSD
	Apache-2.0
"
# BSD - src/util/hsa_rsrc_factory.cpp
# Apache-2.0 - plugin/perfetto/perfetto_sdk/sdk/perfetto.cc
SLOT="${ROCM_SLOT}/${PV}"
KEYWORDS="~amd64"
IUSE=" +aqlprofile system-llvm test r8"
REQUIRED_USE="
	${ROCM_REQUIRED_USE}
"
RDEPEND="
	!dev-util/rocprofiler:0
	dev-python/barectf
	dev-util/rocm-compiler:${ROCM_SLOT}[system-llvm=]
	~dev-libs/rocm-comgr-${PV}:${ROCM_SLOT}
	~dev-libs/rocr-runtime-${PV}:${ROCM_SLOT}
	~dev-util/hip-${PV}:${ROCM_SLOT}
	~dev-util/roctracer-${PV}:${ROCM_SLOT}
	aqlprofile? (
		~dev-libs/hsa-amd-aqlprofile-${PV}:${ROCM_SLOT}
		~dev-libs/rocr-runtime-${PV}:${ROCM_SLOT}
	)
"
DEPEND="
	${RDEPEND}
"
BDEPEND="
	$(python_gen_any_dep '
		dev-python/CppHeaderParser[${PYTHON_USEDEP}]
	')
	>=dev-util/cmake-3.18.0
	test? (
		!system-llvm? (
			~sys-devel/llvm-roc-${PV}:${ROCM_SLOT}
		)
		sys-devel/gcc[sanitize]
		system-llvm? (
			sys-devel/clang:${LLVM_MAX_SLOT}
		)
	)
"
RESTRICT="test"
S="${WORKDIR}/${PN}-rocm-${PV}"
PATCHES=(
	"${FILESDIR}/${PN}-5.6.0-toggle-aqlprofile.patch"
	"${FILESDIR}/${PN}-5.6.1-path-changes.patch"
)

python_check_deps() {
	python_has_version "dev-python/CppHeaderParser[${PYTHON_USEDEP}]"
}

pkg_setup() {
	llvm_pkg_setup
	python-any-r1_pkg_setup
	rocm_pkg_setup
}

src_prepare() {
	cmake_src_prepare

	if ! use aqlprofile ; then
ewarn
ewarn "You are enabling an experimental patch."
ewarn "For production, set USE=aqlprofile ON."
ewarn

		# Caused by commit e80f7cb
		sed \
			-i \
			-e "s|NOT AQLPROFILE_LIB|FALSE|g" \
			"src/api/CMakeLists.txt" \
			|| die

		# Caused by commit e80f7cb
		sed \
			-i \
			-e "s|NOT AQLPROFILE_LIB|FALSE|g" \
			"src/tools/rocprofv2/CMakeLists.txt" \
			|| die

		# Caused by commit 071379b
		sed \
			-i \
			-e "s|NOT FIND_AQL_PROFILE_LIB|FALSE|g" \
			"cmake_modules/env.cmake" \
			|| die
	fi

	rocm_src_prepare
}

src_configure() {
	if use aqlprofile ; then
		[[ -e "${ESYSROOT}/opt/rocm-${PV}/lib/hsa-amd-aqlprofile/librocprofv2_att.so" ]] \
			|| die "Missing" # For e80f7cb
		[[ -e "${ESYSROOT}/opt/rocm-${PV}/lib/libhsa-amd-aqlprofile64.so" ]] \
			|| die "Missing" # For 071379b
		append-ldflags -Wl,-rpath="${EPREFIX}/opt/rocm-${PV}/lib"
	fi

	export CMAKE_BUILD_TYPE="debug"
	export HIP_PLATFORM="amd"
	local gpu_targets=$(get_amdgpu_flags \
		| tr ";" " ")
	local mycmakeargs=(
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}${EROCM_PATH}"
		-DCMAKE_MODULE_PATH="${ESYSROOT}${EROCM_PATH}/$(get_libdir)/cmake/hip"
		-DCMAKE_PREFIX_PATH="${EPREFIX}${EROCM_PATH}/include/hsa"
		-DCMAKE_SKIP_RPATH=ON
		-DFILE_REORG_BACKWARD_COMPATIBILITY=OFF
		-DGPU_TARGETS="${gpu_targets}"
		-DHIP_COMPILER="clang"
		-DHIP_PLATFORM="amd"
		-DHIP_ROOT_DIR="${ESYSROOT}${EROCM_PATH}"
		-DHIP_RUNTIME="rocclr"
		-DPROF_API_HEADER_PATH="${ESYSROOT}${EROCM_PATH}/include/roctracer/ext"
		-DUSE_PROF_API=1
		-DAQLPROFILE=$(usex aqlprofile ON OFF)
	)
	if use system-llvm ; then
		export CC="${HIP_CC:-${CHOST}-clang-${LLVM_MAX_SLOT}}"
		export CXX="${HIP_CXX:-${CHOST}-clang++-${LLVM_MAX_SLOT}}"
	else
		export CC="${HIP_CC:-clang}"
		export CXX="${HIP_CXX:-clang++}"
	fi
	cmake_src_configure
}

src_install() {
	cmake_src_install
	rocm_mv_docs
	rocm_fix_rpath
}

# OILEDMACHINE-OVERLAY-STATUS:  builds-without-problems

