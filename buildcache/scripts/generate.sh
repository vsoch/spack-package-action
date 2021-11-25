#!/bin/bash

set -e

# If the github repo is set, use GITHUB_REPOSITORY
if [ -z "${INPUT_REPO+x}" ]; then
    INPUT_REPO="${GITHUB_REPOSITORY}"
fi

printf "Input repository to clone is https://github.com/${INPUT_REPO}.git"



# Clone a branch is asked for, otherwise default to main
if [ -z "${INPUT_REPO+x}" ]; then
    git clone https://github.com/${INPUT_REPO}.git /tmp/repo
else
    git clone -b ${INPUT_BRANCH} https://github.com/${INPUT_REPO}.git /tmp/repo
fi

# Clone GitHub pages branch with site
cd /tmp/repo
ls .

# Repository name
repository_name=$(basename ${GITHUB_REPOSITORY})

# If no input subfolder exists, create with new site content
if [ ! -d "${INPUT_SUBFOLDER}" ]; then
   printf "${INPUT_SUBFOLDER} does not exist\n"
   printf "cp -R ${ACTION_PATH}/docs ${INPUT_SUBFOLDER}\n"
   cp -R ${ACTION_PATH}/docs "${INPUT_SUBFOLDER}"

   # Ensure repository and baseurl at top of _config
   sed -i '1s/^/repository: ${GITHUB_REPOSITORY} /' ${INPUT_SUBFOLDER}/_config.yaml
   sed -i '1s/^/baseurl: /${repository_name} /' ${INPUT_SUBFOLDER}/_config.yaml
   cat _config.yaml
fi

# Remove .spack to get general name
package_name=$(basename ${INPUT_PACKAGE_NAME%.spack})

# We will write the package template
markdown_result=${INPUT_SUBFOLDER}/_cache/${INPUT_CACHE_PREFIX}/build_cache/${package_name}.md
repository=$(basename ${GITHUB_REPOSITORY})
spec_json_name=$(basename ${INPUT_SPEC_JSON})

# Date updated
updated_at=$(date '+%Y-%m-%d')

# Generate package page
cat > ${markdown_result} <<EOL
---
title: ${package_name}
categories: spack-package
tags: [spack-package, "latest", "${INPUT_PACKAGE_TAG}"]
json: ${spec_json_name}
content_type: "${INPUT_CONTENT_TYPE}"
package: ${INPUT_PACKAGE_NAME}
tagged: ${INPUT_PACKAGE_TAGGED_NAME}
updated_at: ${updated_at}
package_page: https://github.com/${GITHUB_REPOSITORY}/pkgs/container/${repository}/${package_name}
maths: 1
toc: 1
---
EOL


printf "Markdown file generated was ${markdown_result}\n"
cat ${markdown_result}

# Copy the spec_json there
mv ${INPUT_SPEC_JSON} ${INPUT_SUBFOLDER}/_cache/${INPUT_CACHE_PREFIX}/build_cache/${spec_json_name}

tree ${INPUT_SUBFOLDER}/_cache
git status
