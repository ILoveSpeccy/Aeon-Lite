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

#include <stdio.h>
#include "hardware.h"
#include "timer.h"
#include "usb_handler.h"
#include "fpga.h"

int main(void)
{
   USB_Init();
   InitController();
   InitTimer();

//   FPGA_Reset();
//   while(!PowerButton);

   PowerLED_On;

   printf("Aeon Lite booting...\n");

   SPI_Mux_PIC24;
   FPGA_Configure_from_File("firmware.bin");
   SPI_Mux_FPGA;

   while(1)
      USB_Handler();
}
