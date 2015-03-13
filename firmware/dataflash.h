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

#ifndef _DATAFLASH_H_
#define _DATAFLASH_H_

#define DataFlash_SPI_Read()     SPI1_Transfer(0xFF)
#define DataFlash_SPI_Write(a)   SPI1_Transfer(a)
#define DataFlash_Select()       Flash_Select
#define DataFlash_Deselect()     Flash_Deselect

#define DataFlash_Busy           (!(DataFlash_GetStatus() & 0x80))

void DataFlash_Init(void);
void DataFlash_PowerOfTwo(void);
void DataFlash_SoftReset(void);

unsigned char DataFlash_GetStatus(void);
void DataFlash_ChipErase(unsigned char wait);

void DataFlash_ReadBlock(unsigned long address, unsigned char *buffer, unsigned short length);
void DataFlash_ReadPage(unsigned long page, unsigned char *buffer);

void DataFlash_FillBuffer(unsigned short address, unsigned char *buffer, unsigned short length);
void DataFlash_FlushBuffer(unsigned long page);
void DataFlash_WritePage(unsigned long page, unsigned char *buffer);

#endif  // _DATAFLASH_H_
