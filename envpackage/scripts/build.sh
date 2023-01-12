#!/bin/bash

set -e

echo $PWD
ls 


# Setup the spack environment
. /opt/spack/share/spack/setup-env.sh 

# The spack yaml must exist
if [ ! -f "${INPUT_SPACK_YAML}" ]; then
    printf "${INPUT_SPACK_YAML} does not exist\n"
    exit
fi

# Show user all variables for debugging
printf "spack_yaml: ${INPUT_SPACK_YAML}\n"
printf "flags: ${INPUT_FLAGS}\n"
printf "spec: ${SPACK_SPEC}\n"

# Do we want a custom compiler / variants?
if [ ! -z ${INPUT_FLAGS} ]; then
    SPACK_SPEC="$SPACK_SPEC ${INPUT_FLAGS}"
fi

# Create the spack environment
envdirname=$(dirname ${INPUT_SPACK_YAML})
cd $envdirname

# And install packages to it
spack env create -d .
spack env activate .
spack install

# After install, create and add to build cache.
# We want the directory to be the YEAR.MONTH (21.05)
month=$(date '+%y.%m')
build_cache=/opt/${month}
mkdir -p $build_cache

# Add the key, stored with buildcache action (we need to do both these things?)
root=$(dirname ${ACTION_ROOT})
spack gpg trust ${root}/buildcache/4A424030614ADE118389C2FD27BDB3E5F0331921.pub
spack gpg init
spack gpg create "${GITHUB_ACTOR}" "${GITHUB_ACTOR}@users.noreply.github.com"

# Install packages. If needed, we can add a variable to customize the string here
spack buildcache create -a -d  ${build_cache} $(spack find --format "{name}/{hash}")

# Did we make stuff?
tree ${build_cache}

# We want to save the .json files for any following step :)
spec_jsons=""

echo "build_cache=${build_cache}" >> "${GITHUB_OUTPUT}"
echo "build_cache_prefix=${build_cache_prefix}" >> "${GITHUB_OUTPUT}"

# There can be more than one thing in the build cache
for spec_json in $(find ${build_cache} -name *.json); do
    printf "${spec_json}\n"
    cat ${spec_json}
    if [[ "${spec_jsons}" == "" ]]; then
        spec_jsons=${spec_json}
    else
        spec_jsons="${spec_jsons},${spec_json}"
    fi
done

# Set output for spec, and TODO binary to upload/save for next step
echo "spec=${SPACK_SPEC}" >> "${GITHUB_OUTPUT}"
echo "spec_jsons=${spec_jsons}" >> "${GITHUB_OUTPUT}"
echo "spec=${SPACK_SPEC}" >> $GITHUB_ENV
echo "spec_jsons=${spec_jsons}" >> $GITHUB_ENV
echo "build_cache=${build_cache}" >> $GITHUB_ENV
echo "build_cache_prefix=${month}/build_cache" >> $GITHUB_ENV
