#!/bin/bash

set -e

# Do we have a dockerfile or a root?
if [ "${INPUT_DEPLOY}" != "true" ]; then
    printf "Deploy is false, will not deploy\n"
    exit 0
fi

# Go to where repository was cloned
cd ${INPUT_ROOT}

printf "GitHub Actor: ${GITHUB_ACTOR}\n"
git config --global user.name "github-actions"
git config --global user.email "github-actions@users.noreply.github.com"
git config pull.rebase true

# We should already be in cloned repository and branch!
ls .

git remote set-url origin "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
git add ${INPUT_SUBFOLDER}
git add ${INPUT_SUBFOLDER}/_cache
git status

set +e
git status | grep -e "modified" -e "new"
if [ $? -eq 0 ]; then
    set -e
    printf "Changes\n"
    git commit -m "Automated push to update build cache $(date '+%Y-%m-%d')" || exit 0
    git pull origin ${INPUT_BRANCH} || printf "Does not exist yet.\n"
    git push origin ${INPUT_BRANCH} || exit 0
else
    set -e
    printf "No changes\n"
fi
