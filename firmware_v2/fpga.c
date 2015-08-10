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

/// Serial Configuration Data Timing
//        ____       ________________________________________________________________________
// PROG_B     \_____/
//        _______       _____________________________________________________________________
// INIT_B        \_____/
//                       ___     ___     ___     ___     ___     ___     ___
// CCLK   ______________/   \___/   \___/   \___/   \___/   \___/   \___/   \________________
//
// DIN    xxxxxxxxxxx< DATA >< DATA >< DATA >< DATA >< DATA >< DATA >xxxxxxxxxxxxxxxxxxxxxxxx
//                                                                       ____________________
// DONE   ______________________________________________________________/

/// PROG_B latency max. 5ms

/// Xilinx Spartan 6 XC6SLX9 Bitstream Length
/// 2742528 Bits (uncompressed)
/// 342816 Bytes
/// 670 Pages (of 8192 Pages Total) in DataFlash AT45DB321E

#include <string.h>
#include "hal.h"
#include "fpga.h"
#include "dataflash.h"
#include "timer.h"
#include "fat/ff.h"
#include "bitstream.h"

static uint8_t buffer[512];

// *****************************************************************************
// * Reset & Init FPGA, return 0 when Cuccessfull (Ready for Configuration)
// *****************************************************************************
uint8_t fpgaReset(void)
{
   pinProgB = 0;
   __delay_ms(10);

   if (!pinInitB)
   {
      pinProgB = 1;
      __delay_ms(10);
      if (pinInitB)
         return 0;
   }

   pinProgB = 1;
   return 1;
}

// *****************************************************************************
// * Configure FPGA (Write Bitstream)
// *****************************************************************************
void fpgaConfigure(uint8_t *buffer, uint16_t length)
{
   while(length--)
      commTransfer(*buffer++);
}

// *****************************************************************************
// * Configure FPGA from DataFlash, Return 0 when Successfull
// *****************************************************************************
uint8_t fpgaConfigureFromDataflash(uint8_t slot)
{
   uint16_t i;
   spiSckFast();
   fpgaReset();

   for(i=0;i<670;i++)
   {
      dataflashReadPage(i, buffer);
      fpgaConfigure(buffer, sizeof(buffer));
   }

   __delay_ms(1);
   if (pinConfDone)
      return 0;
   else
      return 1;
}

// *****************************************************************************
// * Configure FPGA from .bit File (SD-Card), Return 0 when Successfull
// *****************************************************************************
uint8_t fpgaConfigureFromFile(char *filename)
{
   FATFS filesystem;
   FIL file;
   FRESULT result;
   uint16_t readed = 0;
   struct bitinfo_struct bitinfo;

   if (fpgaReset())
      return 1;

   f_mount(&filesystem, "", 0);

   if (f_open(&file, filename, FA_READ))
      return 1;

   if (readBitFileHeader(&file, &bitinfo))
      return 1;

   if (f_lseek(&file, bitinfo.data_pos))
      return 1;

   while(1)
   {
      result = f_read(&file, buffer, sizeof(buffer), &readed);
      fpgaConfigure(buffer, sizeof(buffer));

      if (result || (readed == 0))
         break;
   }
   f_close(&file);
   f_mount(NULL, "",0);

   __delay_ms(1);
   if (pinConfDone)
      return 0;
   else
      return 1;
}

// *****************************************************************************
// * Configure FPGA from RAW (.bin) File (SD-Card), Return 0 when Successfull
// *****************************************************************************
uint8_t fpgaConfigureFromRawFile(char *filename)
{
   FATFS filesystem;
   FIL file;
   FRESULT result;
   uint16_t readed = 0;

   if (fpgaReset())
      return 1;

   f_mount(&filesystem, "", 0);

   if (f_open(&file, filename, FA_READ))
      return 1;

   while(1)
   {
      result = f_read(&file, buffer, sizeof(buffer), &readed);
      fpgaConfigure(buffer, sizeof(buffer));

      if (result || (readed == 0))
         break;
   }
   f_close(&file);
   f_mount(NULL, "",0);

   __delay_ms(1);
   if (pinConfDone)
      return 0;
   else
      return 1;
}

uint8_t fpgaInitRamFromFile(char* filename, uint32_t startaddr, uint8_t mode)
{
   FATFS FileSystem;
   FIL InputFile;
   FRESULT Result;
   UINT Readed = 0;

   f_mount(&FileSystem, "", 0);
   Result = f_open(&InputFile, filename, FA_OPEN_EXISTING | FA_READ);
   if (Result)
      return Result;

   fpgaRamSetAddress(startaddr);
   fpgaRamSetMode(mode & 0x01);

   while(1)
   {
      Result = f_read(&InputFile, buffer, sizeof(buffer), &Readed);
      fpgaWriteBuffer(buffer, sizeof(buffer));

      if (Result || (Readed == 0))
         break;
   }
   f_close(&InputFile);
   f_mount(NULL, "",0);

   return 0;
}

void fpgaFillRam(uint32_t startaddr, uint32_t length, uint8_t value, uint8_t mode)
{
   fpgaRamSetAddress(startaddr);
   fpgaRamSetMode(mode & 0x01);
   while(length--)
      memoryWriteData(value);
}

void fpgaRamSetAddress(uint32_t addr)
{
   memorySetHAddr((addr>>16) & 0xff);
   memorySetMAddr((addr>>8) & 0xff);
   memorySetLAddr(addr & 0xff);
}

void fpgaRamSetMode(uint8_t mode)
{
   memorySetMode(mode);
}

void fpgaWriteBuffer(uint8_t *buffer, uint16_t length)
{
    uint16_t i;

    for(i=0;i<length;i++)
        memoryWriteData(buffer[i]);
}
