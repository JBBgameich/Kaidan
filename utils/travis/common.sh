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

	# bionic backports
	sudo bash -c "echo deb http://archive.ubuntu.com/ubuntu bionic main restricted universe multiverse >> /etc/apt/sources.list"
	sudo bash -c "echo deb http://archive.ubuntu.com/ubuntu bionic-backports main restricted universe multiverse >> /etc/apt/sources.list"

	sudo apt update

	# Qt 5.12 repository
	sudo add-apt-repository -y ppa:beineri/opt-qt-5.12.2-xenial
}

add_ubuntu-touch_apt_repos() {
	sudo add-apt-repository ppa:bhdouglass/clickable -y
}

install_linux-desktop_deps() {
	add_linux-desktop_apt_repos

	sudo apt-get update
	sudo apt-get install -y -t bionic-backports \
	                     cmake \
	                     build-essential \
	                     ninja-build \
	                     zlib1g-dev \
	                     qt512base \
	                     qt512script \
	                     qt512declarative \
	                     qt512tools \
	                     qt512x11extras \
	                     qt512svg \
	                     qt512quickcontrols2
}

install_ubuntu-touch_deps() {
	add_ubuntu-touch_apt_repos

	sudo apt-get update
	sudo apt-get install clickable
	clickable setup-docker
}

env_setup() {
	if [ -f /opt/qt5*/bin/qt5*-env.sh ]; then
		echo "I: Setting up custom Qt installation..."
		source /opt/qt5*/bin/qt5*-env.sh
	fi
}
