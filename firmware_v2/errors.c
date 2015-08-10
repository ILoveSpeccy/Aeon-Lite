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

#include "errors.h"

void buzzer(uint16_t count, uint16_t period, uint8_t signal)
{
   while(count--)
   {
      pinBuzzer = signal;
      __delay_us(period);
      pinBuzzer = 0;
      __delay_us(period);
   }
}

void error_handler(uint8_t code)
{
   dirBuzzer = 0;
   pinBuzzer = 0;

   switch (code)
   {
      case 0:  // No Errors
         buzzer(250,250, 1);
         buzzer(250,250, 0);
         break;

      case 3:  // Wrong service configuration ID
         while(code--)
         {
            buzzer(250,175, 1);
            buzzer(250,175, 0);
         }
         break;

      case 4:  // Error service core FPGA configuration from DataFlash
         while(code--)
         {
            buzzer(250,175, 1);
            buzzer(250,175, 0);
         }
         break;

      case 5:  // FPGA Configuration error
         while(code--)
         {
            buzzer(250,175, 1);
            buzzer(250,175, 0);
         }
         break;
   }
}
