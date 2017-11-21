#!/bin/bash

# Grab the MACHINE from the environment; otherwise, set it to a sane default
export MACHINE="${MACHINE-qemux86-64}"

# What to build
BUILD_TARGETS=`find poky/meta-openembedded/meta-python -name '*.bb' | xargs -n1 basename | grep -v systemd | grep -v networkmanager | grep -v blivet | cut -d '_' -f 1 | tr '\n' ' '`

die() {
    echo "$*" >&2
    exit 1
}

rm -f build/conf/bblayers.conf || die "failed to nuke bblayers.conf"
rm -f build/conf/local.conf || die "failed to nuke local.conf"

mkdir -p artifacts

./scripts/containerize.sh "bitbake ${BUILD_TARGETS} -c checkpkg && cp tmp/log/checkpkg.csv ../artifacts/python-packages-checkpkg.csv"

echo "TCLIBC=\"${TCLIBC}\"" >> build/conf/local.conf

./scripts/containerize.sh bitbake -k ${BUILD_TARGETS} || die "failed to build"

# Find all the items that contain a BBCLASSEXTEND for native
CLASS_EXTENDS_RECIPES=`grep -r BBCLASSEXTEND poky/meta-openembedded/meta-python/ | grep native | cut -d ":" -f1 | xargs -n1 basename | grep \.bb$ | cut -d '_' -f 1`
CLASS_EXTENDS_INC=`grep -r BBCLASSEXTEND poky/meta-openembedded/meta-python | grep native | cut -d ":" -f1 | xargs -n1 basename | grep \.inc$ | cut -d '.' -f 1`

NATIVE_BUILD_TARGETS=

for recipe in $CLASS_EXTENDS_RECIPES; do
    NATIVE_BUILD_TARGETS="${NATIVE_BUILD_TARGETS} ${recipe}-native"
done

for inc in $CLASS_EXTENDS_INC; do
    # Strip off the leading 'python-'
    token=`echo $inc | cut -d '-' -f 2-`
    
    py2=`find poky/meta-openembedded/meta-python -name python-${token}_\* | wc -l`
    py3=`find poky/meta-openembedded/meta-python -name python3-${token}_\* | wc -l`

    if [ "$py2" -eq "1" ]; then
        NATIVE_BUILD_TARGETS="${NATIVE_BUILD_TARGETS} python-${token}-native"
    fi

    if [ "$py3" -eq "1" ]; then
        NATIVE_BUILD_TARGETS="${NATIVE_BUILD_TARGETS} python3-${token}-native"
    fi    

done

./scripts/containerize.sh bitbake -k ${NATIVE_BUILD_TARGETS} || die "failed to build native targets"
