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

#include "bitstream.h"

const uint8_t header[13] = {0x00, 0x09, 0x0f, 0xf0,  0x0f, 0xf0,  0x0f, 0xf0,  0x0f, 0xf0, 0x00, 0x00, 0x01};

uint8_t readBitFileHeader(FIL *bitfile, struct bitinfo_struct *bitinfo)
{
   uint8_t buffer[13];
   uint8_t result;
   uint16_t value;

   // Read and Compare Bit File Header
   /////////////////////////////////////////////////////////////////////////////
   bitinfo->current_pos = 13;

   result = f_read(bitfile, buffer, 13, &value);
   if (result || value != 13)
      return 1;

   if (memcmp(buffer, header, 13))
      return 1;

   // Read Design Name
   /////////////////////////////////////////////////////////////////////////////
   result = f_read(bitfile, buffer, 3, &value);

   if (result || value != 3)
      return 1;

   if (buffer[0] != 0x61)
      return 1;

   bitinfo->current_pos += 3;
   bitinfo->design_name_pos = bitinfo->current_pos;
   value = (buffer[1] << 8) | buffer[2];
   bitinfo->design_name_length = value;
   bitinfo->current_pos += value;

   if (f_lseek(bitfile, bitinfo->current_pos))
      return 1;

   // Read Part Name
   /////////////////////////////////////////////////////////////////////////////
   result = f_read(bitfile, buffer, 3, &value);

   if (result || value != 3)
      return 1;

   if (buffer[0] != 0x62)
      return 1;

   bitinfo->current_pos += 3;
   bitinfo->part_name_pos = bitinfo->current_pos;
   value = (buffer[1] << 8) | buffer[2];
   bitinfo->part_name_length = value;
   bitinfo->current_pos += value;

   if (f_lseek(bitfile, bitinfo->current_pos))
      return 1;

   // Read Date
   /////////////////////////////////////////////////////////////////////////////
   result = f_read(bitfile, buffer, 3, &value);

   if (result || value != 3)
      return 1;

   if (buffer[0] != 0x63)
      return 1;

   bitinfo->current_pos += 3;
   bitinfo->date_pos = bitinfo->current_pos;
   value = (buffer[1] << 8) | buffer[2];
   bitinfo->date_length = value;
   bitinfo->current_pos += value;

   if (f_lseek(bitfile, bitinfo->current_pos))
      return 1;

   // Read Time
   /////////////////////////////////////////////////////////////////////////////
   result = f_read(bitfile, buffer, 3, &value);

   if (result || value != 3)
      return 1;

   if (buffer[0] != 0x64)
      return 1;

   bitinfo->current_pos += 3;
   bitinfo->time_pos = bitinfo->current_pos;
   value = (buffer[1] << 8) | buffer[2];
   bitinfo->time_length = value;
   bitinfo->current_pos += value;

   if (f_lseek(bitfile, bitinfo->current_pos))
      return 1;

   // Read Bitstream Data
   /////////////////////////////////////////////////////////////////////////////
   result = f_read(bitfile, buffer, 5, &value);

   if (result || value != 5)
      return 1;

   if (buffer[0] != 0x65)
      return 1;

   bitinfo->current_pos += 5;
   bitinfo->data_pos = bitinfo->current_pos;
   bitinfo->data_length = ((uint32_t)buffer[1] << 24) | ((uint32_t)buffer[2] << 16) | ((uint32_t)buffer[3] << 8) | (uint32_t)buffer[4];

   return 0;
}
