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
// PROG_B ----\_____/------------------------------------------------------------------------
// INIT_B -------\_____/---------------------------------------------------------------------
// CCLK   ______________/---\___/---\___/---\___/---\___/---\___/---\___/---\________________
// DIN    xxxxxxxxxxx<======><======><======><======><======><======>xxxxxxxxxxxxxxxxxxxxxxxx
// DONE   ______________________________________________________________/--------------------

/// Xilinx Spartan 6 XC6SLX9 Bitstream Length
/// 2742528 Bits (uncompressed)
/// 342816 Bytes
/// 670 Pages (of 8192 Pages Total) in DataFlash AT45DB321E

#include <string.h>
#include "hal.h"
#include "fat/ff.h"
#include "fpga.h"
#include "dataflash.h"

static unsigned char Buffer[512];

unsigned char FPGA_Configure_from_DataFlash(unsigned char slot)
{
    unsigned short i;
    SPI1_Setup(SPI_Speed_8MHz);
    FPGA_Reset();

    for(i=0;i<670;i++)
    {
        DataFlash_ReadPage(i, Buffer);
        FPGA_Write_Bitstream(Buffer, sizeof(Buffer));
    }

    for(i=0;i<10000;i++)
    {
        if (CONF_DONE)
            return 0;
    }
    return 1;
}

unsigned char FPGA_Configure_from_File(char *FileName)
{
   FATFS FileSystem;
   FIL InputFile;
   FRESULT Result;
   UINT Readed = 0;

   FPGA_Reset();

   f_mount(&FileSystem, "", 0);
   Result = f_open(&InputFile, FileName, FA_READ);
   if (Result)
      return Result;
   while(1)
   {
      Result = f_read(&InputFile, Buffer, sizeof(Buffer), &Readed);
      FPGA_Write_Bitstream(Buffer, sizeof(Buffer));

      if (Result || (Readed == 0))
         break;
   }
   f_close(&InputFile);
   f_mount(NULL, "",0);

   for(Readed=0;Readed<10000;Readed++)
   {
      if (CONF_DONE)
         return 0;
   }

   return 20;
}

void FPGA_Write_Bitstream(unsigned char *buffer, unsigned short length)
{
    unsigned short i;
    for(i=0;i<length;i++)
        SPI2_Transfer(buffer[i]);
}

void FPGA_Reset(void)
{
    PROG_B = 0;
    while(INIT_B);
    PROG_B = 1;
}

unsigned char InitRAMFromFile(char* filename, unsigned long startaddr, unsigned char mode)
{
    FATFS FileSystem;
    FIL InputFile;
    FRESULT Result;
    UINT Readed = 0;

    f_mount(&FileSystem, "", 0);
    Result = f_open(&InputFile, filename, FA_READ);
    if (Result)
        return Result;

    RAMSetAddr(startaddr, mode);

    while(1)
    {
        Result = f_read(&InputFile, Buffer, sizeof(Buffer), &Readed);
        WriteRAMFromBuffer(Buffer, sizeof(Buffer));

        if (Result || (Readed == 0))
            break;
    }
    f_close(&InputFile);
    f_mount(NULL, "",0);

    return 0;
}

void FillRAM(unsigned long startaddr, unsigned long length, unsigned char value, unsigned char mode)
{
    unsigned long l;

    RAMSetAddr(startaddr, mode);

    for(l=0;l<length;l++)
        fpgaWriteData(value);
}

void RAMSetAddr(unsigned long addr, unsigned char mode)
{
    fpgaSetMode(mode);
    fpgaSetHAddr((addr>>16) & 0xff);
    fpgaSetMAddr((addr>>8) & 0xff);
    fpgaSetLAddr(addr & 0xff);
}

void WriteRAMFromBuffer(unsigned char *buffer, unsigned short length)
{
    unsigned short i;

    for(i=0;i<length;i++)
        fpgaWriteData(buffer[i]);
}

void ReadRAMToBuffer(unsigned char *buffer, unsigned short length)
{
    unsigned short i;

    for(i=0;i<length;i++)
        buffer[i] = fpgaReadData();
}
