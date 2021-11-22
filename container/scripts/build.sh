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
  mirrors:
    autamus: s3://autamus-cache
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

# Add labels with name and version if we have a package name and not yaml
if [ -z "${INPUT_SPACK_YAML}" ] && [ ! -z "${INPUT_PACKAGE_NAME}" ]  ; then
    echo "LABEL org.spack.package.name=${INPUT_PACKAGE_NAME}" >> Dockerfile
    version=$(spack find --format "{version}" ${INPUT_PACKAGE_NAME})
    echo "LABEL org.spack.package.version=${version}" >> Dockerfile

# Otherwise, get all packages installed in list
else
    packages=""
    for package in $(spack find --format "{name}@{version}" | uniq); do 
       packages="$packages,$package"
    done

    # Strip commas
    packages=$(python -c "print('${packages}'.strip(','))")
    echo "LABEL org.spack.packages=${packages}" >> Dockerfile
fi

# Get compilers in image
compilers=""
for compiler in $(spack find --format "{compiler}" | uniq); do 
   compilers="$compilers,$compiler"
done

# Strip commas
compilers=$(python -c "print('${compilers}'.strip(','))")
echo "LABEL org.spack.compilers=${compilers}" >> Dockerfile

# Do we have a tag?
if [ -z "${INPUT_TAG}" ]; then
    INPUT_TAG=${GITHUB_SHA}
fi

printf "Preparing to build Dockerfile"
cat Dockerfile

# build the docker container! We could eventually just send the Dockerfile to an output
# and then use BuildX, this is okay for a demo for now, at least until someone asks for differently
docker build -t ghcr.io/${GITHUB_REPOSITORY}/${INPUT_PACKAGE_NAME}:${GITHUB_SHA} .
if [[ "${GITHUB_SHA}" != "${INPUT_TAG}" ]]; then
    docker tag ghcr.io/${GITHUB_REPOSITORY}/${INPUT_PACKAGE_NAME}:${GITHUB_SHA} ghcr.io/${GITHUB_REPOSITORY}/${INPUT_PACKAGE_NAME}:${INPUT_TAG}
fi

docker images | grep ghcr.io
