#-------------------------------------------------
#
# Project created by QtCreator 2015-02-18T09:01:24
#
#-------------------------------------------------

QT       += core gui

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

TARGET = AeonLoader
TEMPLATE = app

#QMAKE_LFLAGS +=

SOURCES += main.cpp\
        mainwindow.cpp \
    bitfile.cpp

HEADERS  += mainwindow.h \
    bitfile.h

FORMS    += mainwindow.ui

INCLUDEPATH += C:/Dev/Qt/libs/libusb/include
LIBS += C:/Dev/Qt/libs/libusb/lib/gcc/libusb.a

RESOURCES += \
    resource.qrc

win32:RC_FILE = tool.rc
