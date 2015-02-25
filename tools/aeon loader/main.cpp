#include "mainwindow.h"
#include <QApplication>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);

    QApplication::setOrganizationName("SpeccyLand");
    QApplication::setOrganizationDomain("www.speccyland.net");
    QApplication::setApplicationName("Aeon Tool");

    MainWindow w;
    w.show();

    return a.exec();
}
