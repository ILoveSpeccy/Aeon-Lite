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

#define dataflashCsLow     pinDataFlashCs = 0
#define dataflashCsHigh    pinDataFlashCs = 1

// *****************************************************************************
// * Set Page Size to 512 Bytes ("Power of Two")
// *****************************************************************************
void dataflashPowerOfTwo(void)
{
   dataflashCsLow;
   spiTransfer(0x3D);
   spiTransfer(0x2A);
   spiTransfer(0x80);
   spiTransfer(0xA6);
   dataflashCsHigh;
}

// *****************************************************************************
// * Soft Reset
// *****************************************************************************
void dataflashSoftReset(void)
{
   dataflashCsLow;
   spiTransfer(0xF0);
   spiTransfer(0x00);
   spiTransfer(0x00);
   spiTransfer(0x00);
   dataflashCsHigh;
}

// *****************************************************************************
// * Get Current DataFlash Status
// *****************************************************************************
uint8_t dataflashGetStatus(void)
{
   uint8_t status;
   dataflashCsLow;
   spiTransfer(0xD7);
   status = spiTransfer(0xFF);
   dataflashCsHigh;
   return status;
}

// *****************************************************************************
// * Read Data Block form DataFlash
// *****************************************************************************
void dataflashReadBlock(uint32_t address, uint8_t *buffer, uint16_t length)
{
   uint16_t i;
   dataflashCsLow;
   spiTransfer(0x03);
   spiTransfer((address >> 16) & 0x3F);
   spiTransfer((address >> 8)  & 0xFF);
   spiTransfer( address        & 0xFF);
   for (i = 0 ; i < length ; i++)
      *buffer++ = spiTransfer(0xFF);
   dataflashCsHigh;
}

// *****************************************************************************
// * Read Page DataFlash
// *****************************************************************************
void dataflashReadPage(uint16_t page, uint8_t *buffer)
{
   uint32_t address = page * 512UL;
   dataflashReadBlock(address, buffer, 512);
}

// *****************************************************************************
// * Fill Buffer
// *****************************************************************************
void dataflashFillBuffer(uint16_t address, uint8_t *buffer, uint16_t length)
{
   uint16_t i;
   dataflashCsLow;
   spiTransfer(0x84);
   spiTransfer(0x00);
   spiTransfer(address >> 8);
   spiTransfer(address & 0xFF);
   for (i = 0 ; i < length ; i++)
      spiTransfer(*buffer++);
   dataflashCsHigh;
}

// *****************************************************************************
// * Flush Buffer (Write Data from Buffer to DataFlash)
// *****************************************************************************
void dataflashFlushBuffer(uint16_t page)
{
   dataflashCsLow;
   spiTransfer(0x83);
   spiTransfer((page >> 7) & 0x3F);
   spiTransfer(page << 1);
   spiTransfer(0x00);
   dataflashCsHigh;
   while(dataflashIsBusy);
}

// *****************************************************************************
// * Write Page to DataFlash
// *****************************************************************************
void dataflashWritePage(uint16_t page, uint8_t *buffer)
{
   dataflashFillBuffer(0, buffer, 512);
   dataflashFlushBuffer(page);
}

// *****************************************************************************
// * Erase DataFlash
// *****************************************************************************
void dataflashChipErase(uint8_t wait)
{
   dataflashCsLow;
   spiTransfer(0xC7);
   spiTransfer(0x94);
   spiTransfer(0x80);
   spiTransfer(0x9A);
   dataflashCsHigh;
   if (wait)
      while(dataflashIsBusy);
}
