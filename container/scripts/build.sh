#!/bin/bash

set -e

echo $PWD
ls 

# Show user all variables for debugging
printf "package: ${INPUT_PACKAGE_NAME}\n"
printf "spack_yaml: ${INPUT_SPACK_YAML}\n"

# Setup the spack environment
. "${SPACK_ROOT}/share/spack/setup-env.sh"


# If we don't have a spack yaml or package, no go!
if [ -z "${INPUT_SPACK_YAML}" ] && [ -z "${INPUT_PACKAGE_NAME}" ]  ; then
    printf "You must define a spack yaml (spack_yaml) or package name (package)\n"
    exit 1
fi

if [ -z "${INPUT_SPACK_YAML}" ] && [ -z "${INPUT_PACKAGE_NAME}" ]  ; then
    printf "You must define a spack yaml (spack_yaml) or package name (package)\n"
    exit 1
fi

# If we don't have a spack yaml, generate from package
if [ -z "${INPUT_SPACK_YAML}" ]; then

cat > spack.yaml <<EOL
spack:
  view: true
  specs:
    - ${INPUT_PACKAGE_NAME}
  config:
    concretizer: clingo
    compiler:
      target: [x86_64_v3]
    install_missing_compilers: true
    install_tree:
      root: /opt/software
      padded_length: 512
  container:
    strip: true
    os_packages:
      build:
        - python3-boto3
        - python3-dev
EOL
INPUT_SPACK_YAML=spack.yaml
fi

printf "Preparing to containerize:\n"

# Show the finished spack.yaml
cat $INPUT_SPACK_YAML
YAMLDIR=$(dirname ${INPUT_SPACK_YAML})
cd ${YAMLDIR}
ls

spack containerize > Dockerfile

echo "" >> Dockerfile

# Add a single clone of spack back
echo "RUN apt-get update && apt-get install -y git python3 && git clone --depth 1 https://github.com/spack/spack /opt/spack" >> Dockerfile
echo "ENV PATH=/opt/spack/bin:$PATH" >> Dockerfile
echo "ENV SPACK_ROOT=/opt/spack" >> Dockerfile

# Do we have a tag?
if [ -z "${INPUT_TAG}" ]; then
    INPUT_TAG=${GITHUB_SHA}
fi

printf "Preparing to build Dockerfile"
cat Dockerfile

# Use first 8 of Github sha
SHA=${GITHUB_SHA:0:8}

# Default to name package the same as GitHub repository
PACKAGE_NAME=${GITHUB_REPOSITORY}

# And if we have a package name, add it
if [ ! -z "${INPUT_PACKAGE_NAME}" ]; then
    PACKAGE_NAME=${GITHUB_REPOSITORY}/${INPUT_PACKAGE_NAME}
fi

# build the docker container! We could eventually just send the Dockerfile to an output
# and then use BuildX, this is okay for a demo for now, at least until someone asks for differently
container=ghcr.io/${PACKAGE_NAME}:${SHA}
docker build -t ${container} .

# Apply post labels!
labels=""
 
# Add labels with name and version if we have a package name and not yaml
# TODO this should be done with spack containerize
if [ -z "${INPUT_SPACK_YAML}" ] && [ ! -z "${INPUT_PACKAGE_NAME}" ]  ; then
    labels="${labels} --label org.spack.package.name=${INPUT_PACKAGE_NAME}"
    version=$(docker run -i --entrypoint spack --rm ${container} find --format "{version}" ${INPUT_PACKAGE_NAME})    
    labels="${labels} --label org.spack.package.version=${version}"
    description="Spack package container with ${INPUT_PACKAGE_NAME}@${version}"

# Otherwise, get all packages installed in list
else
    count=$(docker run -i --entrypoint spack --rm ${container} find --format "{name}" | wc -l)
    description="Spack package container with ${count} packages."
    packages=""
    docker run -i --entrypoint spack --rm ${container} find --format "{name}@{version}" > packages.txt
    cat packages.txt
    for package in $(cat packages.txt | uniq); do 
       packages="$packages,$package"
    done
    printf "Packages: ${packages}\n"

    # Strip commas
    packages=$(python -c "print('${packages}'.strip(','))")
    printf "Packages: ${packages}\n"
 
    labels="${labels} --label org.spack.packages=${packages}"
fi

# Get compilers in image
compilers=""
docker run -i --entrypoint spack --rm ${container} find --format "{compiler}" > compilers.txt
cat compilers.txt
for compiler in $(cat compilers.txt | uniq); do 
   compilers="$compilers,$compiler"
done

# Strip commas
printf "Compilers: ${compilers}\n"
compilers=$(python -c "print('${compilers}'.strip(','))")
printf "Compilers: ${compilers}\n"
labels="${labels} --label org.spack.compilers=${compilers}"
labels="${labels} --label org.opencontainers.image.description=${description}"

printf "Adding labels:\n ${labels}"
echo "FROM ${container}" > Dockerfile.labeled
docker build ${labels} -t ${container} -f Dockerfile.labeled .

if [[ "${GITHUB_SHA}" != "${INPUT_TAG}" ]]; then
    docker tag ghcr.io/${PACKAGE_NAME}:${SHA} ghcr.io/${PACKAGE_NAME}:${INPUT_TAG}
fi

docker images | grep ghcr.io
