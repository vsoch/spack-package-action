#!/bin/bash

set -e

echo $PWD
ls 

printf "build cache prefix: ${BUILD_CACHE_PREFIX}"
printf "build cache: ${BUILD_CACHE}"
printf "package: ${INPUT_PACKAGE_NAME}\n"
printf "actor: ${GITHUB_ACTOR}\n"
printf "tag: ${INPUT_TAG}\n"
printf "deploy: ${DEPLOY}\n"

# Setup the spack environment
. "${SPACK_ROOT}/share/spack/setup-env.sh"

# Install oras
curl -LO https://github.com/oras-project/oras/releases/download/v0.12.0/oras_0.12.0_linux_amd64.tar.gz
mkdir -p oras-install/
tar -zxf oras_0.12.0_*.tar.gz -C oras-install/
mv oras-install/oras /usr/local/bin/
rm -rf oras_0.12.0_*.tar.gz oras-install/

# Login to GitHub packages
if [ "${DEPLOY}" == "true" ]; then
    echo ${GITHUB_TOKEN} | oras login -u ${GITHUB_ACTOR} --password-stdin ghcr.io
fi

# Do we have a tag?
if [ -z "${INPUT_TAG}" ]; then
    INPUT_TAG=${GITHUB_SHA:0:8}
fi

# The package name must include the package and hash, etc.
# linux-ubuntu20.04-broadwell-gcc-10.3.0-zlib-1.2.11-5vlodp7yawk5elx4dfhnpzmpg743fwv3.spack
spack_package=$(find ${BUILD_CACHE} -name *.spack)
spack_package_name=$(basename $spack_package)
package_name="${build_cache_prefix}/${spack_package_name}"

# Absolute paths not allowed
mv ${spack_package} ${spack_package_name}

package_full_name=ghcr.io/${GITHUB_REPOSITORY}/${package_name}:latest
package_tagged_name=ghcr.io/${GITHUB_REPOSITORY}/${package_name}:${INPUT_TAG}
package_content_type=application/vnd.spack.package

echo "::set-output name=package_name::${package_full_name}"
echo "::set-output name=package_tagged_name::${package_tagged_name}"
echo "::set-output name=package_content_type::${package_content_type}"
echo "::set-output name=package_tag::${INPUT_TAG}"

echo "package_name=${package_full_name}" >> $GITHUB_ENV
echo "package_tagged_name=${package_tagged_name}" >> $GITHUB_ENV
echo "package_content_type=${package_content_type}" >> $GITHUB_ENV
echo "package_tag=${package_tag}" >> $GITHUB_ENV

# Push for latest
if [ "${DEPLOY}" == "true" ]; then
    printf "oras push ${package_full_name} --manifest-config /dev/null:${package_content_type} ${spack_package_name}\n"
    oras push ${package_full_name} --manifest-config /dev/null:${package_content_type} ${spack_package_name}

    # And custom tag (which will default to GITHUB_SHA)
    printf "oras push ${package_tagged_name} --manifest-config /dev/null:${package_content_type} ${spack_package_name}\n"
    oras push  ${package_tagged_name} --manifest-config /dev/null:${package_content_type} ${spack_package_name}
fi
