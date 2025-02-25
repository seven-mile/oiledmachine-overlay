# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{9..10} )

inherit cmake python-single-r1

if [[ ${PV} == *9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/wdas/partio.git"
else
	SRC_URI="https://github.com/wdas/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="amd64 ~arm ~arm64 ~ppc64 ~x86"
fi

DESCRIPTION="Library for particle IO and manipulation"
HOMEPAGE="http://partio.us/"
LICENSE="BSD"
RESTRICT="test"
SLOT="0"
IUSE="doc test"
REQUIRED_USE="
	${PYTHON_REQUIRED_USE}
"
# U 22.04
RDEPEND="
	${PYTHON_DEPS}
	>=media-libs/freeglut-2.8.1
	>=media-libs/glu-9.0.2
	>=sys-libs/zlib-1.2.11
	virtual/opengl
"
DEPEND="
	${RDEPEND}
"
BDEPEND="
	>=dev-lang/swig-4.0.2
	doc? (
		>=app-doc/doxygen-1.9.1
		dev-texlive/texlive-bibtexextra
		dev-texlive/texlive-fontsextra
		dev-texlive/texlive-fontutils
		dev-texlive/texlive-latex
		dev-texlive/texlive-latexextra
	)
	test? (
		dev-cpp/gtest
	)
"

src_configure() {
	local mycmakeargs=(
		$(cmake_use_find_package doc Doxygen)
	)
	cmake_src_configure
}
