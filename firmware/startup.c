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
#include <string.h>
#include "hal.h"
#include "startup.h"
#include "fpga.h"
#include "video.h"
#include "fat/ff.h"
#include "menu.h"
#include "iniparser.h"
#include <libpic30.h>

void Startup(void)
{
//   FPGA_Reset();
//   while(!PowerButton);
//   PowerLED_On;
//   printf("Aeon Lite booting...\n");

   SPI_Mux_PIC24;

   __delay_us(100);

   FPGA_Configure_from_DataFlash(0);         // Заливаем в FPGA сервисную прошивку из DataFlash (по-умолчанию из слота "0")

   // Рисуем рамку

   WINDOW screen;
   WINDOW workarea;
   CONFIG config;
   FATFS FileSystem;
   unsigned char res;
   char buffer[80];

   videoWindowInit(&screen, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
   videoWindowClear(&screen, 0x00);

   videoWindowSetCursor(&screen, 0,0);
   videoWindowPrintf(&screen, 0x1F, " Aeon Lite - Open Source Reconfigurable Computer                                ");
   videoWindowSetCursor(&screen, 0, SCREEN_HEIGHT - 1);
   videoWindowPutString(&screen, 0x1E, "                                                       www.speccyland.net '2015 ");

   videoWindowInit(&workarea, 0, 1, SCREEN_WIDTH, SCREEN_HEIGHT-2);
   videoWindowClear(&workarea, 0x00);
   videoWindowSetCursor(&workarea, 0, 1);
   videoWindowPrintf(&workarea, 0x07, "===============================\n");
   videoWindowPrintf(&workarea, 0x07, "Aeon Lite Service Configuration\n");
   videoWindowPrintf(&workarea, 0x07, "v0.2 by ILoveSpeccy '07.03.2015\n");
   videoWindowPrintf(&workarea, 0x07, "===============================\n\n");

   // Print charset
   // ====================================================================================================
   videoWindowSetCursor(&workarea,0 ,13);
   videoWindowPrintf(&workarea, 0x0F, "Charset:\n");
   unsigned short k;
   for(k=32;k<256;k++)
   {
      videoWindowPrintf(&workarea, 0x0D, "%02X=",k);
      videoWindowPrintf(&workarea, 0x8F, "%c",k);
      if (k!=255)
         videoWindowPrintf(&workarea, 0x0D, " ");
   }
   // ====================================================================================================

   videoWindowSetCursor(&workarea, 0, 5);

   // Проверяем наличие SD-карты

   videoWindowPrintf(&workarea, 0x07, "Detecting SD-Card..");

   res = f_mount(&FileSystem, "", 1);
   if (res)
   {
      videoWindowPrintf(&workarea, 0x07, " not found (%i)\n", res);
      return;
   }
   else
   {
      videoWindowPrintf(&workarea, 0x07,"found\n");
      f_getlabel("", buffer, 0);
      videoWindowPrintf(&workarea, 0x07,"Volume Label: %s\n", buffer);
      videoWindowPrintf(&workarea, 0x07,"Search \"config.ini\".. ");
      res = f_stat("config.ini", NULL);
      if (res)
      {
         videoWindowPrintf(&workarea, 0x07,"not found (%i)\n", res);
         return;
      }
      else
         videoWindowPrintf(&workarea, 0x07,"found\n");
   }
   f_mount(NULL, "",1);

   videoWindowPrintf(&workarea, 0x07, "Parsing Configuration File..\n");

   /// ##########################################################################
//   return;
   /// ##########################################################################

   MainMenu(&config, 0x07, 0x4F);

   unsigned long addr, length;
   unsigned char value, mode;
   char filename[80];

   unsigned char index = 0;

   while (iniGetKey("config.ini", config.Name[config.CurrentItem], "rom", index++, buffer))
   {
      iniResolveROM(buffer, filename, &addr, &mode);
      videoWindowPrintf(&workarea, 0x07, "Found \"ROM\" Key: Filename \"%s\", Addr: 0x%06lX, Mod: %02X\n", filename, addr, mode);
      InitRAMFromFile(filename, addr, mode);
   }

   if (iniGetKey("config.ini", config.Name[config.CurrentItem], "ramclear", 0, buffer))
   {
      iniResolveRAM(buffer, &addr, &length, &value, &mode);
      videoWindowPrintf(&workarea, 0x07, "Init RAM (0x%06lX, 0x%06lX, 0x%02X, %u)\n",  addr, length, value, mode);
      FillRAM(addr, length, value, mode);
   }

   iniGetKey("config.ini", config.Name[config.CurrentItem], "bitstream", 0, buffer);

   FPGA_Configure_from_File(buffer);

   iniGetKey("config.ini", config.Name[config.CurrentItem], "spimaster", 0, buffer);
   if(strcmp(buffer,"fpga"))
   {
      printf("SPI Master is PIC24\n");
      SPI_Mux_PIC24;
   }
   else
   {
      printf("SPI Master is FPGA\n");
      SPI_Mux_FPGA;
   }

   MCU_Ready;  // Загрузка окончена. Прошивка в FPGA может стартовать!
}
