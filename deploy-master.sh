#!/usr/bin/env bash
# The script creates a separate folder in build/ and creates tags there, pushes
# them and then uploads the package to PyPI.

set -eu -o pipefail

BASE_DIR=$(dirname $(readlink -f "$0"))
cd $BASE_DIR

git fetch --tags

PROJECT_NAME=parso
BRANCH=master
BUILD_FOLDER=build

[ -d $BUILD_FOLDER ] || mkdir $BUILD_FOLDER
# Remove the previous deployment first.
# Checkout the right branch
cd $BUILD_FOLDER
rm -rf $PROJECT_NAME
git clone .. $PROJECT_NAME
cd $PROJECT_NAME
git checkout $BRANCH

# Test first.
tox

# Create tag
tag=v$(python -c "import $PROJECT_NAME; print($PROJECT_NAME.__version__)")

master_ref=$(git show-ref -s heads/$BRANCH)
tag_ref=$(git show-ref -s $tag || true)
if [[ $tag_ref ]]; then
    if [[ $tag_ref != $master_ref ]]; then
        echo 'Cannot tag something that has already been tagged with another commit.'
        exit 1
    fi
else
    git tag $tag
    git push --tags
fi

# Package and upload to PyPI
#rm -rf dist/ - Not needed anymore, because the folder is never reused.
echo `pwd`
python setup.py sdist bdist_wheel
# Maybe do a pip install twine before.
twine upload dist/*

cd $BASE_DIR
# Back in the development directory fetch tags.
git fetch --tags
