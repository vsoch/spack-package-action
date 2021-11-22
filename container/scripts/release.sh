#!/bin/bash

set -e

# Setup the spack environment
. ${INPUT_ROOT}/share/spack/setup-env.sh 


# Login to GitHub packages
echo ${GITHUB_TOKEN} | docker login -u ${GITHUB_ACTOR} --password-stdin ghcr.io

# Push for all container tags
docker push --all-tags ghcr.io/${GITHUB_REPOSITORY}/${INPUT_PACKAGE_NAME}

echo "::set-output name=container::${GITHUB_REPOSITORY}/${INPUT_PACKAGE_NAME}"
echo "::set-output name=tag::${INPUT_TAG}"
echo "::set-output name=commit::${GITHUB_SHA}"
