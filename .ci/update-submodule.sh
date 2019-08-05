#!/bin/bash

set -e

get_submodule_commit() {
    git submodule --quiet foreach git rev-parse HEAD
}

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <submodule_path> <branch>"
    exit 1
fi

SUBMODULE_PATH=$1
BRANCH=$2

if [[ "$BRANCH" != "master" ]]; then
    git fetch origin $BRANCH:$BRANCH
fi

# Needed even on master since on Travis you are on a detached head (git clone
# followed by git checkout) and we want to commit later in this script.
git checkout $BRANCH

git submodule update --init
CURRENT_SUBMODULE_COMMIT=$(get_submodule_commit)

git submodule update --remote
NEW_SUBMODULE_COMMIT=$(get_submodule_commit)

if [[ "$CURRENT_SUBMODULE_COMMIT" == "$NEW_SUBMODULE_COMMIT" ]]; then
    echo 'No update in the submodule since last sync, exiting'
    exit 0
fi

git diff

git config user.email "loic.esteve@ymail.com"
git config user.name lesteve

git add $SUBMODULE_PATH
git commit -m "Update submodule to commit $NEW_SUBMODULE_COMMIT"

PUSH_REMOTE=origin
if [[ -n "$TRAVIS" ]]; then
    PUSH_REMOTE=origin-with-token
    git remote | grep $PUSH_REMOTE || \
        git remote add $PUSH_REMOTE https://${GITHUB_TOKEN}@github.com/${TRAVIS_REPO_SLUG}
fi

git push $PUSH_REMOTE $BRANCH
