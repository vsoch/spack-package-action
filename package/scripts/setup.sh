#!/bin/bash

set -e

# GitHub supports ubuntu, so the setup here assumes that
printf "Installing spack dependencies...\n"

apt update -q -y \
  && apt install -y -q \
      autoconf \
      automake \
      bzip2 \
      clang \
      cpio \
      curl \
      file \
      findutils \
      g++ \
      gcc \
      gettext \
      gfortran \ 
      git \
      gpg \
      iputils-ping \
      jq \
      libffi-dev \
      libssl-dev \
      libtool \
      libxml2-dev \
      locales \
      locate \
      m4 \
      make \
      mercurial \
      ncurses-dev \
      patch \
      patchelf \
      pciutils \
      python3-pip \
      rsync \
      tree \
      unzip \
      wget \
      xz-utils \
      zlib1g-dev \
  && locale-gen en_US.UTF-8 \
  && apt autoremove --purge \
  && apt clean \
  && ln -s /usr/bin/gpg /usr/bin/gpg2 \
  && ln -s `which python3` /usr/bin/python

python -m pip install --upgrade pip setuptools wheel
python -m pip install gnureadline boto3 pyyaml pytz minio requests clingo
rm -rf ~/.cache

export SPACK_ROOT=/opt/spack
export SPACK_ADD_DEBUG_FLAGS=true

printf "Installing spack...\n"
    
# Do we have a release or a branch?
if [ ! -z "${INPUT_RELEASE}" ]; then
    wget https://github.com/spack/spack/releases/download/v${INPUT_RELEASE}/spack-${INPUT_RELEASE}.tar.gz
    tar -xzvf spack-${INPUT_RELEASE}.tar.gz
    mv spack-${INPUT_RELEASE} /opt/spack

# Branch install
else
    git clone --depth 1 -b ${INPUT_BRANCH} https://github.com/spack/spack /opt/spack
fi

# Find compilers
# The user running the action should install additional compilers before
cd /opt/spack
. share/spack/setup-env.sh
spack compiler find

# Do we have additional repos to add?
if [ ! -z "${INPUT_REPOS}" ]; then
    echo ${INPUT_REPOS} | sed -n 1'p' | tr ',' '\n' | while read repo; do
        printf "Adding additional repository $repo\n"
        repo_name=$(basename $repo)
        clone_dir=$(mktemp -d -t $repo_name)
        rm -rf $clone_dir
        git clone $repo $clone_dir        
        spack repo add $clone_dir
    done
    cd /opt/spack
fi
