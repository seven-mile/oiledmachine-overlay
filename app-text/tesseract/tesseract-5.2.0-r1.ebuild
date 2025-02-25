# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# DO NOT REMOVE.   5.2.0 is kept for dev-dotnet/tesseract.

inherit autotools multilib-minimal toolchain-funcs

DESCRIPTION="An OCR Engine, originally developed at HP, now open source"
HOMEPAGE="https://github.com/tesseract-ocr"
SRC_URI="https://github.com/tesseract-ocr/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0/5"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~mips ~ppc ~ppc64 ~riscv ~sparc ~x86"
IUSE="doc float32 jpeg opencl openmp png static-libs tiff training webp"

CDEPEND="
	>=media-libs/leptonica-1.74:=[${MULTILIB_USEDEP},jpeg?,png?,tiff?,webp?,zlib]
	opencl? (
		virtual/opencl[${MULTILIB_USEDEP}]
		media-libs/tiff:=[${MULTILIB_USEDEP}]
		media-libs/leptonica:=[tiff]
	)
	training? (
		dev-libs/icu:=
		x11-libs/pango:=
		x11-libs/cairo:=
	)
"
RDEPEND="
	${CDEPEND}
	|| (
		>=app-text/tessdata_fast-4.0.0
		>=app-text/tessdata_best-4.0.0
		>=app-text/tessdata_legacy-4.0.0
	)
"
DEPEND="
	${CDEPEND}
	app-text/asciidoc
	app-text/docbook-xsl-stylesheets
	dev-libs/libxslt
	doc? (
		app-doc/doxygen
	)
"

pkg_pretend() {
	[[ ${MERGE_TYPE} != binary ]] && use openmp && tc-check-openmp
}

pkg_setup() {
	[[ ${MERGE_TYPE} != binary ]] && use openmp && tc-check-openmp
}

src_prepare() {
	default
	eautoreconf
}

multilib_src_configure() {
	# Scrollview is disabled for now, see bug #686944
	local myeconfargs=(
		$(use_enable float32)
		$(use_enable opencl)
		$(use_enable openmp)
		$(use_enable static-libs static)
		--disable-graphics
		--enable-shared
	)

	ECONF_SOURCE="${S}" econf "${myeconfargs[@]}"
}

multilib_src_compile() {
	default
	if multilib_is_native_abi; then
		use doc && emake doc
		use training && emake training
	fi
}

multilib_src_install() {
	if multilib_is_native_abi; then
		DOCS=(
			"${S}/AUTHORS"
			"${S}/ChangeLog"
			"${S}/README.md"
		)
		if use doc; then
			HTML_DOCS=( doc/html/. )
		fi
		einstalldocs

		if use training; then
			emake DESTDIR="${D}" training-install
		fi
	fi
	emake DESTDIR="${D}" install
}

multilib_src_install_all() {
	find "${D}" -name '*.la' -type f -delete || die
}
