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

#include "hardware.h"
#include "eeprom.h"

unsigned char EEPROM_Write(unsigned char chip, unsigned short addr, unsigned char *buffer, unsigned char len)
{
   unsigned char i;

   I2C_Start();

   I2C_WriteByte(EEPROM_ADDRESS | ((chip & 0x07) << 1) | I2C_WRITE);
   I2C_WriteByte((addr>>8) & 0xff);
   I2C_WriteByte(addr & 0xff);

   for(i=0;i<len;i++)
      I2C_WriteByte(*buffer++);

   I2C_Stop();

   // Wait for complete write process
   do {
      I2C_Start();
      i = I2C_WriteByte(EEPROM_ADDRESS | ((chip & 0x07) << 1) | I2C_WRITE);
      I2C_Stop();
   } while(!i);

   return 0;
}

unsigned char EEPROM_Read(unsigned char chip, unsigned short addr, unsigned char *buffer, unsigned char len)
{
   unsigned char i;

   I2C_Start();

   I2C_WriteByte(EEPROM_ADDRESS | ((chip & 0x07) << 1) | I2C_WRITE);
   I2C_WriteByte((addr>>8) & 0xff);
   I2C_WriteByte(addr & 0xff);
   I2C_RepeatStart();
   I2C_WriteByte(EEPROM_ADDRESS | ((chip & 0x07) << 1) | I2C_READ);

   if (len>1)
      for(i=0;i<(len-1);i++)
         *buffer++ = I2C_ReadByte(1);

   *buffer++ = I2C_ReadByte(0);

   I2C_Stop();

   return 0;
}
