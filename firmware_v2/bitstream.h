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

#ifndef _BITSTREAM_H_
#define _BITSTREAM_H_

#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "fat/ff.h"

struct bitinfo_struct{
   uint16_t current_pos;
   uint16_t design_name_pos;
   uint16_t design_name_length;
   uint16_t part_name_pos;
   uint16_t part_name_length;
   uint16_t date_pos;
   uint16_t date_length;
   uint16_t time_pos;
   uint16_t time_length;
   uint16_t data_pos;
   uint32_t data_length;
};

uint8_t readBitFileHeader(FIL *bitfile, struct bitinfo_struct *bitinfo);

#endif // _BITSTREAM_H_
