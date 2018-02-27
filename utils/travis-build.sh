#!/bin/bash

echo "*****************************************"
echo "Building Kaidan binary"
echo "Using build system: ${BUILD_SYSTEM}"
echo "Number of CPUs used: $(nproc)"
echo "*****************************************"

mkdir ../build; cd ../build/

if [ $BUILD_SYSTEM == "cmake" ]; then
	source /opt/qt*/bin/qt*-env.sh
	cmake .. -GNinja -DI18N=1 -DCMAKE_CXX_COMPILER_LAUNCHER=ccache
	cmake --build .
elif [ $BUILD_SYSTEM == "qmake" ]; then
	source /opt/qt*/bin/qt*-env.sh
	lrelease ../Kaidan.pro
	qmake "QMAKE_CXX=ccache g++" ..
	make -j$(nproc)
elif [ $BUILD_VARIANT == "click" ]; then
	clickable
fi
