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

#define CMD_RTC_READ                      0x10
#define CMD_RTC_WRITE                     0x11
#define CMD_DATAFLASH_FILL_BUFFER         0x12
#define CMD_DATAFLASH_FLUSH_BUFFER        0x13
#define CMD_DATAFLASH_READ                0x14
#define CMD_SET_SPIMASTER                 0x15

#define SPIMASTER_PIC24                   0
#define SPIMASTER_FPGA                    1

#define CMD_FPGA_GET_STATUS               0xA0
#define CMD_FPGA_RESET                    0xA1
#define CMD_FPGA_WRITE_BITSTREAM          0xA2

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
    else {
        ui->labelDesignName->setText("");
        ui->labelPartName->setText("");
        ui->labelDate->setText("");
        ui->labelTime->setText("");
        ui->labelBitstreamLength->setText("");

        statusBar()->showMessage("Error: bitstream file not exists or corrupt", 5000);
    }
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
                OutputPacket[0] = CMD_FPGA_RESET;
                usb_bulk_write(dev,  EP_OUT, OutputPacket, BUF_SIZE, 5000);

                res = 0;
                for(a=0;a<15;a++)
                {
                   OutputPacket[0] = CMD_FPGA_GET_STATUS;
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

                    OutputPacket[0] = CMD_FPGA_WRITE_BITSTREAM;
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
                    OutputPacket[0] = CMD_FPGA_GET_STATUS;
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


void MainWindow::on_pushButtonWriteDataflash_clicked()
{
    showFileInformation(ui->lineFileName->text());
    if (myBitFile.getError())
        return;

    usb_dev_handle *dev = NULL;

    char InputPacket[64];
    char OutputPacket[64];

    statusBar()->showMessage("Starting DataFlash Programming...");
    ui->progressBar->setValue(0);

    unsigned short res;
    unsigned short page = 0;
    unsigned short buff_pos = 0;
    char buffer[512];

    usb_init();
    usb_find_busses();
    usb_find_devices();

    if ((dev = open_dev()))
    {
        if (!(usb_set_configuration(dev, MY_CONFIG)))
        {
            if (!usb_claim_interface(dev, MY_INTF))
            {
                QFile file(ui->lineFileName->text());

                if (!file.open(QIODevice::ReadOnly))
                {
                    statusBar()->showMessage("Error opening file", 5000);
                    return;
                }

                OutputPacket[0] = CMD_SET_SPIMASTER;
                OutputPacket[1] = SPIMASTER_PIC24;

                if (usb_bulk_write(dev,  EP_OUT, OutputPacket, BUF_SIZE, 5000) != BUF_SIZE)
                {
                   statusBar()->showMessage("Error USB Transmit", 5000);
                   return;
                }

                file.seek(myBitFile.getStartPos());

                while((res = file.read(buffer, 512)))
                {
                    for(buff_pos = 0; buff_pos < 512; buff_pos += 32)
                    {
                       OutputPacket[0] = CMD_DATAFLASH_FILL_BUFFER;
                       OutputPacket[1] = (buff_pos >> 8) & 0x01;
                       OutputPacket[2] = buff_pos & 0xFF;
                       memcpy(&OutputPacket[3], &buffer[buff_pos], 32);

                       if (usb_bulk_write(dev,  EP_OUT, OutputPacket, BUF_SIZE, 5000) != BUF_SIZE)
                       {
                          statusBar()->showMessage("Error USB Transmit", 5000);
                          break;
                       }
                    }

                    OutputPacket[0] = CMD_DATAFLASH_FLUSH_BUFFER;
                    OutputPacket[1] = (page >> 8) & 0x0F;
                    OutputPacket[2] = page & 0xFF;
                    if (usb_bulk_write(dev,  EP_OUT, OutputPacket, BUF_SIZE, 5000) != BUF_SIZE)
                    {
                       statusBar()->showMessage("Error USB Transmit", 5000);
                       break;
                    }

                    ui->progressBar->setValue(page * 100 / (file.size() / 512));

                    page++;
                    memset(buffer, 0, sizeof(buffer));
                }

                ui->progressBar->setValue(100);
                statusBar()->showMessage("DataFlash Programming is Done", 5000);
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
