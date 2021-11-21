#!/bin/bash

set -e

echo $PWD
ls 

# Setup the spack environment
. /opt/spack/share/spack/setup-env.sh 

# Create package in spack's repos
PACKAGE_PATH=/opt/spack/repos/builtin/packages/${INPUT_PACKAGE_NAME}

# Start to formulate spack install command
SPACK_SPEC="${INPUT_PACKAGE_NAME}"

# Do we want a custom compiler / variants?
if [ -d ${INPUT_FLAGS} ]; then
    SPACK_SPEC="$SPACK_SPEC ${INPUT_FLAGS}"
fi

# Case 1: the package directory exists and we don't have a package.py
if [ -d ${INPUT_PACKAGE_NAME} ] && [ -z "${INPUT_PACKAGE_PATH}" ]; then
    printf "Package name provided and not custom package.py, will install default package.\n"
    COMMAND="spack install $SPACK_SPEC"
    printf "$COMMAND\n"
    ${COMMAND}    
    echo $?

# Case 2: the package directory exists and we DO have a package.py
# We assume the code is in the repository
elif [ -d ${INPUT_PACKAGE_NAME} ] && [ ! -z "${INPUT_PACKAGE_PATH}" ]; then
    printf "Package name provided that exists and a custom package.py, will install custom package.\n"
    rm -rf ${PACKAGE_PATH}
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
fi

# After install, create and add to build cache
mkdir -p /opt/spack-cache
spack buildcache create -d /opt/spack-cache ${SPACK_SPEC}

# Did we make stuff?
tree /opt/spack-cache
