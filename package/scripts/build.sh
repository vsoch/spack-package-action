#!/bin/bash

set -e

echo $PWD
ls 


# Setup the spack environment
. /opt/spack/share/spack/setup-env.sh 

# Create package in spack's repos
PACKAGE_PATH=/opt/spack/var/spack/repos/builtin/packages/${INPUT_PACKAGE_NAME}
export SPACK_ROOT=/opt/spack
export SPACK_ADD_DEBUG_FLAGS=true

# Start to formulate spack install command
SPACK_SPEC="${INPUT_PACKAGE_NAME}"

# Show user all variables for debugging
printf "package: ${INPUT_PACKAGE_NAME}\n"
printf "package_custom_path: ${INPUT_PACKAGE_PATH}\n"
printf "package_path: ${PACKAGE_PATH}\n"
printf "flags: ${INPUT_FLAGS}\n"
printf "spec: ${SPACK_SPEC}\n"

# Do we want a custom compiler / variants?
if [ ! -z ${INPUT_FLAGS} ]; then
    SPACK_SPEC="$SPACK_SPEC ${INPUT_FLAGS}"
fi

function install_custom_package() {

    # Retrieve inputs - the spec, package.py dest, and source
    SPACK_SPEC="$1"
    PACKAGE_PATH="$2"
    INPUT_PACKAGE_PATH="$3"

    mkdir -p ${PACKAGE_PATH}
    # Copy all files in the directory
    srcdir=$(dirname ${INPUT_PACKAGE_PATH})
    for filename in $(ls $srcdir); do
        name=$(basename $filename)
        src=$srcdir/$name
        dest=$PACKAGE_PATH/$name
        printf "Copying $src to $dest\n"
        cp $src $dest
    done

    # Create and activate an environment here!
    # This assumes code at the root. The package.py should account for it
    spack env create -d .
    spack env activate .

    # This adds metadata for the package to spack.yaml
    spack develop --path . ${SPACK_SPEC}

    # ...but we need spack add to add to the install list!
    spack add ${SPACK_SPEC}
    spack --debug install        
    echo $?
}

# Case 1: the package directory exists and we don't have a custom package.py
if [ -d "${PACKAGE_PATH}" ] && [ -z "${INPUT_PACKAGE_PATH}" ]; then
    printf "Package name provided and not custom package.py, will install default package.\n"
    COMMAND="spack install $SPACK_SPEC"
    printf "$COMMAND\n"
    ${COMMAND}    
    echo $?

# Case 2: the package directory exists and we DO have a package.py
# We assume the code is in the repository
elif [ -d "${PACKAGE_PATH}" ] && [ ! -z "${INPUT_PACKAGE_PATH}" ]; then
    printf "Package name provided that exists and a custom package.py, will install custom package.\n"
    rm -rf ${PACKAGE_PATH}
    install_custom_package "${SPACK_SPEC}" "${PACKAGE_PATH}" "${INPUT_PACKAGE_PATH}"

# Case 3: the package directory doesn't exist and we have a custom package.py
# We also assume the code is in the repository
elif [ -d "${PACKAGE_PATH}" ] && [ ! -z "${INPUT_PACKAGE_PATH}" ]; then
    printf "Package name provided that does NOT exist and a custom package.py, will install custom package.\n"
    install_custom_package "${SPACK_SPEC}" "${PACKAGE_PATH}" "${INPUT_PACKAGE_PATH}"

else
    printf "You must either provide a package name (package) OR a custom package path (package_path)\n"
    exit 1
fi

# After install, create and add to build cache
mkdir -p /opt/spack-cache
spack gpg init
spack gpg create "${GITHUB_ACTOR}" "${GITHUB_ACTOR}@users.noreply.github.com"
spack buildcache create -d /opt/spack-cache ${SPACK_SPEC}

# Did we make stuff?
tree /opt/spack-cache

# Set output for spec, and TODO binary to upload/save for next step
echo "::set-output name=spec::${SPACK_SPEC}"
echo "::set-output name=build_cache::/opt/spack-cache"

echo "spec=${spec}" >> $GITHUB_ENV
echo "build_cache=/opt/spack-cache" >> $GITHUB_ENV
