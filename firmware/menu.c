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

#include <string.h>
#include <stdio.h>
#include "menu.h"
#include "video.h"
#include "hardware.h"
#include "iniparser.h"

unsigned char KeyboardRead(void)
{
    Comm_transfer_addr(RG_READ | 0x20);
    return Comm_transfer_data(0xFF);
}

void GetAllConfigs(CONFIG *conf)
{
    printf("Get all sections from .ini file...\n");
    unsigned char i = 0;
    for(i=0;i<32;i++)
        if (!iniBrowseSections("config.ini", i, conf->Name[i]))
            break;

    printf("%i Sections found\n", i);
    conf->Count = i;
    conf->CurrentItem = 0;
    conf->StartPosition = 0;
    conf->CurrentPosition = 0;
}

void PaintMenu(WINDOW* window, CONFIG* config, unsigned char attr, unsigned char selattr)
{
   unsigned char i;

   for(i=0; i< ((config->Count<window->window_h) ? config->Count:window->window_h);i++)
   {
        videoWindowSetCursor(window,0,i);
        if (i==(config->CurrentItem - config->StartPosition))
        {
            videoFill(' ',selattr, window->window_w);
            videoWindowSetCursor(window,1,i);
            videoWindowPutString(window, selattr, config->Name[config->StartPosition + i]);
        }
        else
        {
            videoFill(' ',attr, window->window_w);
            videoWindowSetCursor(window,1,i);
            videoWindowPutString(window, attr, config->Name[config->StartPosition + i]);
        }
   }
}

void MainMenu(CONFIG* config, unsigned char attr, unsigned char selattr)
{
    unsigned char key;
    WINDOW menu;
    videoWindowInit(&menu,42,4,35,10);
    videoWindowFrame(&menu, 0, 0x09, "Configurations", 0x1A);
    videoWindowClear(&menu, 0x0E);

    GetAllConfigs(config);
    PaintMenu(&menu, config, attr, selattr);

    while(1)
    {
        key = KeyboardRead();

        if (key & 0b00000010) // Enter
            break;

        if (key & 0b00000100) // Up
        {
            if (config->CurrentItem > 0)
            {
                config->CurrentItem--;
                if (config->CurrentItem < config->StartPosition)
                    config->StartPosition--;
                else
                    config->CurrentPosition--;

                PaintMenu(&menu, config, attr, selattr);
            }
            while (KeyboardRead() & 0b00000100);
        }

        if (key & 0b00010000) // Down
        {
            if (config->CurrentItem < (config->Count-1))
            {
                config->CurrentItem++;
                if (config->CurrentItem >= (config->StartPosition + menu.window_h))
                    config->StartPosition++;
                else
                    config->CurrentPosition++;

                PaintMenu(&menu, config, attr, selattr);
            }
            while (KeyboardRead() & 0b00010000);
        }
    }
}
