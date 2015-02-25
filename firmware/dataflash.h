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

/// HAL
#define     DataFlash_SPI_Read()       TransferSPI1(0xff)
#define     DataFlash_SPI_Write(a)     TransferSPI1(a)
#define     DataFlash_Select()         Flash_Select
#define     DataFlash_Deselect()       Flash_Deselect
/// End of HAL

#define     DataFlash_Busy             (!(DataFlash_GetStatus() & 0x8000))

void DataFlash_Init(void);
void DataFlash_SoftReset(void);
unsigned short DataFlash_GetStatus(void);
unsigned char DataFlash_ReadByte(unsigned long address);
void DataFlash_ReadPage(unsigned long address, unsigned char *buffer);
void DataFlash_WritePage(unsigned long address, unsigned char *buffer);

#endif  // _DATAFLASH_H_
