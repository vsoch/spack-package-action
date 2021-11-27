#!/bin/bash

# These envars are required!
if [ -z "${spec_jsons}" ]; then
    printf "Envar spec_jsons is required.\n"
    exit 1
fi

if [ -z "${package_names}" ]; then
    printf "Envar package_names is required.\n"
    exit 1
fi

if [ -z "${package_tagged_names}" ]; then
    printf "Envar package_tagged_names is required.\n"
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

printf "subfolder: ${INPUT_SUBFOLDER}\n"
printf "branch: ${GITHUB_BRANCH}\n"
printf "spec_jsons: ${spec_jsons}\n"
printf "package: ${package_names}\n"
printf "tagged: ${package_tagged_names}\n"
printf "content type: ${package_content_type}\n"

printf "git checkout -b ${INPUT_BRANCH} || git checkout ${INPUT_BRANCH}\n"

# Repository name
repository_name=$(basename ${PWD})
printf "Repository name is ${repository_name}\n"

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

# Date updated
updated_at=$(date '+%Y-%m-%d')

# Reach each of package_names, package_tagged_names, and spec_jsons into arrays
IFS=',' read -r -a package_names <<< "$package_names"
IFS=',' read -r -a package_tagged_names <<< "$package_tagged_names"
IFS=',' read -r -a spec_jsons <<< "$spec_jsons"

for i in "${!package_names[@]}"; do
    package_name=${package_names[i]}
    package_tagged_name=${package_tagged_names[i]}
    spec_json=${spec_jsons[i]}
    printf "Parsing spec package ${i}\n"
    printf "package: ${package_name}\n"
    printf "tagged package: ${package_tagged_name}\n"
    printf "spec_json: ${spec_json}\n"

    plain_package_name=$(basename ${package_name%.spack})

    # We will write the package template
    markdown_result=${INPUT_SUBFOLDER}_cache/${build_cache_prefix}/${plain_package_name}.md
    repository=$(basename ${GITHUB_REPOSITORY})

    spec_json_name=$(basename ${spec_json})

# Generate package page
cat > ${markdown_result} <<EOL
---
title: ${plain_package_name}
categories: spack-package
tags: [spack-package, "latest", "${package_tag}"]
json: ${spec_json_name}
content_type: "${package_content_type}"
package: ${package_name}
tagged: ${package_tagged_name}
updated_at: ${updated_at}
maths: 1
toc: 1
---
EOL

    printf "Markdown file generated was ${markdown_result}\n"
    cat ${markdown_result}

    # Copy the spec_json there
    mv ${spec_json} ${INPUT_SUBFOLDER}/_cache/${build_cache_prefix}/${spec_json_name}
done

tree ${INPUT_SUBFOLDER}/_cache
git status
