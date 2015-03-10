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

#include "hal.h"
#include "timer.h"
#include "usb_handler.h"
#include <libpic30.h>
#include "fpga.h"
#include "startup.h"

int main(void)
{
   __delay_ms(200);     // startup delay, need for USB

   USB_Init();
   Controller_Init();
   Timer_Init();

   Startup();           // выбор прошивки для первоначальной загрузки FPGA / сервисная прошивка

   while(1)
      USB_Handler();
}
