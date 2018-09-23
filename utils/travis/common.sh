#!/bin/bash -e

# Compatibility with Travis-CI and GitLab-CI
if [ ! -z ${TRAVIS_BUILD_DIR} ]; then
        export BUILD_DIR=${TRAVIS_BUILD_DIR}
else
        export BUILD_DIR="$(dirname "$(readlink -f "${0}")")/../../"
fi

export CPUS_USED=2
if command -v nproc >/dev/null; then
	export CPUS_USED=$(nproc)
fi

if [[ ${PLATFORM} == "ubuntu-touch" ]]; then
	export BUILD_SYSTEM="cmake"
elif [[ ${PLATFORM} == "android" ]]; then
	# Packages
	export QT_VERSION=5.11.0
	export NDK_VERSION=r16b
	export SDK_PLATFORM=android-21
	export SDK_PACKAGES="tools platform-tools"

	# Pathes
	export QT_PATH=/opt/Qt
	export QT_ANDROID=${QT_PATH}/${QT_VERSION}/android_armv7
	export ANDROID_HOME=/opt/android-sdk
	export ANDROID_SDK_ROOT=${ANDROID_HOME}
	export ANDROID_NDK_ROOT=/opt/android-ndk
	export ANDROID_NDK_TOOLCHAIN_PREFIX=arm-linux-androideabi
	export ANDROID_NDK_TOOLCHAIN_VERSION=4.9
	export ANDROID_NDK_HOST=linux-x86_64
	export ANDROID_NDK_PLATFORM=${SDK_PLATFORM}
	export ANDROID_NDK_TOOLS_PREFIX=${ANDROID_NDK_TOOLCHAIN_PREFIX}
	export QMAKESPEC=android-g++
	export PATH=${QT_ANDROID}/bin:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools:${PATH}
elif [[ ${PLATFORM} == "" ]]; then
	# currently there's only linux-desktop & ut
	# otherwise other parameters (as TRAVIS_OS_NAME) could be checked
	export PLATFORM="linux-desktop"
fi

echo_env() {
	echo "PLATFORM=${PLATFORM}"
	echo "BUILD_SYSTEM=${BUILD_SYSTEM}"
	echo "CPUS_USED=${CPUS_USED}"
	echo "BUILD_DIR=$(readlink -f ${BUILD_DIR})"
}

add_linux-desktop_apt_repos() {
	sudo apt-get install dirmngr

	# trusty backports
	sudo bash -c "echo deb http://archive.ubuntu.com/ubuntu trusty-backports main restricted universe multiverse >> /etc/apt/sources.list"

	# Qt 5.9 repository
	sudo add-apt-repository -y ppa:beineri/opt-qt-5.10.1-trusty
}

add_ubuntu-touch_apt_repos() {
	sudo add-apt-repository ppa:bhdouglass/clickable -y
}

install_kf5() {
	wget -c "https://github.com/kf5builds/precompiled-kf5-linux/releases/download/kf5.50/kf5-5.50.0-Release-ubuntu-trusty-amd64.tar.xz"
	mkdir /tmp/kf5
	tar xf kf5-5.50.0-Release-ubuntu-trusty-amd64.tar.xz -C /tmp/kf5
	sudo cp -rf /tmp/kf5/* /opt/qt*/
}

install_gloox() {
	# download
	wget -c "https://github.com/JBBgameich/precompiled-kf5-linux/releases/download/KF5.40/libgloox17_1.0.20-1_amd64.deb"
	wget -c "https://github.com/JBBgameich/precompiled-kf5-linux/releases/download/KF5.40/libgloox-dev_1.0.20-1_amd64.deb"

	# install debs and install possible missing dependencies
	sudo dpkg -i libgloox*.deb || sudo apt-get -f -y install

	# clean up
	rm libgloox*.deb
}

install_linux-desktop_deps() {
	add_linux-desktop_apt_repos

	sudo apt-get update
	sudo apt-get install -y -t trusty-backports \
	                     cmake \
	                     build-essential \
	                     ninja-build \
	                     zlib1g-dev \
	                     qt510base \
	                     qt510script \
	                     qt510declarative \
	                     qt510tools \
	                     qt510x11extras \
	                     qt510svg \
	                     qt510quickcontrols2

	# KF5 (only for cmake; qmake compiles kirigami from submodule)
	if [[ $BUILD_SYSTEM == "cmake" ]]; then
		install_kf5
	fi
	install_gloox
}

install_ubuntu-touch_deps() {
	add_ubuntu-touch_apt_repos

	sudo apt-get update
	sudo apt-get install clickable
	clickable setup-docker
}

install_android_deps() {
	sudo dpkg --add-architecture i386
	sudo apt update
	sudo apt purge postgresql* -y
	sudo apt full-upgrade -y
	sudo apt install -y --no-install-recommends \
		        unzip \
		        curl \
		        make \
		        default-jdk \
		        ant \
		        libsm6 \
		        libice6 \
		        libxext6 \
		        libxrender1 \
		        libfontconfig1 \
		        libdbus-1-3 \
		        libc6:i386 \
		        libncurses5:i386 \
		        libstdc++6:i386 \
		        libz1:i386
	sudo apt-get -qq clean

	# Download qt installer extractor
	mkdir /tmp/qt/ -p
	curl -o /tmp/qt/extract-qt-installer.sh \
		https://raw.githubusercontent.com/rabits/dockerfiles/master/5.11-android/extract-qt-installer.sh \
		&& chmod +x /tmp/qt/extract-qt-installer.sh

	# Download & unpack Qt toolchains & clean
	curl -Lo /tmp/qt/installer.run "https://download.qt.io/official_releases/qt/$(echo "${QT_VERSION}" | cut -d. -f 1-2)/${QT_VERSION}/qt-opensource-linux-x64-${QT_VERSION}.run" \
		&& QT_CI_PACKAGES=qt.qt5.$(echo "${QT_VERSION}" | tr -d .).android_armv7 /tmp/qt/extract-qt-installer.sh /tmp/qt/installer.run "$QT_PATH" \
		&& find "${QT_PATH}" -mindepth 1 -maxdepth 1 ! -name "${QT_VERSION}" -exec echo 'Cleaning Qt SDK: {}' \; -exec rm -r '{}' \; \
		&& rm -rf /tmp/qt

	# Download & unpack android SDK
	curl -Lo /tmp/sdk-tools.zip 'https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip' \
		&& mkdir -p /opt/android-sdk && unzip -q /tmp/sdk-tools.zip -d /opt/android-sdk && rm -f /tmp/sdk-tools.zip \
		&& yes | sdkmanager --licenses && sdkmanager --verbose "platforms;${SDK_PLATFORM}" "build-tools;${SDK_BUILD_TOOLS}" ${SDK_PACKAGES}

	# Download & unpack android NDK
	mkdir /tmp/android && cd /tmp/android && curl -Lo ndk.zip "https://dl.google.com/android/repository/android-ndk-${NDK_VERSION}-linux-x86_64.zip" \
		&& unzip -q ndk.zip && mv android-ndk-* $ANDROID_NDK_ROOT && chmod -R +rX $ANDROID_NDK_ROOT \
		&& rm -rf /tmp/android
}

env_setup() {
	if [ -f /opt/qt5*/bin/qt5*-env.sh ]; then
		echo "I: Setting up custom Qt installation..."
		source /opt/qt5*/bin/qt5*-env.sh
	fi
}
