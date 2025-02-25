# Copyright 2022-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# This is the python portion of the package.

AMDGPU_TARGETS_COMPAT=(
	gfx900
	gfx906
	gfx908
)
CUDA_TARGETS_COMPAT=(
# Builds for all cards
	auto

# Observed:
	#sm_35 # Dropped based on RELEASE.md:  Release Compatibility Matrix
	sm_50_plus_ptx
	sm_52
	sm_60
	sm_61
	sm_70
	sm_70_plus_ptx
	sm_75
	sm_80
	sm_86
)
AMDGPU_TARGETS_USEDEP=("${AMDGPU_TARGETS_COMPAT[@]/#/amdgpu_targets_}")
AMDGPU_TARGETS_USEDEP=("${AMDGPU_TARGETS_USEDEP[@]/%/?}")
AMDGPU_TARGETS_USEDEP="${AMDGPU_TARGETS_USEDEP[@]}"
AMDGPU_TARGETS_USEDEP="${AMDGPU_TARGETS_USEDEP// /,}"
CUDA_TARGETS_USEDEP=("${CUDA_TARGETS_COMPAT[@]/#/cuda_targets_}")
CUDA_TARGETS_USEDEP=("${CUDA_TARGETS_USEDEP[@]/%/?}")
CUDA_TARGETS_USEDEP="${CUDA_TARGETS_USEDEP[@]}"
CUDA_TARGETS_USEDEP="${CUDA_TARGETS_USEDEP// /,}"
DISTUTILS_USE_PEP517="setuptools"
PYTHON_COMPAT=( python3_10 ) # Upstream only allows <= 3.10
DISTUTILS_SINGLE_IMPL=1

inherit distutils-r1 rocm

SRC_URI="
https://github.com/pytorch/${PN}/archive/refs/tags/v${PV}.tar.gz
	-> ${P}.tar.gz
"

DESCRIPTION="Tensors and Dynamic neural networks in Python"
HOMEPAGE="https://pytorch.org/"
LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64"
IUSE="
${CUDA_TARGETS_COMPAT[@]/#/cuda_targets_}
${ROCM_IUSE}
cuda rocm
"
gen_cuda_required_use() {
	local x
	for x in ${CUDA_TARGETS_COMPAT[@]} ; do
		echo "
			cuda_targets_${x}? (
				cuda
			)
		"
	done
}
gen_rocm_required_use() {
	local x
	for x in ${AMDGPU_TARGETS_COMPAT[@]} ; do
		echo "
			amdgpu_targets_${x}? (
				rocm
			)
		"
	done
}
REQUIRED_USE="
	$(gen_cuda_required_use)
	$(gen_rocm_required_use)
	cuda? (
		|| (
			${CUDA_TARGETS_COMPAT[@]/#/cuda_targets_}
		)
	)
	rocm? (
		${ROCM_REQUIRED_USE}
	)
	${PYTHON_REQUIRED_USE}
"
ROCM_SLOTS=(
# See https://github.com/pytorch/pytorch/blob/v1.13.1/.github/workflows/trunk.yml
	"5.2.0"
)
gen_rocm_depends() {
	local pv
	for pv in ${ROCM_SLOTS[@]} ; do
		local s="0/"$(ver_cut 1-2 ${pv})
		echo "
			(
				~dev-libs/rccl-${pv}:${s}
				~dev-libs/rocm-comgr-${pv}:${s}
				~dev-libs/rocm-core-${pv}:${s}
				~dev-libs/rocr-runtime-${pv}:${s}
				~dev-util/hip-${pv}:${s}[rocm]
				~dev-util/rocprofiler-${pv}:${s}
				~dev-util/roctracer-${pv}:${s}
				~sci-libs/hipCUB-${pv}:${s}[rocm]
				~sci-libs/hipSPARSE-${pv}:${s}[rocm]
				~sci-libs/hipFFT-${pv}:${s}[rocm]
				~sci-libs/miopen-${pv}:${s}[rocm]
				~sci-libs/rocBLAS-${pv}:${s}[rocm]
				~sci-libs/rocFFT-${pv}:${s}[rocm]
				~sci-libs/rocRAND-${pv}:${s}[rocm]
				~sci-libs/rocPRIM-${pv}:${s}[rocm]
				~sci-libs/rocThrust-${pv}:${s}
			)
		"
	done
}
CUDA_PV="11.8" # 11.6 minimum required
RDEPEND="
	$(python_gen_cond_dep '
		dev-python/typing-extensions[${PYTHON_USEDEP}]
	')
	${PYTHON_DEPS}
	~sci-libs/caffe2-${PV}[${AMDGPU_TARGETS_USEDEP},${CUDA_TARGETS_USEDEP},${PYTHON_SINGLE_USEDEP},cuda=,rocm=]
	cuda? (
		cuda_targets_auto? (
			=dev-util/nvidia-cuda-toolkit-${CUDA_PV}*:=
		)
		cuda_targets_sm_50_plus_ptx? (
			=dev-util/nvidia-cuda-toolkit-${CUDA_PV}*:=
		)
		cuda_targets_sm_52? (
			=dev-util/nvidia-cuda-toolkit-${CUDA_PV}*:=
		)
		cuda_targets_sm_60? (
			=dev-util/nvidia-cuda-toolkit-${CUDA_PV}*:=
		)
		cuda_targets_sm_61? (
			=dev-util/nvidia-cuda-toolkit-${CUDA_PV}*:=
		)
		cuda_targets_sm_70? (
			=dev-util/nvidia-cuda-toolkit-${CUDA_PV}*:=
		)
		cuda_targets_sm_70_plus_ptx? (
			=dev-util/nvidia-cuda-toolkit-${CUDA_PV}*:=
		)
		cuda_targets_sm_75? (
			=dev-util/nvidia-cuda-toolkit-${CUDA_PV}*:=
		)
		cuda_targets_sm_80? (
			=dev-util/nvidia-cuda-toolkit-${CUDA_PV}*:=
		)
		cuda_targets_sm_86? (
			=dev-util/nvidia-cuda-toolkit-${CUDA_PV}*:=
		)
		=dev-util/nvidia-cuda-toolkit-${CUDA_PV}*[profiler]
	)
	rocm? (
		|| (
			$(gen_rocm_depends)
		)
	)
"
DEPEND="
	$(python_gen_cond_dep '
		dev-python/pyyaml[${PYTHON_USEDEP}]
	')
	${RDEPEND}
"
BDEPEND="
"
RESTRICT="test"
_PATCHES=(
	"${FILESDIR}/0002-Don-t-build-libtorch-again-for-PyTorch-1.7.1.patch"
	"${FILESDIR}/pytorch-1.9.0-Change-library-directory-according-to-CMake-build.patch"
	"${FILESDIR}/${P}-global-dlopen.patch"
	"${FILESDIR}/pytorch-1.7.1-torch_shm_manager.patch"
	"${FILESDIR}/${PN}-1.13.0-setup.patch"
	"${FILESDIR}/${P}-emptyso.patch"
)

src_prepare() {
	eapply ${_PATCHES[@]}

	# Set build dir for pytorch's setup
	sed -i \
		-e "/BUILD_DIR/s|build|/var/lib/caffe2/|" \
		tools/setup_helpers/env.py \
		|| die
	distutils-r1_src_prepare
}

src_compile() {
	# Python files only
	# For binaries/libs see caffe2
	local pyargs=(
		BUILD_DIR=
		CMAKE_BUILD_DIR="${BUILD_DIR}"
		PYTORCH_BUILD_VERSION="${PV}"
		PYTORCH_BUILD_NUMBER=0
		USE_SYSTEM_LIBS=ON
	)

	"${pyargs[@]}" \
	distutils-r1_src_compile
}

src_install() {
	USE_SYSTEM_LIBS=ON \
	distutils-r1_src_install
}

# OILEDMACHINE-OVERLAY-STATUS:  build-needs-test
# OILEDMACHINE-OVERLAY-EBUILD-FINISHED:  NO
