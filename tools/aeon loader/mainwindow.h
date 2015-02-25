#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QtWidgets>
#include <QSettings>
#include <QDebug>

namespace Ui {
class MainWindow;
}

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = 0);
    ~MainWindow();

    void saveSettings();
    void loadSettings();
    void showFileInformation(QString fileName);

private slots:
    void on_pushButtonOpenFile_clicked();

    void on_pushButtonConfigureFPGA_clicked();

private:
    Ui::MainWindow *ui;
    QSettings *settings;
};

#endif // MAINWINDOW_H
