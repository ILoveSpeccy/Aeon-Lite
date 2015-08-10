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

#include <usb/usb.h>
#include <usb/usb_device.h>
#include <usb/usb_device_cdc.h>
#include <usb/usb_device_generic.h>
#include "hal.h"
#include "dataflash.h"
#include "usb_handler.h"
#include "fpga.h"
#include "rtc.h"

volatile static uint8_t lock = 0;

volatile USB_HANDLE USBGenericOutHandle;
volatile USB_HANDLE USBGenericInHandle;

uint8_t USBGenericOutPacket[64];
uint8_t USBGenericInPacket[64];

// Local Functions
void usbGenericHandler(void);
void usbGenericFlush(void);

void usbInit(void)
{
   USBDeviceInit();
   USBDeviceAttach();
}

uint8_t usbHandler(void)
{
   #if defined(USB_POLLING)
      USBDeviceTasks();
   #endif

   if (!(USBGetDeviceState() < CONFIGURED_STATE))
      if(USBIsDeviceSuspended() != true)
         usbGenericHandler();

   return lock;
}

bool USER_USB_CALLBACK_EVENT_HANDLER(USB_EVENT event, void *pdata, uint16_t size)
{
   switch((int)event)
   {
      case EVENT_CONFIGURED:
         USBGenericInHandle = 0;
         USBEnableEndpoint(USBGEN_EP_NUM, USB_OUT_ENABLED|USB_IN_ENABLED|USB_HANDSHAKE_ENABLED|USB_DISALLOW_SETUP);
         USBGenericOutHandle = USBGenRead(USBGEN_EP_NUM, (uint8_t*)&USBGenericOutPacket, USBGEN_EP_SIZE);
         break;

      case EVENT_EP0_REQUEST:
         USBCheckCDCRequest();
         break;

      default:
         break;
   }
   return true;
}

#if defined(USB_INTERRUPT)
void __attribute__((interrupt,auto_psv)) _USB1Interrupt()
{
   USBDeviceTasks();
}
#endif

void usbGenericHandler(void)
{
   if(!USBHandleBusy(USBGenericOutHandle)) // data recieved from host
   {
      yellowLedOn;
      switch (USBGenericOutPacket[0])
      {
         case CMD_READ_STATUS:
         {
            /// Выдать состояние по-возможности ВСЕГО возможного....
            USBGenericInPacket[0] = pinInitB;
            USBGenericInPacket[1] = pinConfDone;
            USBGenericInPacket[2] = pinMcuReady;
            USBGenericInPacket[3] = pinSpiMux;
            USBGenericInPacket[4] = pinPowerLed;
            USBGenericInPacket[5] = pinRedLed;
            USBGenericInPacket[6] = pinYellowLed;
            USBGenericInPacket[7] = pinGreenLed;
            USBGenericInPacket[8] = pinSdcardDetect;
            USBGenericInPacket[9] = pinSdcardWriteProtect;

            usbGenericFlush();
            break;
         }

         case CMD_MCU_READY:
         {
            pinMcuReady = USBGenericOutPacket[1];
            break;
         }

         // Get FPGA Status; Byte 0 - INIT_B, Byte 1 - DONE
         ///////////////////////////////////////////////////////////////////////
         case CMD_FPGA_GET_STATUS:
         {
            USBGenericInPacket[0] = pinInitB;
            USBGenericInPacket[1] = pinConfDone;
            usbGenericFlush();
            break;
         }

         // Reset FPGA
         ///////////////////////////////////////////////////////////////////////
         case CMD_FPGA_RESET:
         {
            fpgaReset();
            break;
         }

         // Configure FPGA (Bytes 1-63)
         ///////////////////////////////////////////////////////////////////////
         case CMD_FPGA_WRITE_BITSTREAM:
         {
            fpgaConfigure(&USBGenericOutPacket[1], 63);
            break;
         }

         // Write RTC
         ///////////////////////////////////////////////////////////////////////
         case CMD_RTC_WRITE:
         {
            rtcWrite(USBGenericOutPacket[1], USBGenericOutPacket[2], (uint8_t*)&USBGenericOutPacket[3]);
            break;
         }

         // Read RTC
         ///////////////////////////////////////////////////////////////////////
         case CMD_RTC_READ:
         {
            rtcRead(USBGenericOutPacket[1], USBGenericOutPacket[2], (uint8_t*)&USBGenericInPacket);
            usbGenericFlush();
            break;
         }




         case CMD_SET_SPI_MASTER:
         {
            pinSpiMux = USBGenericOutPacket[1];
            break;
         }

         case CMD_DATAFLASH_RESET:
         {
            dataflashSoftReset();
            break;
         }

         case CMD_DATAFLASH_POWER_OF_TWO:
         {
            dataflashPowerOfTwo();
            break;
         }

         case CMD_DATAFLASH_GET_STATUS:
         {
            USBGenericInPacket[0] = dataflashGetStatus();
            usbGenericFlush();
            break;
         }

         case CMD_DATAFLASH_CHIP_ERASE:
         {
            dataflashChipErase(0);
            break;
         }

         case CMD_DATAFLASH_FILL_BUFFER:
         {
            unsigned short pos = (((unsigned short)USBGenericOutPacket[1] << 8) | USBGenericOutPacket[2]) & 0x1FF;
            dataflashFillBuffer(pos, &USBGenericOutPacket[3], 32);
            break;
         }

         case CMD_DATAFLASH_FLUSH_BUFFER:
         {
            unsigned short page = ((unsigned short)USBGenericOutPacket[1] << 8) | USBGenericOutPacket[2];
            dataflashFlushBuffer(page);
            break;
         }

         case CMD_DATAFLASH_READ:
         {
            unsigned long address = ((unsigned long)USBGenericOutPacket[1] << 16) |
                                    ((unsigned long)USBGenericOutPacket[2] << 8)  |
                                                    USBGenericOutPacket[3];
            dataflashReadBlock(address, USBGenericInPacket, 32);
            usbGenericFlush();
            break;
         }





         //
         ///////////////////////////////////////////////////////////////////////
         case CMD_COMM_ADDR_TRANSFER:
         {
            USBGenericInPacket[0] = commTransferAddr(USBGenericOutPacket[1]);
            usbGenericFlush();
            break;
         }

         //
         ///////////////////////////////////////////////////////////////////////
         case CMD_COMM_DATA_TRANSFER:
         {
            USBGenericInPacket[0] = commTransferData(USBGenericOutPacket[1]);
            usbGenericFlush();
            break;
         }
      }
      yellowLedOff;
      USBGenericOutHandle = USBGenRead(USBGEN_EP_NUM,(uint8_t*)&USBGenericOutPacket,USBGEN_EP_SIZE); // Refresh USB
   }
}

void usbGenericFlush(void)
{
   USBGenericInHandle = USBGenWrite(USBGEN_EP_NUM, (uint8_t*)&USBGenericInPacket, USBGEN_EP_SIZE);
   while (USBHandleBusy(USBGenericInHandle));
}
