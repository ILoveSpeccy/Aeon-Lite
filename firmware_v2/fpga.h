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

#define GET_ID              0x00

#define MEM_INC_MODE        0x01
#define MEM_SET_ADDR_U      0x02
#define MEM_SET_ADDR_M      0x03
#define MEM_SET_ADDR_L      0x04
#define MEM_WRITE_DATA      0x05
#define MEM_READ_DATA       0x06

#define SCR_INC_MODE        0x10
#define SCR_X_WR            0x11
#define SCR_Y_WR            0x12
#define SCR_CHAR_PUT        0x13
#define SCR_REG_ATTR_WR     0x14
#define SCR_CHAR_WR         0x15
#define SCR_CHAR_RD         0x16
#define SCR_ATTR_WR         0x17
#define SCR_ATTR_RD         0x18
#define SCR_PAL_R_COLOR     0x19
#define SCR_PAL_G_COLOR     0x1A
#define SCR_PAL_B_COLOR     0x1B
#define SCR_CHARSET         0x1C

#define KBD_RD              0x20

#define fpgaGetConfigId()   commTransferReg(GET_ID              , 0xFF)

#define memorySetHAddr(a)   commTransferReg(MEM_SET_ADDR_U      , a)
#define memorySetMAddr(a)   commTransferReg(MEM_SET_ADDR_L      , a)
#define memorySetLAddr(a)   commTransferReg(MEM_SET_ADDR_M      , a)
#define memorySetMode(a)    commTransferReg(MEM_INC_MODE        , a)
#define memoryWriteData(a)  commTransferReg(MEM_WRITE_DATA      , a)
#define memoryReadData()    commTransferReg(MEM_WRITE_DATA      , 0xFF)

#define videoSetMode(a)     commTransferReg(SCR_INC_MODE        , a)
#define videoSetX(a)        commTransferReg(SCR_X_WR            , a)
#define videoSetY(a)        commTransferReg(SCR_Y_WR            , a)
#define videoPutChar(a)     commTransferReg(SCR_CHAR_PUT        , a)
#define videoSetAttr(a)     commTransferReg(SCR_REG_ATTR_WR     , a)
#define videoCharWr(a)      commTransferReg(SCR_CHAR_WR         , a)
#define videoAttrWr(a)      commTransferReg(SCR_ATTR_WR         , a)
#define videoCharRd()       commTransferReg(SCR_CHAR_RD         , 0xFF)
#define videoAttrRd()       commTransferReg(SCR_ATTR_RD         , 0xFF)
#define videoSetPalR(a)     commTransferReg(SCR_PAL_R_COLOR     , a)
#define videoSetPalG(a)     commTransferReg(SCR_PAL_G_COLOR     , a)
#define videoSetPalB(a)     commTransferReg(SCR_PAL_B_COLOR     , a)
#define videoKeybRd()       commTransferReg(KBD_RD              , 0xFF)

uint8_t fpgaReset(void);
void fpgaConfigure(uint8_t *buffer, uint16_t length);
uint8_t fpgaConfigureFromDataflash(uint8_t slot);
uint8_t fpgaConfigureFromFile(char *filename);
uint8_t fpgaConfigureFromRawFile(char *filename);
uint8_t fpgaInitRamFromFile(char* filename, uint32_t startaddr, uint8_t mode);
void fpgaFillRam(uint32_t startaddr, uint32_t length, uint8_t value, uint8_t mode);

void fpgaRamSetAddress(uint32_t addr);
void fpgaRamSetMode(uint8_t mode);
void fpgaWriteBuffer(uint8_t *buffer, uint16_t length);

#endif // _FPGA_H_
