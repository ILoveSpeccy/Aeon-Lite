#include "mainwindow.h"
#include "ui_mainwindow.h"
#include <lusb0_usb.h>  // libUSB, http://libusb.sourceforge.net/
#include "bitfile.h"

#define MY_VID      0xF055
#define MY_PID      0xFFF0

#define EP_IN       0x81
#define EP_OUT      0x01

#define MY_CONFIG   1
#define MY_INTF     0

#define BUF_SIZE    64

bitfile myBitFile;

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
    ui->setupUi(this);
    settings = new QSettings("aeontool.ini", QSettings::IniFormat);
    loadSettings();
}

MainWindow::~MainWindow()
{
    saveSettings();
    delete ui;
}

void MainWindow::saveSettings()
{
    settings->setValue("BitstreamFile", ui->lineFileName->text());
    settings->sync(); // flush
}

void MainWindow::loadSettings()
{
    ui->lineFileName->setText(settings->value("BitstreamFile","").toString());
}

void MainWindow::showFileInformation(QString fileName)
{
    if (myBitFile.readBitFile(fileName)) {
        ui->labelDesignName->setText(myBitFile.getDesignName());
        ui->labelPartName->setText(myBitFile.getPartName());
        ui->labelDate->setText(myBitFile.getDate());
        ui->labelTime->setText(myBitFile.getTime());
        ui->labelBitstreamLength->setText(QString::number(myBitFile.getDataLength()));
    }
    else
        statusBar()->showMessage("Error: bitstream file not exists or corrupt", 5000);
}

void MainWindow::on_pushButtonOpenFile_clicked()
{
    QString fileName = QFileDialog::getOpenFileName(this, tr("Open Bitstream File"),
                                ui->lineFileName->text(),tr("Bitstream Files (*.bit *.bin)"));
    if (!fileName.isEmpty()) {
        showFileInformation(fileName);
        ui->lineFileName->setText(fileName);
    }
}

usb_dev_handle *open_dev(void)
{
    struct usb_bus *bus;
    struct usb_device *dev;

    for (bus = usb_get_busses(); bus; bus = bus->next)
        for (dev = bus->devices; dev; dev = dev->next)
            if (dev->descriptor.idVendor  == MY_VID && dev->descriptor.idProduct == MY_PID)
                return usb_open(dev);
    return NULL;
}

void MainWindow::on_pushButtonConfigureFPGA_clicked()
{
    showFileInformation(ui->lineFileName->text());
    if (myBitFile.getError())
        return;

    usb_dev_handle *dev = NULL;

    char InputPacket[64];
    char OutputPacket[64];

    statusBar()->showMessage("Starting FPGA Programming...");
    ui->progressBar->setValue(0);

    unsigned char res;
    unsigned long a = 0;

    usb_init();
    usb_find_busses();
    usb_find_devices();

    if ((dev = open_dev()))
    {
        if (!(usb_set_configuration(dev, MY_CONFIG)))
        {
            if (!usb_claim_interface(dev, MY_INTF))
            {
                OutputPacket[0] = 0xA1;
                usb_bulk_write(dev,  EP_OUT, OutputPacket, BUF_SIZE, 5000);

                res = 0;
                for(a=0;a<15;a++)
                {
                   OutputPacket[0] = 0xA0;
                   usb_bulk_write(dev,  EP_OUT, OutputPacket, BUF_SIZE, 5000);
                   usb_bulk_read(dev,  EP_IN, InputPacket, BUF_SIZE, 5000);
                   if (InputPacket[0] == 1)
                   {
                      res = 1;
                      break;
                   }
                }

                if (res)
                {
                    QFile file(ui->lineFileName->text());

                    if (!file.open(QIODevice::ReadOnly))
                    {
                        statusBar()->showMessage("Error opening file", 5000);
                        return;
                    }

                    OutputPacket[0] = 0xA2;
                    file.seek(myBitFile.getStartPos());

                    while((res = file.read(&OutputPacket[1], 63)))
                    {
                        if (usb_bulk_write(dev,  EP_OUT, OutputPacket, BUF_SIZE, 5000) != BUF_SIZE)
                        {
                           statusBar()->showMessage("Error USB Transmit", 5000);
                           break;
                        }
                        a += res;
                        if (ui->progressBar->value() != (a * 100 / file.size()))
                            ui->progressBar->setValue(a * 100 / file.size());
                    }

                    ui->progressBar->setValue(100);
                    OutputPacket[0] = 0xA0;
                    usb_bulk_write(dev,  EP_OUT, OutputPacket, BUF_SIZE, 5000);
                    usb_bulk_read(dev,  EP_IN, InputPacket, BUF_SIZE, 5000);
                    if (InputPacket[1]==0)
                       statusBar()->showMessage("FPGA Configuration Error", 5000);
                    else
                       statusBar()->showMessage("FPGA Configuration Done", 5000);
                }
                else
                    statusBar()->showMessage("FPGA Reset error", 5000);
            }
            else
                statusBar()->showMessage("Claiming interface error", 5000);
        }
        else
            statusBar()->showMessage("Device configuration error", 5000);
        usb_close(dev);
    }
    else
        statusBar()->showMessage("Error: \"Aeon Lite\" is not found", 5000);
}

