#!/bin/bash
SOURCE_ROOT="$(dirname "$(readlink -f "${0}")")/../"

cd $SOURCE_ROOT

DATE=$(date +%Y%m%d)
KAIDAN_PKG_VERSION=$(dpkg-parsechangelog -SVersion -l packaging/debian/changelog)
KAIDAN_VERSION=$(echo $KAIDAN_PKG_VERSION | sed "s/[-].*//")
KAIDAN_PKG_GIT_VERSION="$KAIDAN_VERSION+git$DATE"
TAR="$SOURCE_ROOT/kaidan_$KAIDAN_PKG_GIT_VERSION.orig.tar.xz"

git archive master | xz > $TAR
tar -xf $TAR -C $SOURCE_ROOT/packaging/

cd $SOURCE_ROOT/packaging
dch -v $KAIDAN_PKG_GIT_VERSION-1 "Git snapshot build"
sudo apt build-dep .
dpkg-buildpackage --no-sign

cd $SOURCE_ROOT
git -C packaging reset HEAD --hard
