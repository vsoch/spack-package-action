#!/bin/bash

set -e

echo $PWD
ls 

ACTION_ROOT=$(dirname $ACTION_PATH)
printf "ACTION_ROOT is ${ACTION_ROOT}\n"
ls ${ACTION_ROOT}
echo "ACTION_ROOT=${ACTION_ROOT}" >> $GITHUB_ENV
