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

// ==========================================================
// Vendor Part       Size     Man.ID  Dev.ID0  Dev.ID1  Pages
// ----------------------------------------------------------
// Adesto AT45DB161E 16Mbit   0x1F    0x26     0x00     4096
// Atmel  AT45DB161D 16Mbit   0x1F    0x26     0x00     4096
// Adesto AT45DB321E 32Mbit   0x1F    0x27     0x01     8192
// Atmel  AT45DB321D 32Mbit   0x1F    0x27     0x01     8192
// ==========================================================

#include <stdint.h>

void dataflashPowerOfTwo(void);
void dataflashSoftReset(void);
uint8_t dataflashGetStatus(void);
void dataflashChipErase(uint8_t wait);

void dataflashReadBlock(uint32_t address, uint8_t *buffer, uint16_t length);
void dataflashReadPage(uint16_t page, uint8_t *buffer);

void dataflashFillBuffer(uint16_t address, uint8_t *buffer, uint16_t length);
void dataflashFlushBuffer(uint16_t page);
void dataflashWritePage(uint16_t page, uint8_t *buffer);

#define dataflashIsBusy    (!(dataflashGetStatus() & 0x80))
#define dataflashInit()    dataflashSoftReset()

#endif  // _DATAFLASH_H_
