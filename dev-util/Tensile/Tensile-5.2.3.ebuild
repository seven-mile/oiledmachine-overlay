# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# FIXME: build

AMDGPU_TARGETS_COMPAT=(
	gfx803
	gfx900
	gfx906
	gfx908
	gfx90a
	gfx1010
	gfx1011
	gfx1012
	gfx1030
	gfx1100
	gfx1101
	gfx1102
)
PYTHON_COMPAT=( python3_{10..11} )
DISTUTILS_USE_PEP517="setuptools"
GCC_SLOT=11
LLVM_MAX_SLOT=14
ROCM_SLOT="$(ver_cut 1-2 ${PV})"
ROCM_VERSION="${PV}"

inherit cmake distutils-r1 llvm prefix rocm toolchain-funcs

DESCRIPTION="Stretching GPU performance for GEMMs and tensor contractions"
HOMEPAGE="https://github.com/ROCmSoftwarePlatform/Tensile"
SRC_URI="
https://github.com/ROCmSoftwarePlatform/Tensile/archive/rocm-${PV}.tar.gz
	-> rocm-Tensile-${PV}.tar.gz
"
LICENSE="MIT"
KEYWORDS="~amd64"
SLOT="${ROCM_SLOT}/${PV}"
IUSE="client openmp system-llvm r8"
REQUIRED_USE="
	client? (
		${ROCM_REQUIRED_USE}
		openmp
	)
"
RDEPEND="
	!system-llvm? (
		sys-devel/llvm-roc:=
		~sys-devel/llvm-roc-${PV}:${ROCM_SLOT}
	)
	${PYTHON_DEPS}
	>=dev-cpp/msgpack-cxx-6.0.0
	dev-lang/python-exec:rocm-${ROCM_SLOT}
	dev-python/msgpack[${PYTHON_USEDEP}]
	dev-python/pyyaml[${PYTHON_USEDEP}]
	dev-util/rocm-compiler:${ROCM_SLOT}[system-llvm=]
	~dev-util/hip-${PV}:${ROCM_SLOT}
	client? (
		dev-libs/boost
		sys-devel/gcc:${GCC_SLOT}
		~dev-util/rocm-smi-${PV}:${ROCM_SLOT}
	)
	openmp? (
		sys-devel/lld:${LLVM_MAX_SLOT}
		sys-libs/libomp:${LLVM_MAX_SLOT}
	)
	system-llvm? (
		sys-devel/clang:${LLVM_MAX_SLOT}
	)
"
DEPEND="
	${RDEPEND}
"
BDEPEND="
	>=dev-util/cmake-3.13
"
# Not compatible with recent versions of pytest
RESTRICT="test"
S="${WORKDIR}/${PN}-rocm-${PV}"
_PATCHES=(
	"${FILESDIR}/${PN}-change-cmake-name-for-msgpack-cxx-6-release.patch"
	"${FILESDIR}/${PN}-4.3.0-output-commands.patch"
#	"${FILESDIR}/${PN}-5.4.2-gfx1031.patch"
	"${FILESDIR}/${PN}-5.2.3-fix-arch-parse.patch"
	"${FILESDIR}/${PN}-5.0.2-use-ninja.patch"
	"${FILESDIR}/${PN}-5.2.3-path-changes.patch"
)
CMAKE_USE_DIR="${S}/${PN}/Source"

pkg_setup() {
	llvm_pkg_setup # For LLVM_SLOT init.  Must be explicitly called or it is blank.
	python_setup
	rocm_pkg_setup
}

src_prepare() {
	eapply "${_PATCHES[@]}"
	distutils-r1_src_prepare

	pushd "${PN}" || die
		sed \
			-r \
			-e "/TENSILE_USE_LLVM/s/ON/OFF/" \
			-i \
			"Source/CMakeLists.txt" \
			|| die
		sed \
			-e "/chmod 755/d" \
			-i \
			"Source/TensileCreateLibrary.cmake" \
			|| die # remove chmod 755 on
		hipconfig --version || die
		sed \
			-e "/HipClangVersion/s/0.0.0/$(hipconfig -v)/" \
			-i \
			"Common.py" \
			|| die
	popd || die

	sed \
		-e "/package_data/d" \
		-e "/data_files/d" \
		-i \
		"setup.py" \
		|| die

	cmake_src_prepare
	rocm_src_prepare
}

src_configure() {
	export CC="${HIP_CC:-hipcc}"
	export CXX="${HIP_CXX:-hipcc}"
	if use openmp ; then
		append-flags -fuse-ld=lld
	fi
	append-ldflags \
		-Wl,-L/usr/$(get_libdir)/rocm/${ROCM_SLOT}/llvm/$(get_libdir) \
		-Wl,-lLLVMSupport

	export TENSILE_ROCM_ASSEMBLER_PATH="${ESYSROOT}${EROCM_LLVM_PATH}/bin/clang++"
	export TENSILE_ROCM_OFFLOAD_BUNDLER_PATH="${ESYSROOT}${EROCM_LLVM_PATH}/bin/clang-offload-bundler"

	distutils-r1_src_configure

	if use client; then
		local gcc_current_profile=$(gcc-config -c)
		local gcc_current_profile_slot=${gcc_current_profile##*-}

		if ver_test "${GCC_SLOT}" -ne "${gcc_current_profile_slot}" ; then
# Fixes:
#shared_ptr_base.h:196:22: error: use of undeclared identifier 'noinline'; did you mean 'inline'?
#      __attribute__((__noinline__))
#                     ^
eerror
eerror "You must switch to == GCC ${GCC_SLOT}.  Do"
eerror
eerror "  eselect gcc set ${CHOST}-${GCC_SLOT}"
eerror "  source /etc/profile"
eerror
eerror "This is a temporary for ${PN}:${SLOT}.  You must restore it back"
eerror "to the default immediately after this package has been merged."
eerror
			die
		fi

		export HIP_PLATFORM="amd"
		local mycmakeargs=(
			-DAMDGPU_TARGETS="$(get_amdgpu_flags)"
			-DCMAKE_SKIP_RPATH=ON
			-DHIP_COMPILER="clang"
			-DHIP_PLATFORM="amd"
			-DHIP_RUNTIME="rocclr"
			-DTENSILE_BUILD_CLIENT=$(usex client ON OFF)
			-DTENSILE_USE_LLVM=ON
			-DTENSILE_USE_MSGPACK=ON
			-DTENSILE_USE_OPENMP=$(usex openmp ON OFF)
			-DTensile_LIBRARY_FORMAT="msgpack"
		)
		cmake_src_configure
	fi
}

src_compile() {
	distutils-r1_src_compile
	use client && cmake_src_compile
}

python_install() {
	distutils-r1_python_install
	python_moduleinto "Tensile"
	cd "Tensile" || die
	python_domodule "Components"
	python_newexe "Utilities/merge.py" "${PN}-merge"

	dodir "${EROCM_PATH}/lib/python-exec/${EPYTHON}"
	cp -aT \
		"${ED}/usr/lib/python-exec/${EPYTHON}" \
		"${ED}${EROCM_PATH}/lib/python-exec/${EPYTHON}" \
		|| die
	rm -rf "${ED}/usr/lib/python-exec/${EPYTHON}" || die

	dodir "${EROCM_PATH}/lib/${EPYTHON}/site-packages"
	cp -aT \
		"${ED}/usr/lib/${EPYTHON}/site-packages" \
		"${ED}${EROCM_PATH}/lib/${EPYTHON}/site-packages" \
		|| die
	rm -rf "${ED}/usr/lib/${EPYTHON}/site-packages" || die
}

src_install() {
	export EPREFIX="${EPREFIX}/${EROCM_PATH}"
	distutils-r1_src_install
	cd "${PN}" || die
	insinto "${EROCM_PATH}/share/${PN}"
	doins -r \
		"Configs" \
		"CustomKernels" \
		"Perf" \
		"ReplacementKernels" \
		"ReplacementKernels-cov3" \
		"Source"
	insinto "${EROCM_PATH}/$(get_libdir)/cmake/${PN}"
	doins "cmake/"*".cmake"
	if use client; then
		pushd "${BUILD_DIR}" || die
		dobin "client/tensile_client"
	fi
	rocm_mv_docs

	cp -aT \
		"${ED}/usr/bin" \
		"${ED}/${EROCM_PATH}/bin" \
		|| die
	rm -rf "${ED}/usr/bin" || die
	use client || ewarn "The symlinks require the client USE flag."
	rocm_fix_rpath
ewarn
ewarn "You must restore back the default gcc via eselect."
ewarn
}

# OILEDMACHINE-OVERLAY-STATUS:  builds-without-problems
