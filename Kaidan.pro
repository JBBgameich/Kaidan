TEMPLATE = app

QT += qml quick quickcontrols2 sql
android: QT += androidextras

CONFIG += c++11

SOURCES += \
    src/main.cpp \
    src/Kaidan.cpp \
    src/AvatarFileStorage.cpp \
    src/Database.cpp \
    src/RosterModel.cpp \
    src/RosterManager.cpp \
    src/RosterUpdater.cpp \
    src/MessageHandler.cpp \
    src/MessageSessionHandler.cpp \
    src/MessageModel.cpp \
    src/Notifications.cpp \
    src/PresenceHandler.cpp \
    src/ServiceDiscoveryManager.cpp \
    src/VCardManager.cpp \
    src/XmlLogHandler.cpp \
    src/StatusBar.cpp

HEADERS += \
    src/Database.h \
    src/RosterModel.h \
    src/XmlLogHandler.h  \
    src/RosterManager.h \
    src/AvatarFileStorage.h \
    src/ServiceDiscoveryManager.h \
    src/RosterUpdater.h \
    src/MessageSessionHandler.h \
    src/MessageModel.h \
    src/Notifications.h \
    src/PresenceHandler.h \
    src/MessageHandler.h \
    src/Kaidan.h \
    src/VCardManager.h \
    src/branding.h \
    src/StatusBar.h

android: INCLUDEPATH += $$PWD/prebuilt/libgloox/android/$$ANDROID_TARGET_ARCH/include
android: LIBS += -L$$PWD/prebuilt/libgloox/android/$$ANDROID_TARGET_ARCH/lib/
android: LIBS += -L$$PWD/prebuilt/openssl/android/$$ANDROID_TARGET_ARCH/lib/
LIBS += -lgloox -lssl -lcrypto

include(3rdparty/kirigami/kirigami.pri)

RESOURCES += kaidan_qml.qrc i18n/0_i18n.qrc data/images/images.qrc

TRANSLATIONS += \
    i18n/de.ts \
    i18n/fr.ts \
    i18n/ja.ts \
    i18n/ms.ts \
    i18n/ru.ts
    
DEFINES += QMAKE_BUILD

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH = $$PWD/src/qml $$PWD/3rdparty/kirigami/src

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH = $$PWD/src/qml $$PWD/3rdparty/kirigami/src

# The following define makes your compiler emit warnings if you use
# any feature of Qt which as been marked deprecated (the exact warnings
# depend on your compiler). Please consult the documentation of the
# deprecated API in order to know how to port your code away from it.
DEFINES += QT_DEPRECATED_WARNINGS

# You can also make your code fail to compile if you use deprecated APIs.
# In order to do so, uncomment the following line.
# You can also select to disable deprecated APIs only up to a certain version of Qt.
DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

DISTFILES += \
    android/AndroidManifest.xml \
    android/gradle/wrapper/gradle-wrapper.jar \
    android/gradlew \
    android/res/values/libs.xml \
    android/build.gradle \
    android/gradle/wrapper/gradle-wrapper.properties \
    android/gradlew.bat \
    android/AndroidManifest.xml \
    android/gradle/wrapper/gradle-wrapper.jar \
    android/gradlew \
    android/res/drawable/splash.xml \
    android/res/values/colors.xml \
    android/res/values/libs.xml \
    android/res/values/theme.xml \
    android/res/mipmap-hdpi/icon.png \
    android/res/mipmap-hdpi/logo.png \
    android/res/mipmap-ldpi/icon.png \
    android/res/mipmap-ldpi/logo.png \
    android/res/mipmap-mdpi/icon.png \
    android/res/mipmap-mdpi/logo.png \
    android/res/mipmap-xhdpi/icon.png \
    android/res/mipmap-xhdpi/logo.png \
    android/res/mipmap-xxhdpi/icon.png \
    android/res/mipmap-xxhdpi/logo.png \
    android/res/mipmap-xxxhdpi/icon.png \
    android/res/mipmap-xxxhdpi/logo.png \
    android/gradle/wrapper/gradle-wrapper.properties \
    android/build.gradle \
    android/gradlew.bat \
    android/gradle.properties \
    android/local.properties

ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android

