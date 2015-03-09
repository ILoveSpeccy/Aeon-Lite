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

#include "dataflash.h"
#include "hal.h"

void DataFlash_Init(void)
{
   /// Buffer and Page Size Configuration for 512 Bytes
   DataFlash_Select();
   DataFlash_SPI_Write(0x3D);
   DataFlash_SPI_Write(0x2A);
   DataFlash_SPI_Write(0x80);
   DataFlash_SPI_Write(0xA6);
   DataFlash_Deselect();
}

void DataFlash_SoftReset(void)
{
   DataFlash_Select();
   DataFlash_SPI_Write(0xF0);
   DataFlash_SPI_Write(0x00);
   DataFlash_SPI_Write(0x00);
   DataFlash_SPI_Write(0x00);
   DataFlash_Deselect();
}

unsigned short DataFlash_GetStatus(void)
{
   unsigned short status;
   DataFlash_Select();
   DataFlash_SPI_Write(0xD7);
   status = DataFlash_SPI_Read() << 8;
   status = (status & 0xff00) | DataFlash_SPI_Read();
   DataFlash_Deselect();
   return status;
}

unsigned char DataFlash_ReadByte(unsigned long address)
{
   unsigned char data;
   DataFlash_Select();
   DataFlash_SPI_Write(0x03);
   DataFlash_SPI_Write((address >> 16) & 0x1F);
   DataFlash_SPI_Write((address >> 8)  & 0xFF);
   DataFlash_SPI_Write( address        & 0xFF);
   data = DataFlash_SPI_Read();
   DataFlash_Deselect();
   return data;
}

void DataFlash_ReadBlock(unsigned long address, unsigned char *buffer, unsigned short length)
{
   unsigned short i;
   DataFlash_Select();
   DataFlash_SPI_Write(0x03);
   DataFlash_SPI_Write((address >> 16) & 0x1F);
   DataFlash_SPI_Write((address >> 8)  & 0xFF);
   DataFlash_SPI_Write( address        & 0xFF);
   for(i = 0 ; i < length ; i++)
      *buffer++ = DataFlash_SPI_Read();
   DataFlash_Deselect();
}

void DataFlash_ReadPage(unsigned long address, unsigned char *buffer)
{
   unsigned short i;
   DataFlash_Select();
   DataFlash_SPI_Write(0x03);
   DataFlash_SPI_Write((address >> 7) & 0x1F);
   DataFlash_SPI_Write(address << 1);
   DataFlash_SPI_Write(0x00);
   for(i=0;i<512;i++)
      *buffer++ = DataFlash_SPI_Read();
   DataFlash_Deselect();
}

void DataFlash_WritePage(unsigned long page, unsigned char *buffer)
{
   unsigned short i;

   // Fill Buffer
   DataFlash_Select();
   DataFlash_SPI_Write(0x84);
   DataFlash_SPI_Write(0x00);
   DataFlash_SPI_Write(0x00);
   DataFlash_SPI_Write(0x00);
   for(i=0;i<512;i++)
      DataFlash_SPI_Write(*buffer++);
   DataFlash_Deselect();

   // Flush
   DataFlash_Select();
   DataFlash_SPI_Write(0x83);
   DataFlash_SPI_Write((page >> 7) & 0x1F);
   DataFlash_SPI_Write(page << 1);
   DataFlash_SPI_Write(0x00);
   DataFlash_Deselect();
   while(DataFlash_Busy);
}

void DataFlash_FillBuffer(unsigned short address, unsigned char *buffer, unsigned short length)
{
   unsigned short i;

   DataFlash_Select();
   DataFlash_SPI_Write(0x84);
   DataFlash_SPI_Write(0x00);
   DataFlash_SPI_Write(address >> 8);
   DataFlash_SPI_Write(address & 0xFF);
   for(i = 0 ; i < length ; i++)
      DataFlash_SPI_Write(*buffer++);
   DataFlash_Deselect();
}

void DataFlash_FlushBuffer(unsigned long page)
{
   DataFlash_Select();
   DataFlash_SPI_Write(0x83);
   DataFlash_SPI_Write((page >> 7) & 0x1F);
   DataFlash_SPI_Write(page << 1);
   DataFlash_SPI_Write(0x00);
   DataFlash_Deselect();
   while(DataFlash_Busy);
}
