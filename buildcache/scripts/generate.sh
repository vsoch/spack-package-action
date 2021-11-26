#!/bin/bash

set -e

# These envars are required!
if [ -z "${spec_json}" ]; then
    printf "Envar spec_json is required.\n"
    exit 1
fi

if [ -z "${package_name}" ]; then
    printf "Envar package_name is required.\n"
    exit 1
fi

if [ -z "${package_tagged_name}" ]; then
    printf "Envar package_tagged_name is required.\n"
    exit 1
fi

if [ -z "${package_tag}" ]; then
    printf "Envar package_tag is required.\n"
    exit 1
fi

if [ -z "${package_content_type}" ]; then
    printf "Envar package_content_type is required.\n"
    exit 1
fi

if [ -z "${build_cache_prefix}" ]; then
    printf "Envar build_cache_prefix is required.\n"
    exit 1
fi

# Keep full name for later
full_package_name=${package_name}

printf "repo: ${INPUT_REPO}\n"
printf "clone root: ${INPUT_ROOT}\n"
printf "subfolder: ${INPUT_SUBFOLDER}\n"
printf "branch: ${GITHUB_BRANCH}\n"
printf "default repo: ${GITHUB_REPOSITORY}\n"
printf "spec_json: ${spec_json}\n"
printf "package: ${package_name}\n"
printf "tagged: ${package_tagged}\n"
printf "content type: ${package_content_type}\n"

# If the github repo is set, use GITHUB_REPOSITORY
if [ -z "${INPUT_REPO}" ]; then
    INPUT_REPO="${GITHUB_REPOSITORY}"
fi

printf "Input repository to clone is https://github.com/${INPUT_REPO}.git"


# Clone a branch is asked for, otherwise default to main
if [ -z "${INPUT_BRANCH}" ]; then
    git clone https://github.com/${INPUT_REPO}.git ${INPUT_ROOT}
else
    git clone -b ${INPUT_BRANCH} https://github.com/${INPUT_REPO}.git ${INPUT_ROOT} || git clone https://github.com/${INPUT_REPO}.git ${INPUT_ROOT} && cd ${INPUT_ROOT} && git checkout -b ${INPUT_BRANCH} 
fi

# Clone GitHub pages branch with site
cd ${INPUT_ROOT}

# Repository name
repository_name=$(basename ${INPUT_REPO})

# If no input subfolder exists, create with new site content
if [ ! -d "${INPUT_SUBFOLDER}" ]; then
   printf "${INPUT_SUBFOLDER} does not exist\n"
   printf "cp -R ${ACTION_PATH}/docs ${INPUT_SUBFOLDER}\n"
   cp -R ${ACTION_PATH}/docs "${INPUT_SUBFOLDER}"

   # Ensure repository and baseurl at top of _config
   sed -i "1irepository: ${INPUT_REPO}" ${INPUT_SUBFOLDER}/_config.yml
   sed -i "1ibaseurl: /${repository_name}" ${INPUT_SUBFOLDER}/_config.yml
   cat ${INPUT_SUBFOLDER}/_config.yml

   # Copy the key into the root of the cache
   cp ${ACTION_PATH}/4A424030614ADE118389C2FD27BDB3E5F0331921.pub ${INPUT_SUBFOLDER}/_cache/4A424030614ADE118389C2FD27BDB3E5F0331921.pub
   sed -i "1isigning_key: 4A424030614ADE118389C2FD27BDB3E5F0331921.pub" ${INPUT_SUBFOLDER}/_config.yml
fi

# Remove .spack to get general name
package_name=$(basename ${package_name%.spack})

# We will write the package template
markdown_result=${INPUT_SUBFOLDER}/_cache/${build_cache_prefix}/${package_name}.md
repository=$(basename ${GITHUB_REPOSITORY})
spec_json_name=$(basename ${spec_json})

# Date updated
updated_at=$(date '+%Y-%m-%d')

# Generate package page
cat > ${markdown_result} <<EOL
---
title: ${package_name}
categories: spack-package
tags: [spack-package, "latest", "${package_tag}"]
json: ${spec_json_name}
content_type: "${package_content_type}"
package: ${full_package_name}
tagged: ${package_tagged_name}
updated_at: ${updated_at}
package_page: https://github.com/${GITHUB_REPOSITORY}/pkgs/container/${repository}/${package_name}
maths: 1
toc: 1
---
EOL


printf "Markdown file generated was ${markdown_result}\n"
cat ${markdown_result}

# Copy the spec_json there
mv ${spec_json} ${INPUT_SUBFOLDER}/_cache/${build_cache_prefix}/${spec_json_name}

tree ${INPUT_SUBFOLDER}/_cache
git status
