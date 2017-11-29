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
    sed "s/<TEMPLATE_PACKAGE>/${target}/g" templates/core-image-minimal.bb.template > poky/meta/recipes-core/images/core-image-minimal-plus-${target}.bb
    IMAGE_TARGETS="${IMAGE_TARGETS} core-image-minimal-plus-${target}"
done

${SCRIPT_DIR}/containerize.sh bitbake -k ${IMAGE_TARGETS} || die "failed to build image targets"

${SCRIPT_DIR}/check-python-imports.sh
