#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <lusb0_usb.h>  // libUSB, http://libusb.sourceforge.net/

#include "bitinfo.h"    // Get Xilinx .bit-Header information
#include "progress.h"   // Progress bar

#define MY_VID 0xF055
#define MY_PID 0xFFF0

#define EP_IN 0x81
#define EP_OUT 0x01

unsigned char InputPacket[64];
unsigned char OutputPacket[64];
unsigned char count;

usb_dev_handle *MyLibusbDeviceHandle = NULL;

// Open USB Device
/////////////////////////////////////////////////////////////

usb_dev_handle *open_dev(void)
{
   struct usb_bus *bus;
   struct usb_device *dev;

   for(bus = usb_get_busses(); bus; bus = bus->next)
   {
      for(dev = bus->devices; dev; dev = dev->next)
	   {
	      if(dev->descriptor.idVendor == MY_VID && dev->descriptor.idProduct == MY_PID)
	      {
		      return usb_open(dev);
	      }
	   }
   }
   return NULL;
}

// Connect USB Device
/////////////////////////////////////////////////////////////

unsigned char Connect_Device(void)
{
   usb_init(); /* initialize the library */
   usb_find_busses(); /* find all busses */
   usb_find_devices(); /* find all connected devices */
   if(!(MyLibusbDeviceHandle = open_dev()))
      return 1;
   if(usb_set_configuration(MyLibusbDeviceHandle, 1) < 0)
   {
      usb_close(MyLibusbDeviceHandle);
      return 2;
   }
	if(usb_claim_interface(MyLibusbDeviceHandle, 0) < 0)
   {
      usb_close(MyLibusbDeviceHandle);
	   return 3;
   }
   return 0;
}

// Configure FPGA
/////////////////////////////////////////////////////////////

void FPGA_Configure(unsigned char *FileName)
{
   bithead BitHeader;
   unsigned short Count = 0;
   unsigned char INITB = 0;

   switch (ReadBitHeader(&BitHeader, FileName))
   {
      case 1 : {printf("File could not open \n");     exit (1);}
      case 2 : {printf("Invalid bit file header.\n"); exit (2);}
      case 3 : {printf("File corrupt.\n");            exit (3);}
   }

   printf("File: %s\nBitstream: %s\nPart: %s",FileName, BitHeader.filename, BitHeader.part);
   printf("\nDate: %s\nTime: %s\nBitstream Size: %i bits\n", BitHeader.date, BitHeader.time, BitHeader.length);

   printf("\n\nReset FPGA... ");
	OutputPacket[0] = 0xA1;
	usb_bulk_write(MyLibusbDeviceHandle,  EP_OUT, &OutputPacket[0], 64, 5000);

   for(Count=0;Count<15;Count++)
   {
      OutputPacket[0] = 0xA0;
      usb_bulk_write(MyLibusbDeviceHandle,  EP_OUT, &OutputPacket[0], 64, 5000);
      usb_bulk_read(MyLibusbDeviceHandle,  EP_IN, &InputPacket[0], 64, 5000);
      if (InputPacket[0] == 1)
      {
         INITB = 1;
         break;
      }
   }

   if (INITB == 1)
   {
      printf("ok\nStart FPGA Configuration\n");
      FILE *MFILE;
      if ((MFILE=fopen(FileName,"rb")) == NULL)
      {
         printf("File could not open \n");
         exit(1);
      }
      fseek(MFILE, BitHeader.position, SEEK_SET);
      OutputPacket[0] = 0xA2;

      while((count = fread(&OutputPacket[1],1,63,MFILE)))
      {
         if (usb_bulk_write(MyLibusbDeviceHandle,  EP_OUT, &OutputPacket[0], 64, 5000) != 64)
         {
            printf("Error USB Transmit\n");
            exit(4);
         }
         progress(BitHeader.length/63, Count++);
      }
      fclose(MFILE);

      OutputPacket[0] = 0xA0;
      usb_bulk_write(MyLibusbDeviceHandle,  EP_OUT, &OutputPacket[0], 64, 5000);
      usb_bulk_read(MyLibusbDeviceHandle,  EP_IN, &InputPacket[0], 64, 5000);
      if (InputPacket[1]==0)
         printf("FPGA Configuration Error\n");
      else
         printf("\nFPGA Configuration Done\n");
   }
   else
      printf("\nFPGA Reset Error\n");
}


int main(int argc, char **argv)
{
   printf("\n\n");
   printf("========================================\n");
   printf("            Aeon v2.0 Loader\n");
   printf("   Configure FPGA with Bitstream file   \n");
   printf("----------------------------------------\n");
   printf("        www.speccyland.net '2010\n");
   printf("by Dmitriy Schapotschkin aka ILoveSpeccy\n");
   printf("========================================\n\n");

   if(argc < 2) // missing parameter
   {
      printf("Missing parameters.\n");
      printf("Use: aeonloader <bitstream-filename>\n");
      exit(5);
   }

   switch (Connect_Device())
   {
      case 1:  {printf("Open USB Device failed\n"); return 1;}
      case 2:  {printf("Config USB Device failed\n"); return 2;}
      case 3:  {printf("Claim USB Device failed\n"); return 3;}
      default:
      {
         FPGA_Configure(argv[1]);
      }
   }

   usb_release_interface(MyLibusbDeviceHandle, 0);
   usb_close(MyLibusbDeviceHandle);
   return 0;
}
