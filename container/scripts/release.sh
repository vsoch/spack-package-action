#!/bin/bash

set -e

# Setup the spack environment
. ${SPACK_ROOT}/share/spack/setup-env.sh 


# Login to GitHub packages
echo ${GITHUB_TOKEN} | docker login -u ${GITHUB_ACTOR} --password-stdin ghcr.io

# Default to name package the same as GitHub repository
PACKAGE_NAME=${GITHUB_REPOSITORY}

# And if we have a package name, add it
if [ ! -z "${INPUT_PACKAGE_NAME}" ]; then
    PACKAGE_NAME=${GITHUB_REPOSITORY}/${INPUT_PACKAGE_NAME}
fi

# Push for all container tags
docker push --all-tags ghcr.io/${PACKAGE_NAME}

echo "container=${PACKAGE_NAME}" >> "${GITHUB_OUTPUT}"
echo "tag=${INPUT_TAG}" >> "${GITHUB_OUTPUT}"
echo "commit=${GITHUB_SHA}" >> "${GITHUB_OUTPUT}"
