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
	VERSION="5.43.0+p16.04+git20180221.0430-0"
	wget https://archive.neon.kde.org/dev/unstable/pool/main/k/kirigami2/${PKG}_${VERSION}_armhf.deb -O /tmp/${PKG}_${VERSION}_armhf.deb
	dpkg-deb -x /tmp/${PKG}_${VERSION}_armhf.deb $CLICK_TARGET_DIR
	rm /tmp/${PKG}_${VERSION}_armhf.deb
done


echo "*****************************************"
echo "Downloading QtQuick Controls 2 from UBports"
echo "*****************************************"

for PKG in qml-module-qtquick-controls2 qtquickcontrols2-5-dev qml-module-qtquick-templates2 qml-module-qt-labs-platform libqt5quicktemplates2-5 libqt5quicktemplates2-5; do
	VERSION="5.9.3-0ubports2"
	wget https://repo.ubports.com/pool/xenial/main/q/qtquickcontrols2-opensource-src/${PKG}_${VERSION}_armhf.deb -O /tmp/${PKG}_${VERSION}_armhf.deb
	dpkg-deb -x /tmp/${PKG}_${VERSION}_armhf.deb $CLICK_TARGET_DIR
	rm /tmp/${PKG}_${VERSION}_armhf.deb
done

echo "*****************************************"
echo "Downloading Gloox from Plasma Mobile"
echo "*****************************************"

for PKG in libgloox-dev libgloox17; do
	VERSION="1.0.20-1+16.04+xenial+build1"
	wget http://neon.plasma-mobile.org:8080/pool/main/g/gloox/${PKG}_${VERSION}_armhf.deb -O /tmp/${PKG}_${VERSION}_armhf.deb
	dpkg-deb -x /tmp/${PKG}_${VERSION}_armhf.deb $CLICK_TARGET_DIR
	rm /tmp/${PKG}_${VERSION}_armhf.deb
done


echo "*****************************************"
echo "Building Kaidan"
echo "*****************************************"

! [ -d $KAIDAN_SOURCES/build ] && mkdir $KAIDAN_SOURCES/build
cd $KAIDAN_SOURCES/build
cmake .. -DUBUNTU_TOUCH=1 -DCMAKE_INSTALL_PREFIX=/usr/
DESTDIR=$CLICK_TARGET_DIR make VERBOSE=1 install

cp $KAIDAN_SOURCES/misc/ubuntu-touch/manifest.json $CLICK_TARGET_DIR
cp $KAIDAN_SOURCES/misc/ubuntu-touch/apparmor.json $CLICK_TARGET_DIR
cp $KAIDAN_SOURCES/misc/ubuntu-touch/kaidan.desktop $CLICK_TARGET_DIR
cp $KAIDAN_SOURCES/misc/kaidan.svg $CLICK_TARGET_DIR

# Strip out documentation and includes
rm -r \
	$KAIDAN_SOURCES/bin/ubuntu-touch/usr/include \
	$KAIDAN_SOURCES/bin/ubuntu-touch/usr/share/doc \
	$KAIDAN_SOURCES/bin/ubuntu-touch/usr/lib/arm-linux-gnueabihf/cmake/ \
	$KAIDAN_SOURCES/bin/ubuntu-touch/usr/lib/arm-linux-gnueabihf/pkgconfig/

# Move everything from usr/ to parent dir
mv $KAIDAN_SOURCES/bin/ubuntu-touch/usr/* $KAIDAN_SOURCES/bin/ubuntu-touch/

cd $CLICK_TARGET_DIR

echo "*****************************************"
echo "Build script finished, now leaving work to 'click build'"
echo "******************************************"
