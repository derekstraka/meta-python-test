#!/bin/bash

# Grab the MACHINE from the environment; otherwise, set it to a sane default
export MACHINE="${MACHINE-qemux86-64}"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. ${SCRIPT_DIR}/generate-targets

die() {
    echo "$*" >&2
    exit 1
}

rm -f build/conf/bblayers.conf || die "failed to nuke bblayers.conf"
rm -f build/conf/local.conf || die "failed to nuke local.conf"

mkdir -p artifacts

${SCRIPT_DIR}/containerize.sh "bitbake ${BUILD_TARGETS} -c checkpkg && cp tmp/log/checkpkg.csv ../artifacts/python-packages-checkpkg.csv"

echo "TCLIBC=\"${TCLIBC}\"" >> build/conf/local.conf

${SCRIPT_DIR}/containerize.sh bitbake -k ${BUILD_TARGETS} || die "failed to build"

${SCRIPT_DIR}/containerize.sh bitbake -k ${NATIVE_BUILD_TARGETS} || die "failed to build native targets"

${SCRIPT_DIR}/generate-images.sh

IMAGE_TARGETS=
for target in ${BUILD_TARGETS}; do
    case "${target}" in
        # Python babel does some bad things with naming modules that override standard ones,
        # so it does not lend itself well to running directly
        #    Traceback (most recent call last):
        #      File "/usr/lib/python3.5/site-packages/babel/localedata.py", line 21, in <module>
        #        from babel._compat import pickle, string_types
        #      File "/usr/lib/python3.5/site-packages/babel/__init__.py", line 20, in <module>
        #        from babel.core import UnknownLocaleError, Locale, default_locale, \
        #      File "/usr/lib/python3.5/site-packages/babel/core.py", line 14, in <module>
        #        from babel import localedata
        #      File "/usr/lib/python3.5/site-packages/babel/localedata.py", line 21, in <module>
        #        from babel._compat import pickle, string_types
        #      File "/usr/lib/python3.5/site-packages/babel/_compat.py", line 65, in <module>
        #        import decimal
        #      File "/usr/lib/python3.5/decimal.py", line 8, in <module>
        #        from _pydecimal import *
        #      File "/usr/lib/python3.5/_pydecimal.py", line 154, in <module>
        #        import numbers as _numbers
        #      File "/usr/lib/python3.5/site-packages/babel/numbers.py", line 25, in <module>
        #        from babel.core import default_locale, Locale, get_global
        #    ImportError: cannot import name 'default_locale'
        python-babel|python3-babel)
            continue
        ;;

        # Python can has several scripts that attempt to blindly load windows modules or execute scripts when called with __main__
        python-can|python3-can)
            continue
        ;;
        python-pylint|python3-pylint|python-flask-*|python3-flask*)
            continue
        ;;
        *)
            sed "s/<TEMPLATE_PACKAGE>/${target}/g" templates/core-image-minimal.bb.template > poky/meta/recipes-core/images/core-image-minimal-plus-${target}.bb
            IMAGE_TARGETS="${IMAGE_TARGETS} core-image-minimal-plus-${target}"
        ;;
    esac
done

${SCRIPT_DIR}/containerize.sh bitbake -k ${IMAGE_TARGETS} || die "failed to build image targets"

${SCRIPT_DIR}/check-python-imports.sh
