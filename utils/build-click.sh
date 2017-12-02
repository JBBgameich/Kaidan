#!/bin/bash

KAIDAN_SOURCES=$(dirname "$(readlink -f "${0}")")/..
export CLICK_TARGET_DIR="$KAIDAN_SOURCES/bin/ubuntu-touch/"

# Tell build system what tools to use.
export target_host=arm-linux-gnueabihf
export AR=$target_host-ar
export AS=$target_host-gcc
export CC=$target_host-gcc
export CXX=$target_host-g++
export LD=$target_host-ld
export STRIP=$target_host-strip

! [ -d $CLICK_TARGET_DIR ] && mkdir $CLICK_TARGET_DIR

echo "*****************************************"
echo "Downloading Kirigami from KDE Neon"
echo "*****************************************"

for PKG in qml-module-org-kde-kirigami2 kirigami2-dev libkf5kirigami2-5; do
	SUFFIX="5.43.0+p16.04+git20180221.0430-0_armhf"
	wget https://archive.neon.kde.org/dev/unstable/pool/main/k/kirigami2/${PKG}_${SUFFIX}.deb -O /tmp/${PKG}_${SUFFIX}.deb
	dpkg-deb -x /tmp/${PKG}_${SUFFIX}.deb $CLICK_TARGET_DIR
	rm /tmp/${PKG}_${SUFFIX}.deb
done


echo "*****************************************"
echo "Downloading QtQuick Controls 2 from UBports"
echo "*****************************************"

for PKG in qml-module-qtquick-controls2 qtquickcontrols2-5-dev qml-module-qtquick-templates2 qml-module-qt-labs-platform libqt5quicktemplates2-5 libqt5quicktemplates2-5; do
	SUFFIX="5.9.3-0ubports2_armhf"
	wget https://repo.ubports.com/pool/xenial/main/q/qtquickcontrols2-opensource-src/${PKG}_${SUFFIX}.deb -O /tmp/${PKG}_${SUFFIX}.deb
	dpkg-deb -x /tmp/${PKG}_${SUFFIX}.deb $CLICK_TARGET_DIR
	rm /tmp/${PKG}_${SUFFIX}.deb
done


echo "*****************************************"
echo "Building Gloox"
echo "*****************************************"

cd $KAIDAN_SOURCES/3rdparty/gloox
./autogen.sh
./configure --host=arm --prefix=/usr/
DESTDIR=$CLICK_TARGET_DIR make install -j$(nproc)
cd $KAIDAN_SOURCES

echo "*****************************************"
echo "Building Kaidan"
echo "*****************************************"

! [ -d $KAIDAN_SOURCES/build ] && mkdir $KAIDAN_SOURCES/build; cd build
cd $KAIDAN_SOURCES/build
cmake .. -DUBUNTU_TOUCH=1 -DCMAKE_INSTALL_PREFIX=/usr/
DESTDIR=$CLICK_TARGET_DIR make VERBOSE=1 install

cp $KAIDAN_SOURCES/misc/ubuntu-touch/manifest.json $CLICK_TARGET_DIR
cp $KAIDAN_SOURCES/misc/ubuntu-touch/apparmor.json $CLICK_TARGET_DIR
cp $KAIDAN_SOURCES/misc/ubuntu-touch/kaidan.desktop $CLICK_TARGET_DIR
cp $KAIDAN_SOURCES/misc/kaidan.svg $CLICK_TARGET_DIR

cd $CLICK_TARGET_DIR

echo "*****************************************"
echo "Build script finished, now leaving work to 'click build'"
echo "******************************************"
