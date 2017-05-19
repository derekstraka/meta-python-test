#!/bin/bash

# Grab the MACHINE from the environment; otherwise, set it to a sane default
export MACHINE="${MACHINE-qemux86-64}"

# What to build
BUILD_TARGETS=`find poky/meta-openembedded/meta-python -name '*.bb' | xargs -n1 basename | grep -v systemd | cut -d '_' -f 1 | tr '\n' ' '`

die() {
    echo "$*" >&2
    exit 1
}

rm -f build/conf/bblayers.conf || die "failed to nuke bblayers.conf"
rm -f build/conf/local.conf || die "failed to nuke local.conf"

mkdir -p artifacts

./scripts/containerize.sh "bitbake ${BUILD_TARGETS} -c checkpkg && cp tmp/log/checkpkg.csv ../artifacts/python-packages-checkpkg.csv"
./scripts/containerize.sh bitbake -k ${BUILD_TARGETS} || die "failed to build"

