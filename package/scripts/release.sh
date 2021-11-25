#!/bin/bash

set -e

echo $PWD
ls 

printf "build cache prefix: ${BUILD_CACHE_PREFIX}"
printf "build cache: ${BUILD_CACHE}"
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

# Do we have a tag?
if [ -z "${INPUT_TAG}" ]; then
    INPUT_TAG=${GITHUB_SHA:0:8}
fi

# The package name must include the package and hash, etc.
# linux-ubuntu20.04-broadwell-gcc-10.3.0-zlib-1.2.11-5vlodp7yawk5elx4dfhnpzmpg743fwv3.spack
spack_package=$(find ${BUILD_CACHE} -name *.spack)
spack_package_name=$(basename $spack_package)
package_name="${build_cache_prefix}/${spack_package_name}"

printf "oras push ghcr.io/${GITHUB_REPOSITORY}/${package_name}:latest --manifest-config /dev/null:application/vnd.spack.package ${spack_package}\n"

# Push for latest
oras push ghcr.io/${GITHUB_REPOSITORY}/${package_name}:latest --manifest-config /dev/null:application/vnd.spack.package ${spack_package}

# And custom tag (which will default to GITHUB_SHA)
printf "oras push ghcr.io/${GITHUB_REPOSITORY}/${package_name}:${INPUT_TAG} --manifest-config /dev/null:application/vnd.spack.package ${spack_package}\n"
oras push ghcr.io/${GITHUB_REPOSITORY}/${package_name}:${INPUT_TAG} --manifest-config /dev/null:application/vnd.spack.package ${spack_package}
