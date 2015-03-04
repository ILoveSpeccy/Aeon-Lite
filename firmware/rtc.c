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
#include "rtc.h"

unsigned char RTC_Write(unsigned char addr, unsigned char *buffer, unsigned char len)
{
   unsigned char i;

   I2C_Start();

   I2C_WriteByte(RTC_ADDRESS | I2C_WRITE);
   I2C_WriteByte(addr);

   for(i=0;i<len;i++)
      I2C_WriteByte(*buffer++);

   I2C_Stop();

   return 0;
}

unsigned char RTC_Read(unsigned char addr, unsigned char *buffer, unsigned char len)
{
   unsigned char i;

   I2C_Start();

   I2C_WriteByte(RTC_ADDRESS | I2C_WRITE);
   I2C_WriteByte(addr);
   I2C_RepeatStart();
   I2C_WriteByte(RTC_ADDRESS | I2C_READ);

   if (len>1)
      for(i=0;i<(len-1);i++)
         *buffer++ = I2C_ReadByte(1);

   *buffer++ = I2C_ReadByte(0);

   I2C_Stop();

   return 0;
}
