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

#ifndef _USB_HANDLER_H_
#define _USB_HANDLER_H_

#define CMD_RTC_READ                      0x10
#define CMD_RTC_WRITE                     0x11
#define CMD_DATAFLASH_FILL_BUFFER         0x12
#define CMD_DATAFLASH_FLUSH_BUFFER        0x13
#define CMD_DATAFLASH_READ                0x14
#define CMD_SET_SPIMASTER                 0x15

#define CMD_FPGA_GET_STATUS               0xA0
#define CMD_FPGA_RESET                    0xA1
#define CMD_FPGA_WRITE_BITSTREAM          0xA2

void USB_Init(void);
void USB_Handler(void);

#endif // _USB_HANDLER_H_
