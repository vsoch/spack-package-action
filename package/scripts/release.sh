#!/bin/bash

set -e

echo $PWD
ls 

printf "package: ${INPUT_PACKAGE_NAME}\n"
printf "actor: ${GITHUB_ACTOR}\n"
printf "tag: ${INPUT_TAG}\n"


# Setup the spack environment
. "${SPACK_ROOT}/share/spack/setup-env.sh"

# Install oras
curl -LO https://github.com/oras-project/oras/releases/download/v0.12.0/oras_0.12.0_linux_amd64.tar.gz
mkdir -p oras-install/
tar -zxf oras_0.12.0_*.tar.gz -C oras-install/
mv oras-install/oras /usr/local/bin/
rm -rf oras_0.12.0_*.tar.gz oras-install/

# Login to GitHub packages
echo ${GITHUB_TOKEN} | oras login -u ${GITHUB_ACTOR} --password-stdin ghcr.io

# Compress entire build build cache
printf "Creating .tar.gz of spack build cache to upload\n"
tar -czvf spack-package.tar.gz ${BUILD_CACHE}

# Do we have a tag?
if [ -z "${INPUT_TAG}" ]; then
    INPUT_TAG=${GITHUB_SHA}
fi

printf "oras push ghcr.io/${GITHUB_REPOSITORY}/${INPUT_PACKAGE_NAME}:${INPUT_TAG} --manifest-config /dev/null:application/vnd.spack.package ./spack-package.tar.gz\n"
oras push ghcr.io/${GITHUB_REPOSITORY}/${INPUT_PACKAGE_NAME}:${INPUT_TAG} --manifest-config /dev/null:application/vnd.spack.package ./spack-package.tar.gz
