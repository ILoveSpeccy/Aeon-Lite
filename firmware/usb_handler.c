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
#include "usb_handler.h"
#include "fpga.h"

volatile USB_HANDLE USBGenericOutHandle;
volatile USB_HANDLE USBGenericInHandle;

unsigned char USBGenericOutPacket[64];
unsigned char USBGenericInPacket[64];

// Local Functions
void USB_Generic_Handler(void);

void USB_Init(void)
{
    USBDeviceInit();
    USBDeviceAttach();
}

void USB_Handler(void)
{
   #if defined(USB_POLLING)
      USBDeviceTasks();
   #endif

   if (USBGetDeviceState() < CONFIGURED_STATE)
      return;

   if( USBIsDeviceSuspended() == true )
      return;

   USB_Generic_Handler();
}

bool USER_USB_CALLBACK_EVENT_HANDLER(USB_EVENT event, void *pdata, uint16_t size)
{
    switch((int)event)
    {
        case EVENT_CONFIGURED:
            USBGenericInHandle = 0;
            USBEnableEndpoint(USBGEN_EP_NUM,USB_OUT_ENABLED|USB_IN_ENABLED|USB_HANDSHAKE_ENABLED|USB_DISALLOW_SETUP);
            USBGenericOutHandle = USBGenRead(USBGEN_EP_NUM,(uint8_t*)&USBGenericOutPacket,USBGEN_EP_SIZE);

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

void USB_Generic_Handler(void)
{
   if(!USBHandleBusy(USBGenericOutHandle)) // data recieved from host
   {
      UserLED1_On;
      switch (USBGenericOutPacket[0])
      {
         case 0xA0 :    // Get FPGA Status; Byte 0 - INIT_B, Byte 1 - DONE
         {
            USBGenericInPacket[0] = INIT_B;
            USBGenericInPacket[1] = CONF_DONE;
            USBGenericInHandle = USBGenWrite(USBGEN_EP_NUM,(uint8_t*)&USBGenericInPacket,USBGEN_EP_SIZE);
            while (USBHandleBusy(USBGenericInHandle));
            break;
         }

         case 0xA1 :    /** Reset FPGA */
         {
            FPGA_Reset();
            break;
         }

         case 0xA2 :    /** Configure FPGA (Bytes 1-63) */
         {
            FPGA_Write_Bitstream(&USBGenericOutPacket[1], 63);
            break;
         }
      }
      UserLED1_Off;
      USBGenericOutHandle = USBGenRead(USBGEN_EP_NUM,(uint8_t*)&USBGenericOutPacket,USBGEN_EP_SIZE); // Refresh USB
   }
}
