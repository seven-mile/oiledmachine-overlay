## Contributing ebuilds

### Submissions that are considered for acceptance

1. Enhancements and optimization (PGO, BOLT, algorithms, ...)
2. Fixes and completeness
3. New ebuilds related to
   - Game development (for programmers, for artists, for producers, for musicians)
   - Game libraries
   - Porting games outside of Linux
   - Programmer developer tools
   - Graphic arts
   - Games and gamer tools
   - Electron based apps
   - Emoji related
   - Security
   - AI (Artificial Intelligence)
4. Version bumps
5. Porting to different hardware
6. Automated scripts to speed up updating or bumping of ebuilds

When you submit an ebuild on this overlay exclusively, they will not be
disseminated or searchable in the overlay search engine.  Consider uploading
them to another overlay if you would like them more searchable.

You may send contributions many ways.

Sending them is covered in the following sections below.

### Code review

Difficulty:  Easy

1. Create an issue request.
2. Add the link to the line with the flaw.
3. Describe the flaw.

### Trivial fixes

These are limited to ebuild only changes.

Difficulty:  Easy

1. Create an issue request.
2. Add the patch in the issue request.

### Longer patches

Difficulty:  Easy

1. Create an issue request.
2. Use pastebin or gist to submit a patch(s) or ebuild(s).
3. Link the patch(s) or ebuild(s) to your issue request.

If you submit a ebuild this way, you still need to follow the rules below.

### Pull request

Difficulty:  Hard for noobs, easy for experienced

#### Ebuild guidelines

All ebuilds must conform to specifically 2023 ebuild style guide only recognized
by this overlay.  We do not use the distro recommendations because they are
based on an outdated style guide.

* Coding style:
  - Ebuilds contents must be symmetric/even or ANSI C like code style.
  - The ~90% of the code must be within 80 characters boundary.
    - Long strings need to be hard wrapped.
    - URIs processed by bazel should not be hard wrapped.
  - Constants are capitalized.
  - Variables are lower case and have _ between words.
  - Most strings should be in double quotes.
  - Floats should be in double quotes.
  - Integers do not need to be double quotes.
  - Paths should be completely in double quotes from start to end of the string.
  - Conditional blocks are symmetric.
  - Inline conditionals should only fit in 80 characters.
  - The use of a pipe (|) with command should hard wrap with backslash and
    be the start of the next line.
    (Historically, people got paid per line of code.)
  - The operator should start the new line most of the time, unless better
    symmetric presentation is found.
  - || conditionals in REQUIRED_USE and *DEPENDs must have free alternatives at
    the top of the list and proprietary alternatives at the bottom of the list.
  - Indents are mostly tabs.
  - Sorting is generally ASCII sorted.
    - RDEPEND, DEPEND, BDEPEND, PDEPEND are using an ASCII inspired decision
      tree sort.
    - USE flags in *DEPENDs need to be ASCII sorted.
    - Configure options should be ASCII sorted.
  - Comments should be placed in either column 0 or first tab and no more.
  - If a package has many internal vendored dependencies, the YYYYMMDD of the
    last commit of the third_party or depends folder should be recorded and
    place at the top of the *DEPENDs lists.
  - User output commands (echo/einfo) should be column 0 and only 80 characters.
    Additional einfos may follow.
  - You must put `OILEDMACHINE-OVERLAY-EBUILD-FINISHED:  NO` in the footer and
    disable the KEYWORDS variable if the ebuild is unfinished.
  - Phase functions must be sorted in chronological order.
  - Variables in functions must be scoped with the `local` keyword.
  - All user messages printed with einfo/ewarn/errror must be formal.
  - Comments should be mostly formal and unambiguous.
  - metadata.xml longdescription and flags should be formal.
  - *DEPENDs sources should be documented if not centralized.

* Security:
  - The uploaded point release is not vulnerable and does not have security
    advisories.  Use NVD, CVE, GLSA to see if the package is vulnerable.
  - You must edit profile/package.use.force or profile/package.use.mask to hard
    mask the feature or force the alternative if it breaks something or has
    a serious security issue.
  - Daemons/servers must run as limited (non-root) user.
  - Disclose all unreported security weakness in pkg_postinst to allow the
    user to uninstall, hard mask the ebuild, fork and patch locally, or take
    necessary precautions to mitigate.  See the CWE database for weakness
    descriptions.
  - Disclose all critical vulnerabilities in -bin packages including
    internal vendored libraries.
  - Giving write permissions is disallowed if there is a possibility to
    run/inject custom malicious scripts/configs or writable assets between
    different users.
  - If updating micropackages to resolve vulnerability issues, the policy is
    best effort.  This means that you may bump micropackages to later patch
    versions without breaking the software.  Bumping minor or major versions are
    allowed as long the package has been tested and working.  If a test suite is
    provided, you must use it since it has better test coverage than interactive
    testing.
  - Check all password stores during interactive testing for proper hashing.
    Make sure it doesn't do any of the following:
    - [CWE-312](https://cwe.mitre.org/data/definitions/312.html)
      (Storage of passwords in plaintext.  #40 on the most dangerous weakness list.)
    - [CWE-759](https://cwe.mitre.org/data/definitions/759.html)
      (Unsalted passwords)
  - Storing passwords in environment variables is disallowed.
  - JS/Cargo dependency snapshots or SRC_URI lists should be updated monthly or
    weekly.
  - Ebuilds with multiple critical vulnerabilities may be dropped.

* Versioning:
  - If a project has git tags, you may use use `9999`, `<PV>_p9999`,
    `<PV>_pre9999` for live ebuild versions.
  - If a project has git tags, but the distro uses `<PV>_p20230903`, you must
    use `<PV>_p99999999` for live ebuild versions.
  - If a project has no tag (i.e. no point releases), you can use `9999` or
    `99999999` for live ebuild versions.
  - If a project has no tag but the distro uses `20230903`, you must use
    `99999999` for live ebuild versions.

* SRC_URI:
  - The destination filenames in SRC_URI must be prefixed with the project name
    if the source is just version.ext to avoid name collisions.
  - The destination filenames in SRC_URI must be prefixed with the service name
    or repo owner name or other non-colliding salt id if the name has been already
    used or too generic for reuse.  For example a rust/js tarball may use the name
    and version as a c/c++ tarball.  The distro repo or previous tarball name has
    right of way.

* Live ebuilds:
  - Live ebuilds must have KEYWORDS disabled or removed.
  - Live ebuild snapshots should have KEYWORDs disabled or removed.
  - Live ebuilds should disable analytics/telemetry in the build system.
  - Live commits should have a `fallback-commit` USE flag that sets EGIT_COMMIT.
    In addition, the YYYYMMDD date of that commit recorded.
  - Live ebuilds should perform versioning checks between the current live
    and the expected live for deterministic builds.
  - For live ebuilds without versioning, it should use fingerprinting.  To
    accomplish this, do the following:
    - Get a list of build files, command line option files, file format
      versions, dependencies, etc.
    - Sort file list.
    - Hash files.
    - Hash the hash.
    - Compare the hash of the hash to ensure determinism in live ebuilds or
      else recommend the `fallback-commit` USE flag.

* Python ebuilds:
  - All python dependencies must have either PYTHON_USEDEP or PYTHON_SINGLE_USEDEP.
  - For python pacakages, all dependencies must be listed.
  - If a python package does provide a test suite but not through supported
    distutils_enable_tests values like pytest, then src_test() must be
    explicitly defined in the ebuild.
  - You must present the overall summary of the test results in comment form in
    the footer of the ebuild per each unofficially supported python versions.
  - You may not use scripts to auto bump PYTHON_COMPAT.
  - The PYTHON_COMPAT may be downgraded if no recept from the test suite run
    is not presented in the footer.
  - List officially supported versions (listed in setup.py, CI, etc) + python
    versions that you have tested through the test suite.  Do not put versions
    that were not tested by either you or by upstream.
  - Only 2 minor stable versions of Python are supported in this overlay.
    So currently 3.10, 3.11.
  - If the test suite cannot support one of the last 2 minor stable versions,
    the ebuild will be deleted along with the dependencies.

* JS packages:
  - Use the npm_updater_update_locks.sh to update dependencies and produce a
    lockfile.
  - Both yarn and npm offline install support has been added in the eclass
    level, but it is preferred to use npm to avoid problems.
  - Update the lock files for js app packages that has not bumped the patch
    version within one month.  If the package has not been bumped for more than
    a year, it is a hard requirement.  JS packages with criticial dependencies
    must be updated.  JS ebuilds with dependencies reporting "No fix available"
    during audit fix may be deleted.

* C/C++ ebuilds:
  - Ebuilds should be Prefix aware for C/C++ programs.
    - Use "${ESYSROOT}/usr/include" as a source.
    - Use "${ESYSROOT}/usr/$(get_libdir)" as a source.
    - Use "${EPREFIX}/" as destination.
    - Use of prefix USE flags.
      [kernel USE flags](https://packages.gentoo.org/useflags/kernel_linux)
      [libc USE flags](https://packages.gentoo.org/useflags/elibc_glibc)
    - etc...
  - Adding multilib is optional for decade 2020 in this overlay and may be dropped
    in this decade.  If multilib is provided in the package, all dependencies must
    use MULTILIB_USEDEP if the dependency is capable of using it.  For python
    dependencies, it must not have it.  It is not recommended to support multilib
    because a distro core developer wanted it
    [retired](https://blogs.gentoo.org/mgorny/2021/06/03/retiring-the-multilib-project/).
    Also, there is concern of overflows for array indices because of the lack
    of asan overflow testing.
  - For apps, if Wayland support is possible or mentioned in the build files, it
    should be made available as a USE flag.  Wayland should have higher priority
    than X in || checks.  If an app package supports both but is not automatic,
    then a wrapper may provided by the ebuild.  For decade 2020, use of X may
    likely decline.
  - For C/C++ packages, all dependencies for Linux must be listed.
  - For extra/optional dependencies, you do not need to package it but it is
    strongly recommended for a higher quality release and to improve the
    ebuild ecosystem so that Linux doesn't suck.  In other words, you may package
    optional features you like but skip over things you don't want.  The
    unpackaged dependencies should have a TODO list within the ebuild of packages
    that are missing in the ebuild ecosystem.  Incomplete dependencies relates to
    the package default USE flag features breaking also.
  - Adding src_test and test *DEPENDs for C/C++ libraries is optional, but
    highly recommended and may be required in the future in this overlay.

* USE flags:
  - USE flags should be hyphenated between words most of the time.
    Underscores can used by USE flags in profiles/desc.
  - Adding the test USE flag and test dependencies is required for
    dev-python in this overlay only if the package supports testing.
  - If an ebuild can be trivially PGOed, then it is highly recommended to
    add tpgo USE flag or use the build script's pgo.
  - The default IUSE must mostly respect upstream defaults by prefixing
    `+` or `-` in front of the USE flag.  You may go against upstream defaults
    if the setting is not platform agnostic or would likely lead to
    breakage.

* Quality, time limits, optional, extent of support:
  - If a dependency package is for hardware that you do not have access to,
    you do not need to package it.
  - If a dependency exists on other overlay(s), you do not need to submit it for
    review.
  - If a dependency package is not available on any overlay but is required, you
    must package it, version bump it, or patch the software to disable/meet the
    hard requirement.
  - The dependency versioning must be explicit if versioning details are
    available.
  - If *DEPENDs versioning is not available in build files, the fallback for
    is the CI logs for that particular point release or that particular
    major.minor version from the oldest LTS distro.
  - The package should also be polished as much as possible.  This means to
    disable options or patch the code so that it is either is feature complete
    or completely disables/hides the early (buggy) implementation.  Upstream
    commit patches or ones produced by you that address encountered issues or
    encountered bugs may be added.
  - The ebuilds must be tractable for 1 machine.  This means that if a package 
    requires 400 machines, you must build it in a way that it works for one
    machine by either providing prebuilt package(s) or disabling that feature
    that requires this as a requirement.  You may encounter this for machine
    learning so do your research.
  - The ebuilds must be built in reasonable time.  This means that if a package
    is monolthic or forced unconditionally with too many flag bloat, it needs
    to be patched so that it build files are more modular and these hard coded
    {c,cxx,ld}flag options are optional.
  - Assuming -O2 and minimal install:
    - Tiny packages may be emerged in less than 30 seconds or less.
    - Small packages may be emerged in less than 30 minutes or less.
    - Medium packages may be emerged in 1-2 hrs or less.
    - Large packages may be emerged in 19 hrs or less.
    Again, if longer, the package should use more system packages instead.
  - Increasing the time cost beyond a day may decrease security by blocking
    security updates.  Some security standards require critical updates be
    applied within 24 hours.
  - Do not abuse the use of profile/package.use.force or
    profile/package.use.mask to force unnecessary USE flags that require
    400 machines, or require more than 36 hours to build the package,
    or any hidden agenda to non-free.
  - Do not abuse opt in default to non-free (by deleting USE flags or by
    negligence).  If an opt out to non-free features is possible, it must
    be made available.
  - Packages that have active Long Term Support (LTS) support should have
    versions available support it if the LTS versions are widely used with
    multislot support.  If two popular apps use different major LTS versions of
    a library, then the library package should support both.  If a library is
    guaranteed backwards compatible, then it is not needed and you may just use
    0 for the SLOT.
  - You must not increase the time cost that it may decrease security by
    blocking security updates.
  - If a package is orphaned in this overlay, it may be dropped.

* Multislot:
  - SLOT are up to the ebuild (SLOT="slot/subslot"), but recommened for
    packages where there is difficultly updating or the API/interface has
    changed dramatically when updating to the next major or minor version.
    Both the slot and subslot should be easy to remember and apply.  Most
    packages will use the explicit default.
    Common schemes:
    - slot:  0 (default), stable, branch names, major versions, major.minor versions
    - subslot:  major.minor version, current - age, empty (default)
  - There must be a way to avoid slot file collisions typically conditionally
    or by renaming if multislotted.
  - Switching slots is typically done with either a muxer or handled upstream
    via preprocessor symbols and different installation paths for major
    versions.
    - eselect as the muxer is recommended for drop in replacement forks,
      or handling multiple symlinks to headers/exes.
    - a wrapper script as a muxer is recommended for exe only packages.
    - PATH manipulation typically done by eclasses
    - PATH prioritization to symlinks in for example ${WORKDIR}/bin.  (Uncommon)

* Ebuild End of Life (EOL):
  - If you are going to keep EOL slots/versions, put the reason why as a comment
    in the footer or near the header.
    - Good reasons:
      - Test dependency for package X
      - Active project X still uses it
      - Still use it with YYYYMMDD timestamp [renew/rechecked ever year]
      - Orphan but for future use
    - Bad reasons:
      - Orphaned [delete]
      - Blank [deleted because EOL]
  - Packages that rely on EOL versions and not stable versions of python, gcc,
    and do not have a stable slot or stable version from the distro overlay
    and this overlay are not supported and can be deleted.  For example, if
    an ebuild needs on python 2.7 but cannot support python 3 or be patched
    to support python 3 or disable that requirement, it will be deleted.

* eclass rules:
  - All `.eclass`es must be GPL2 only or have a GPL2 compatible license header.
  - All `.eclass`es have the basic headers rows @ECLASS, @MAINTAINER, 
    @SUPPORTED_EAPIS, @BLURB, @DESCRIPTION.
  - All public functions must have the following @FUNCTION, @DESCRIPTION,
    and the same prefix matching the filename without extension.
  - All internal functions must have @INTERNAL and be prefixed with _.
  - All eclass variables and globals must have the following
    @ECLASS_VARIABLE, @DESCRIPTION
  - All eclasses must have EAPI compatibility switch-case or conditional
    check.
  - Eclasses need to support either EAPI 7 or EAPI 8

* Licenses:
  - All `.ebuild`s must be GPL2 only or have a GPL2 compatible license header.
  - You may add your name to the license header, or AUTHORS.md of the root of
    the overlay, or remain anonymous.
  - Attach custom licenses to the license folder.
  - The licenses of all vendored internal dependencies should be disclosed in
    the LICENSE variable.
  - If the license header says all rights reserved but the license does not
    have it in the license template, it should be disclosed.
  - All patents licenses should be disclosed and should be free.
  - If a license says copyright notices must be preserved, then the license
    file or that header containing that copyright notice should be saved.
    Use the `lcnr` eclass or see
    [header-preserve-kernel](https://github.com/orsonteodoro/oiledmachine-overlay/blob/master/sys-kernel/ot-sources/files/header-preserve-kernel)
    script to accomplish this.  You may want to use the lcnr eclass when
    dealing with micropackages.
  - For patches, the terms of the licenses must be met.
    - Read and follow 4 of the Apache-2.0 license if the project uses that license.
    - Read and follow 3.3 of the MPL-1.0 license if the project uses that license.
    - Read and follow 3.3 of the MPL-1.1 license if the project uses that license.
  - For NOTICES* and PATENTS* files must be made available in install if the
    build scripts did not install them.
  - You must follow the license terms.
  - All variations of the license must be documented in the LICENSE variable.
  - If it appears to be a license incompatibility, document the name of the
    license and at least one path to the license file or the path to the
    source/header file relative to S, WORKDIR, or HOME.
    - If possible, try to unvendor or modify the build files to prevent
      license incompatibility.
  - Refrain from using non free trademarks.

* metadata.xml:
  - Everything is space indented.
  - Generally indents are two spaces.
  - Tags are symmetric.
  - Contents are symmetric.
  - Instructions should be in comments.
  - longdescription is only promo.
  - Do not put personal info or *marks if project is BSDed.
  - If the project is ZLIBed, you must clearly put that you made
    the ebuild and not the project that you are packaging.

* Uploading:
  - You may submit many ebuilds at the same time, but do not send more than
    a reasonable amount.
  - It is better to send one package folder at a time.

* Code review checklist:
  - Header copyright notices
  - License files for free open source compatibility
  - Patches conform to project license terms.
  - The URIs will be reviewed for https, trust, and file naming collisions.
  - ASCII sorted configure, *DEPENDs, IUSE, REQUIRED_USE, etc.
  - Each and every ebuild, patches, and other files will be manually checked for
    security.
  - File permissions and ownership.
  - The project licenses will be reviewed.
  - All eclasses are inspected for comprehensive documentation.
  - Vulnerability database checks for each submitted package.
  - The security of init scripts if any.
  - Multislot file collisions

#### Uploading to this repo

1. Fork the repo
2. Create a feature branch
3. Make changes to the feature branch
4. Follow and create a
[pull request from a fork](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request-from-a-fork).
5. In your pull request state the following:
   - The purpose/summary.
   - Estimate of how long you expect to finish.
     - Do not exceed a week.
     - For scheduled updates like ot-kernel eclass, you are only allowed
       8 hours.
   - State all `<category>/<package>` or paths that you will be editing so we
     avoid merge conflicts.
6. After the merges are done, you may delete the feature branch and forked repo.

#### Rejected pull requests

Your pull request may be rejected for reasons below:

1. The ebuilds were planned earlier for removal because the upstream project is
   end of life (EOL).
2. Security reasons.
   - The point release is vulnerable and will be replaced with a non-vulnerable.
   - Project owners have a questionable background.
   - The project credibility is in question.
3. Exceeded time limits.
   - Submissions are to be evaluated and merged no more than a week.
   (The reason is that I may edit the whole thing or whole category).
   - For submissions that edit scheduled updates like ot-kernel eclass, you are
     only allowed 8 hours.
4. Licensing rejections.
   - The license has overtones of non free is rejected.
   - No code repository and with explicit UNKNOWN is rejected.
5. Code review checklist violations.

#### Deleted ebuilds

Your ebuilds may be deleted for the following reasons:

1. No bumps for 6 months [considered sometimes EOL] to 10 years.
2. The branch/project is is EOL.
3. A better alternative with duplicated functionality.
4. Improved fork.
5. Clearly pre alpha when better alternatives exists.
6. The minor branch is older than 2 relative to the current version, except
when they are needed for testing.

## Overlay maintainers

Spots for overlay maintainers are available.  Due to security reasons, extra
level of qualification standards and checks are required.

You need at least one of the following to qualify:

1. You have an open source project on a well known repo service.
2. We have met in person.
3. Brief interview over voice with a demo of your project on a video sharing
site and code samples.
4. You were an overlay maintainer.

### Skills required

1. git command line experience (or prior experience with version control
and willing to learn git)
2. Shell scripting
3. Ebuild experience
4. Experience with this distro
5. Experience with creating patch files
6. Be able to follow the terms and obligations of the project licenses.
