# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..11} ) # Upstream only lists up to 3.10
MY_PN="estimator"
MY_PV="${PV}"
MY_P="${MY_PN}-${MY_PV}"
TF_PV=$(ver_cut 1-2 ${PV})

inherit bazel distutils-r1

# Version and commits obtained from console and temporary removal of items below.
RULES_CC_PV="0.0.2"
EGIT_RULES_JAVA_COMMIT="7cf3cefd652008d0a64a419c34c13bdca6c8f178"
bazel_external_uris="
https://github.com/bazelbuild/rules_cc/releases/download/${RULES_CC_PV}/rules_cc-${RULES_CC_PV}.tar.gz
https://github.com/bazelbuild/rules_java/archive/${EGIT_RULES_JAVA_COMMIT}.zip -> bazelbuild-rules_java-${EGIT_RULES_JAVA_COMMIT}.zip
"
SRC_URI="
	${bazel_external_uris}
https://github.com/tensorflow/${MY_PN}/archive/v${MY_PV}.tar.gz -> ${P}.tar.gz
"

DESCRIPTION="A high-level TensorFlow API that greatly simplifies machine learning programming"
HOMEPAGE="https://www.tensorflow.org/"
LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""
# https://github.com/tensorflow/tensorflow/blob/v2.12.0/.bazelversion
RDEPEND="
	=sci-libs/keras-${TF_PV}*[${PYTHON_USEDEP}]
	=sci-libs/tensorflow-${TF_PV}*[${PYTHON_USEDEP},python]
"
DEPEND="
	${RDEPEND}
"
BDEPEND="
	>=dev-util/bazel-5.3.0
	app-arch/unzip
	dev-java/java-config
"
S="${WORKDIR}/${MY_P}"
PATCHES=(
)
DOCS=( CONTRIBUTING.md README.md )

src_unpack() {
	unpack "${P}.tar.gz"
	bazel_load_distfiles "${bazel_external_uris}"
}

src_prepare() {
	bazel_setup_bazelrc
	default
	python_copy_sources
}

python_compile() {
	pushd "${BUILD_DIR}" >/dev/null || die
		ebazel build //tensorflow_estimator/tools/pip_package:build_pip_package
		ebazel shutdown
		local srcdir="${T}/src-${EPYTHON/./_}"
		mkdir -p "${srcdir}" || die
		bazel-bin/tensorflow_estimator/tools/pip_package/build_pip_package \
			--src "${srcdir}" \
			|| die
	popd >/dev/null || die
}

src_compile() {
	export JAVA_HOME=$(java-config --jre-home)
	distutils-r1_src_compile
}

python_install() {
	pushd "${T}/src-${EPYTHON/./_}" >/dev/null || die
		esetup.py install
		python_optimize
	popd >/dev/null || die
}
