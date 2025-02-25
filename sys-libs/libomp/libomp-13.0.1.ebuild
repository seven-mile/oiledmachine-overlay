# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# For AMDGPUs, see https://github.com/llvm/llvm-project/blob/llvmorg-13.0.1/openmp/libomptarget/deviceRTLs/amdgcn/CMakeLists.txt#L101
# For NVPTX, see https://github.com/llvm/llvm-project/blob/llvmorg-13.0.1/openmp/libomptarget/DeviceRTL/CMakeLists.txt#L75
# For CUDA sdk versions, https://github.com/llvm/llvm-project/blob/llvmorg-13.0.1/clang/include/clang/Basic/Cuda.h
AMDGPU_TARGETS_COMPAT=(
	gfx700
	gfx701
	gfx801
	gfx803
	gfx900
	gfx902
	gfx906
	gfx908
)

CUDA_TARGETS_COMPAT=(
	auto
	sm_35
	sm_37
	sm_50
	sm_52
	sm_53
	sm_60
	sm_61
	sm_62
	sm_70
	sm_72
	sm_75
	sm_80
)
PYTHON_COMPAT=( python3_{9..10} )

inherit flag-o-matic cmake-multilib linux-info llvm llvm.org python-any-r1 rocm

DESCRIPTION="OpenMP runtime library for LLVM/clang compiler"
HOMEPAGE="https://openmp.llvm.org"
LICENSE="
	Apache-2.0-with-LLVM-exceptions
	|| (
		UoI-NCSA
		MIT
	)
"
SLOT="${LLVM_MAJOR}/${LLVM_SOABI}"
KEYWORDS="
amd64 arm arm64 ~ppc ppc64 ~riscv x86 ~amd64-linux ~x64-macos
"
IUSE="
${CUDA_TARGETS_COMPAT[@]/#/cuda_targets_}
${ROCM_IUSE}
cuda debug hwloc offload ompt test llvm_targets_AMDGPU llvm_targets_NVPTX
rocm_4_3 rocm_4_5 rpc
r5
"
# CUDA works only with the x86_64 ABI
gen_cuda_required_use() {
	local x
	for x in ${CUDA_TARGETS_COMPAT[@]} ; do
		echo "
			cuda_targets_${x}? (
				llvm_targets_NVPTX
			)
		"
	done
}
gen_rocm_required_use() {
	local x
	for x in ${AMDGPU_TARGETS_COMPAT[@]} ; do
		echo "
			amdgpu_targets_${x}? (
				llvm_targets_AMDGPU
			)
		"
	done
}
REQUIRED_USE="
	$(gen_cuda_required_use)
	cuda? (
		llvm_targets_NVPTX
	)
	llvm_targets_AMDGPU? (
		${ROCM_REQUIRED_USE}
		^^ (
			rocm_4_5
			rocm_4_3
		)
	)
	llvm_targets_NVPTX? (
		cuda
		|| (
			${CUDA_TARGETS_COMPAT[@]/#/cuda_targets_}
		)
	)
	rocm_4_3? (
		llvm_targets_AMDGPU
	)
	rocm_4_5? (
		llvm_targets_AMDGPU
	)
	rpc? (
		offload
	)
"
ROCM_SLOTS=(
	"4.5.2"
	"4.3.1"
)
gen_amdgpu_rdepend() {
	local pv
	for pv in ${ROCM_SLOTS[@]} ; do
		local s="${pv%.*}"
		echo "
			rocm_${s/./_}? (
				~dev-libs/rocr-runtime-${pv}:${s}[system-llvm]
				~dev-libs/roct-thunk-interface-${pv}:${s}
			)
		"
	done
}
RDEPEND="
	cuda_targets_sm_35? (
		=dev-util/nvidia-cuda-toolkit-11*:=
	)
	cuda_targets_sm_37? (
		=dev-util/nvidia-cuda-toolkit-11*:=
	)
	cuda_targets_sm_50? (
		|| (
			=dev-util/nvidia-cuda-toolkit-11*:=
		)
	)
	cuda_targets_sm_52? (
		|| (
			=dev-util/nvidia-cuda-toolkit-11*:=
		)
	)
	cuda_targets_sm_53? (
		|| (
			=dev-util/nvidia-cuda-toolkit-11*:=
		)
	)
	cuda_targets_sm_60? (
		|| (
			=dev-util/nvidia-cuda-toolkit-11*:=
		)
	)
	cuda_targets_sm_61? (
		|| (
			=dev-util/nvidia-cuda-toolkit-11*:=
		)
	)
	cuda_targets_sm_62? (
		|| (
			=dev-util/nvidia-cuda-toolkit-11*:=
		)
	)
	cuda_targets_sm_70? (
		|| (
			=dev-util/nvidia-cuda-toolkit-11*:=
		)
	)
	cuda_targets_sm_72? (
		|| (
			=dev-util/nvidia-cuda-toolkit-11*:=
		)
	)
	cuda_targets_sm_75? (
		|| (
			=dev-util/nvidia-cuda-toolkit-11*:=
		)
	)
	cuda_targets_sm_80? (
		|| (
			=dev-util/nvidia-cuda-toolkit-11*:=
		)
	)
	hwloc? (
		>=sys-apps/hwloc-2.5:0=[${MULTILIB_USEDEP}]
	)
	llvm_targets_AMDGPU? (
		|| (
			$(gen_amdgpu_rdepend)
		)
	)
	llvm_targets_NVPTX? (
		<dev-util/nvidia-cuda-toolkit-11.3
	)
	offload? (
		dev-libs/libffi:=[${MULTILIB_USEDEP}]
		virtual/libelf:=[${MULTILIB_USEDEP}]
		~sys-devel/llvm-${PV}[${MULTILIB_USEDEP}]
		llvm_targets_AMDGPU? (
			rocm_4_3? (
				sys-devel/clang:13[rocm_4_3]
			)
			rocm_4_5? (
				sys-devel/clang:13[rocm_4_5]
			)
		)
	)
	rpc? (
		>=net-libs/grpc-1.49.3:=[cxx]
		dev-libs/protobuf:0/3.21
	)
"
# Tests:
# - dev-python/lit provides the test runner
# - sys-devel/llvm provide test utils (e.g. FileCheck)
# - sys-devel/clang provides the compiler to run tests
DEPEND="
	${RDEPEND}
"
BDEPEND="
	dev-lang/perl
	offload? (
		llvm_targets_AMDGPU? (
			sys-devel/clang
		)
		llvm_targets_NVPTX? (
			sys-devel/clang
		)
		virtual/pkgconfig
	)
	test? (
		$(python_gen_any_dep '
			dev-python/lit[${PYTHON_USEDEP}]
		')
		sys-devel/clang
	)
"
RESTRICT="
	!test? (
		test
	)
"
LLVM_COMPONENTS=(
	"openmp"
	"llvm/include"
)
LLVM_PATCHSET="${PV/_/-}"
llvm.org_set_globals
PATCHES=(
	"${FILESDIR}/${PN}-13.0.1-sover-suffix.patch"
	"${FILESDIR}/${PN}-15.0.7-path-changes.patch"
)

python_check_deps() {
	python_has_version "dev-python/lit[${PYTHON_USEDEP}]"
}

kernel_pds_check() {
	if use kernel_linux \
		&& kernel_is -lt 4 15 \
		&& kernel_is -ge 4 13 ; then
		local CONFIG_CHECK="~!SCHED_PDS"
		local ERROR_SCHED_PDS="\
PDS scheduler versions >= 0.98c < 0.98i (e.g. used in kernels >= 4.13-pf11
< 4.14-pf9) do not implement sched_yield() call which may result in horrible
performance problems with libomp. If you are using one of the specified
kernel versions, you may want to disable the PDS scheduler."

		check_extra_config
	fi
}

pkg_pretend() {
	kernel_pds_check
}

pkg_setup() {
ewarn "You may need to uninstall =libomp-${PV} first if merge is unsuccessful."
	if use offload ; then
		LLVM_MAX_SLOT="${PV%%.*}"
		llvm_pkg_setup
	else
		LLVM_MAX_SLOT=$((${PV%%.*} + 1))
		llvm_pkg_setup
	fi
	use test && python-any-r1_pkg_setup
einfo
einfo "The hardmask for llvm_targets_AMDGPU in ${CATEGORY}/${PN} can be removed by doing..."
einfo
einfo "mkdir -p /etc/portage/profile"
einfo "echo \"sys-libs/libomp -llvm_targets_AMDGPU\" >> /etc/portage/profile/package.use.force"
einfo "echo \"sys-libs/libomp -llvm_targets_AMDGPU\" >> /etc/portage/profile/package.use.mask"
einfo
	if use rocm_4_3 ; then
		ROCM_SLOT="4.3"
	else
		ROCM_SLOT="4.5"
	fi
	rocm_pkg_setup
}

src_prepare() {
	llvm.org_src_prepare # Already calls cmake_src_prepare
	PATCH_PATHS=(
		"${WORKDIR}/openmp/libompd/src/CMakeLists.txt"
		"${WORKDIR}/openmp/libomptarget/plugins/amdgpu/CMakeLists.txt"
		"${WORKDIR}/openmp/libomptarget/plugins-nextgen/amdgpu/CMakeLists.txt"
		"${WORKDIR}/openmp/runtime/src/CMakeLists.txt"
		"${WORKDIR}/openmp/tools/archer/CMakeLists.txt"
	)
	rocm_src_prepare
}

gen_nvptx_list() {
	if use cuda_targets_auto ; then
		echo "auto"
	else
		local list
		local x
		for x in ${CUDA_TARGETS_COMPAT[@]} ; do
			if use "cuda_targets_${x}" ; then
				list+=";${x/sm_}"
			fi
		done
		list="${list:1}"
		echo "${list}"
	fi
}

multilib_src_configure() {
	# LTO causes issues in other packages building, #870127
	filter-lto

	# LLVM_ENABLE_ASSERTIONS=NO does not guarantee this for us, #614844
	use debug || local -x CPPFLAGS="${CPPFLAGS} -DNDEBUG"

	local libdir="$(get_libdir)"
	local mycmakeargs=(
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}/usr/lib/llvm/${LLVM_MAJOR}"
	# Disable unnecessary hack copying stuff back to srcdir. \
		-DLIBOMP_COPY_EXPORTS=OFF
		-DLIBOMP_HEADERS_INSTALL_PATH="${EPREFIX}/usr/lib/llvm/${LLVM_MAJOR}/include"
		-DLIBOMP_INSTALL_ALIASES=ON # For binary packages
		-DLIBOMP_OMPT_SUPPORT=$(usex ompt)
		-DLIBOMP_USE_HWLOC=$(usex hwloc)
		-DLLVM_VERSION_MAJOR="${PV%%.*}"
		-DOPENMP_LIBDIR_SUFFIX="${libdir#lib}"
	)

	if use offload && has "${CHOST%%-*}" aarch64 powerpc64le x86_64 ; then
		mycmakeargs+=(
			-DCMAKE_DISABLE_FIND_PACKAGE_CUDA=$(usex !cuda)
			-DLIBOMPTARGET_BUILD_AMDGCN_BCLIB=$(usex llvm_targets_AMDGPU)
			-DLIBOMPTARGET_BUILD_NVPTX_BCLIB=$(usex llvm_targets_NVPTX)
			-DLIBOMPTARGET_ENABLE_EXPERIMENTAL_REMOTE_PLUGIN=$(usex rpc)
	# A cheap hack to force clang. \
			-DLIBOMPTARGET_NVPTX_CUDA_COMPILER="$(type -P "${CHOST}-clang")"
	# Upstream defaults to looking for it in clang dir.  This fails when
	# ccache is being used. \
			-DLIBOMPTARGET_NVPTX_BC_LINKER="$(type -P llvm-link)"
			-DOPENMP_ENABLE_LIBOMPTARGET=ON
		)
		if use llvm_targets_AMDGPU ; then
			mycmakeargs+=(
				-DLIBOMPTARGET_AMDGCN_GFXLIST=$(get_amdgpu_flags)
			)
		fi
		if use llvm_targets_NVPTX ; then
			mycmakeargs+=(
				-DLIBOMPTARGET_NVPTX_COMPUTE_CAPABILITIES=$(gen_nvptx_list)
			)
		fi
		if use ppc64 && ( use llvm_targets_AMDGPU || use llvm_targets_NVPTX ) ; then
			if ! [[ "${CHOST}" =~ "powerpc64le" ]] ; then
eerror
eerror "Big endian is not supported for ppc64 for offload.  Disable either the"
eerror "offload, llvm_targets_AMDGPU, llvm_targets_NVPTX USE flag(s) to"
eerror "continue."
eerror
				die
			fi
		fi
	else
		mycmakeargs+=(
			-DCMAKE_DISABLE_FIND_PACKAGE_CUDA=ON
			-DLIBOMPTARGET_BUILD_AMDGCN_BCLIB=OFF
			-DLIBOMPTARGET_BUILD_NVPTX_BCLIB=OFF
			-DLIBOMPTARGET_ENABLE_EXPERIMENTAL_REMOTE_PLUGIN=OFF
			-DOPENMP_ENABLE_LIBOMPTARGET=OFF
		)
	fi

	use test && mycmakeargs+=(
	# This project does not use standard LLVM cmake macros.
		-DOPENMP_LIT_ARGS="$(get_lit_flags)"
		-DOPENMP_LLVM_LIT_EXECUTABLE="${EPREFIX}/usr/bin/lit"
		-DOPENMP_TEST_C_COMPILER="$(type -P "${CHOST}-clang")"
		-DOPENMP_TEST_CXX_COMPILER="$(type -P "${CHOST}-clang++")"
	)
	addpredict /dev/nvidiactl
	cmake_src_configure
}

multilib_src_test() {
	# Respect TMPDIR!
	local -x LIT_PRESERVES_TMP=1
	cmake_build check-libomp
}
