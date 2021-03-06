#!/bin/bash

set -e

# Do we have a dockerfile or a root?
if [ "${INPUT_DEPLOY}" != "true" ]; then
    printf "Deploy is false, will not deploy\n"
    exit 0
fi

# We should already be in cloned repository and branch!
ls .

git config --global user.name "${INPUT_USER}"
git config --global user.email "${INPUT_USER}@users.noreply.github.com"
git config pull.rebase true

git remote set-url origin "https://x-access-token:${INPUT_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
git add ${INPUT_SUBFOLDER} || printf "No matching files\n"
git add ${INPUT_SUBFOLDER}* || printf "No matching files\n"
git add ${INPUT_SUBFOLDER}//* || printf "No matching files\n"
git add ${INPUT_SUBFOLDER}/_cache || printf "No matching files\n"
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
