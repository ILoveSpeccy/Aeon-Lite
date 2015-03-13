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

    void on_pushButtonWriteDataflash_clicked();

    void on_pushButtonEraseDataflash_clicked();

    void on_pushButtonStatusDataflash_clicked();

    void on_pushButtonPrepareDataflash_clicked();

    void on_pushButtonReadRTC_clicked();

    void on_pushButtonSetRTC_clicked();

private:
    Ui::MainWindow *ui;
    QSettings *settings;
};

#endif // MAINWINDOW_H
