QT       += core gui network

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

CONFIG += c++11

# You can make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

SOURCES += \
    aboutdialog.cpp \
    connectpinecildialog.cpp \
    flashingthread.cpp \
    main.cpp \
    mainwindow.cpp

HEADERS += \
    aboutdialog.h \
    connectpinecildialog.h \
    flashingthread.h \
    mainwindow.h

FORMS += \
    aboutdialog.ui \
    connectpinecildialog.ui \
    mainwindow.ui

TRANSLATIONS += \
    pinecil_firmware_updater_en_US.ts

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

win32: LIBS += -L$$PWD/deps/libusb/VS2019/MS64/dll/ -llibusb-1.0
win32: INCLUDEPATH += $$PWD/deps/libusb/include
win32: DEPENDPATH += $$PWD/deps/libusb/include

message("$$PWD/deps/libusb/lib/")

macx: LIBS += -L$$PWD/deps/libusb/lib/ -lusb-1.0
macx: INCLUDEPATH += $$PWD/deps/libusb/include
macx: DEPENDPATH += $$PWD/deps/libusb/include

unix:!android: LIBS += -lusb-1.0

DISTFILES += \
    pinecil-instructions.png

RESOURCES += \
    resources.qrc

win32: CONFIG += embed_manifest_exe
QMAKE_LFLAGS_WINDOWS += /MANIFESTUAC:"level='requireAdministrator'"
