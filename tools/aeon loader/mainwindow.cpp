/*
 * Aeon - Open Source Reconfigurable Computer
 * Copyright (C) 2013-2015 Dmitriy Schapotschkin (ilovespeccy@speccyland.net)
 * Project Homepage: http://www.speccyland.net
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

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

#define CMD_SET_SPI_MASTER                0x20
#define CMD_DATAFLASH_RESET               0x21
#define CMD_DATAFLASH_POWER_OF_TWO        0x22
#define CMD_DATAFLASH_GET_STATUS          0x23
#define CMD_DATAFLASH_CHIP_ERASE          0x24
#define CMD_DATAFLASH_FILL_BUFFER         0x25
#define CMD_DATAFLASH_FLUSH_BUFFER        0x26
#define CMD_DATAFLASH_READ                0x27

#define CMD_FPGA_GET_STATUS               0xA0
#define CMD_FPGA_RESET                    0xA1
#define CMD_FPGA_WRITE_BITSTREAM          0xA2

#define SPIMASTER_PIC24                   0
#define SPIMASTER_FPGA                    1

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

                if (QMessageBox::question(this,
                                          "Write bitstream into DataFlash",
                                          "Do you want to write bitstream into DataFlash now?",
                                          QMessageBox::Yes, QMessageBox::No) == QMessageBox::Yes)
                {
                   OutputPacket[0] = CMD_SET_SPI_MASTER;
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

                       // verify
                       // ==========================================================================
                       unsigned long address;
                       for(buff_pos = 0; buff_pos < 512; buff_pos += 32)
                       {
                          address = page * 512UL + buff_pos;
                          OutputPacket[0] = CMD_DATAFLASH_READ;
                          OutputPacket[1] = (address >> 16) & 0xFF;
                          OutputPacket[2] = (address >> 8) & 0xff;
                          OutputPacket[3] = address & 0xFF;
                          if (usb_bulk_write(dev,  EP_OUT, OutputPacket, BUF_SIZE, 5000) != BUF_SIZE)
                          {
                             statusBar()->showMessage("Error USB Transmit", 5000);
                             break;
                          }
                          if (usb_bulk_read(dev,  EP_IN, InputPacket, BUF_SIZE, 5000) != BUF_SIZE)
                          {
                             statusBar()->showMessage("Error USB Transmit", 5000);
                             break;
                          }

                          if (memcmp(InputPacket, &buffer[buff_pos], 32))
                          {
                             QMessageBox::warning(this, "DataFlash Write Error", "Verifying failed", QMessageBox::Ok);
                             usb_close(dev);
                             return;
                          }
                       }
                       // ==========================================================================

                       ui->progressBar->setValue(page * 100 / (file.size() / 512));

                       page++;
                       memset(buffer, 0, sizeof(buffer));
                   }

                   ui->progressBar->setValue(100);
                   statusBar()->showMessage("DataFlash Programming is Done", 5000);
                }

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

void MainWindow::on_pushButtonEraseDataflash_clicked()
{
   usb_dev_handle *dev = NULL;

   char InputPacket[64];
   char OutputPacket[64];

   boolean done = false;

   if (QMessageBox::question(this,
                             "Erase DataFlash Chip",
                             "Do you want to erase DataFlash now?\nThis may take a few minutes.",
                             QMessageBox::Yes, QMessageBox::No) == QMessageBox::Yes)
   {
      usb_init();
      usb_find_busses();
      usb_find_devices();

      if ((dev = open_dev()))
      {
          if (!(usb_set_configuration(dev, MY_CONFIG)))
          {
              if (!usb_claim_interface(dev, MY_INTF))
              {
                 statusBar()->showMessage("Erasing DataFlash...", 5000);
                 OutputPacket[0] = CMD_DATAFLASH_CHIP_ERASE;
                 usb_bulk_write(dev,  EP_OUT, OutputPacket, BUF_SIZE, 5000);

                 while (!done)
                 {
                    OutputPacket[0] = CMD_DATAFLASH_GET_STATUS;
                    usb_bulk_write(dev,  EP_OUT, OutputPacket, BUF_SIZE, 5000);
                    usb_bulk_read(dev,  EP_IN, InputPacket, BUF_SIZE, 5000);
                    if (InputPacket[0] & 0x80)
                       done = true;
                 }

                 QMessageBox::information(this, "Erase DataFlash Chip", "DataFlash is erased now!", QMessageBox::Ok);
                 statusBar()->showMessage("DataFlash is erased now", 5000);
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
}

void MainWindow::on_pushButtonStatusDataflash_clicked()
{
   usb_dev_handle *dev = NULL;

   char InputPacket[64];
   char OutputPacket[64];
   char status;
   QString status_line;

   usb_init();
   usb_find_busses();
   usb_find_devices();

   if ((dev = open_dev()))
   {
      if (!(usb_set_configuration(dev, MY_CONFIG)))
      {
         if (!usb_claim_interface(dev, MY_INTF))
         {
            statusBar()->showMessage("Reading DataFlash Information...", 5000);
            OutputPacket[0] = CMD_DATAFLASH_GET_STATUS;
            usb_bulk_write(dev,  EP_OUT, OutputPacket, BUF_SIZE, 5000);
            usb_bulk_read(dev,  EP_IN, InputPacket, BUF_SIZE, 5000);
            status = InputPacket[0];

            if (((status >> 2) & 0x0F) == 0x0B)
               status_line.append("DataFlash Density: 16 Mbit\n");
            else if (((status >> 2) & 0x0F) == 0x0D)
               status_line.append("DataFlash Density: 32 Mbit\n");
            else
               status_line.append("DataFlash Density: unknown\n");

            if (status & 0x01)
               status_line.append("Page Size: 512 Bytes\n");
            else
               status_line.append("Page Size: 528 Bytes\n");

            QMessageBox::information(this, "DataFlash Information",status_line, QMessageBox::Ok);
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

void MainWindow::on_pushButtonPrepareDataflash_clicked()
{
   usb_dev_handle *dev = NULL;

   char OutputPacket[64];

   usb_init();
   usb_find_busses();
   usb_find_devices();

   if ((dev = open_dev()))
   {
      if (!(usb_set_configuration(dev, MY_CONFIG)))
      {
         if (!usb_claim_interface(dev, MY_INTF))
         {
            statusBar()->showMessage("Configure DataFlash for \"Power of Two\" Mode...", 5000);
            OutputPacket[0] = CMD_DATAFLASH_POWER_OF_TWO;
            usb_bulk_write(dev,  EP_OUT, OutputPacket, BUF_SIZE, 5000);

            QMessageBox::information(this, "Prepare DataFlash", "DataFlash is now configured for \"Power of Two\" Mode\nPlease disconnect power from \"Aeon Lite\"", QMessageBox::Ok);
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

void MainWindow::on_pushButtonReadRTC_clicked()
{
   usb_dev_handle *dev = NULL;

   char InputPacket[64];
   char OutputPacket[64];

   QString status_line;
   QTime aeonTime;
   QDate aeonDate;

   usb_init();
   usb_find_busses();
   usb_find_devices();

   if ((dev = open_dev()))
   {
      if (!(usb_set_configuration(dev, MY_CONFIG)))
      {
         if (!usb_claim_interface(dev, MY_INTF))
         {
            statusBar()->showMessage("Reading RTC...", 5000);

            OutputPacket[0] = CMD_RTC_READ;
            OutputPacket[1] = 0; // Start address
            OutputPacket[2] = 7; // Bytes to read

            usb_bulk_write(dev,  EP_OUT, OutputPacket, BUF_SIZE, 5000);
            usb_bulk_read(dev,  EP_IN, InputPacket, BUF_SIZE, 5000);

            aeonTime.setHMS((InputPacket[2] >> 4) * 10 + (InputPacket[2] & 0x0F),            // Hour
                            (InputPacket[1] >> 4) * 10 + (InputPacket[1] & 0x0F),            // Minutes
                            (InputPacket[0] >> 4) * 10 + (InputPacket[0] & 0x0F) );          // Seconds

            aeonDate.setDate((InputPacket[6] >> 4) * 10 + (InputPacket[6] & 0x0F) + 2000UL,  // Year
                             (InputPacket[5] >> 4) * 10 + (InputPacket[5] & 0x0F),           // Month
                             (InputPacket[4] >> 4) * 10 + (InputPacket[4] & 0x0F) );         // Date

            status_line.append("Aeon Lite RTC Status:\n\nDate: ");
            status_line.append(aeonDate.toString("dd.MM.yyyy"));
            status_line.append("\nTime: ");
            status_line.append(aeonTime.toString());

            QMessageBox::information(this, "Reading RTC",status_line, QMessageBox::Ok);
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

void MainWindow::on_pushButtonSetRTC_clicked()
{
   usb_dev_handle *dev = NULL;

   char OutputPacket[64];

   QString status_line;
   QTime aeonTime = QTime::currentTime();
   QDate aeonDate = QDate::currentDate();

   usb_init();
   usb_find_busses();
   usb_find_devices();

   if ((dev = open_dev()))
   {
      if (!(usb_set_configuration(dev, MY_CONFIG)))
      {
         if (!usb_claim_interface(dev, MY_INTF))
         {
            statusBar()->showMessage("Write current Date/Time to RTC...", 5000);

            OutputPacket[0] = CMD_RTC_WRITE;
            OutputPacket[1] = 0; // Start address
            OutputPacket[2] = 7; // Bytes to write
            OutputPacket[3] = ((aeonTime.second() / 10UL) << 4) + (aeonTime.second() % 10);
            OutputPacket[4] = ((aeonTime.minute() / 10UL) << 4) + (aeonTime.minute() % 10);
            OutputPacket[5] = ((aeonTime.hour()   / 10UL) << 4) + (aeonTime.hour()   % 10);
            OutputPacket[6] = aeonDate.dayOfWeek();
            OutputPacket[7] = ((aeonDate.day()    / 10UL) << 4) + (aeonDate.day()    % 10);
            OutputPacket[8] = ((aeonDate.month()  / 10UL) << 4) + (aeonDate.month()  % 10);
            OutputPacket[9] = (((aeonDate.year() - 2000UL) / 10UL) << 4) + ((aeonDate.year() - 2000UL) % 10);

            usb_bulk_write(dev,  EP_OUT, OutputPacket, BUF_SIZE, 5000);

            status_line.append("Write current Date/Time to RTC:\n\nDate: ");
            status_line.append(aeonDate.toString("dd.MM.yyyy"));
            status_line.append("\nTime: ");
            status_line.append(aeonTime.toString("HH:mm:ss"));

            QMessageBox::information(this, "Reading RTC",status_line, QMessageBox::Ok);
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
