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

#ifndef _FPGA_H_
#define _FPGA_H_

#define fpgaSetMode(a)                  commWriteRegister(0x10,a)
#define fpgaSetHAddr(a)                 commWriteRegister(0x11,a)
#define fpgaSetMAddr(a)                 commWriteRegister(0x12,a)
#define fpgaSetLAddr(a)                 commWriteRegister(0x13,a)
#define fpgaWriteData(a)                commWriteRegister(0x14,a)

#define fpgaGetMode()                   commReadRegister(0x10)
#define fpgaGetHAddr()                  commReadRegister(0x11)
#define fpgaGetMAddr()                  commReadRegister(0x12)
#define fpgaGetLAddr()                  commReadRegister(0x13)
#define fpgaReadData()                  commReadRegister(0x14)

unsigned char FPGA_Configure_from_DataFlash(unsigned char slot);
unsigned char FPGA_Configure_from_File(char *FileName);
void FPGA_Write_Bitstream(unsigned char *buffer, unsigned short length);
void FPGA_Reset(void);
unsigned char InitRAMFromFile(char* filename, unsigned long startaddr, unsigned char mode);
void FillRAM(unsigned long startaddr, unsigned long length, unsigned char value, unsigned char mode);
void RAMSetAddr(unsigned long addr, unsigned char mode);
void WriteRAMFromBuffer(unsigned char *buffer, unsigned short length);
void ReadRAMToBuffer(unsigned char *buffer, unsigned short length);

#endif // _FPGA_H_
