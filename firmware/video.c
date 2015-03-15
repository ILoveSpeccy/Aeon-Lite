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
#include <stdarg.h>
#include <string.h>
#include "video.h"
#include "hal.h"

const unsigned char Frame[8] = {0x9C,0x8C,0xAC,0xAA,0x8E,0x8C,0x8D,0x95};

void videoWriteBuffer (unsigned char addr, char* buffer, unsigned char cnt)
{
    unsigned char i;
    comm_transfer_addr(RG_WRITE | addr);
    for(i=0;i<cnt;i++)
        comm_transfer_data(*buffer++);
}

void videoReadBuffer (unsigned char addr, char* buffer, unsigned char cnt)
{
    unsigned char i;
    comm_transfer_addr(RG_READ | addr);
    for(i=0;i<cnt;i++)
        *buffer++ = comm_transfer_data(0x00);
}

void videoSetCursor(unsigned char x, unsigned char y)
{
    videoSetX(x);
    videoSetY(y);
}

void videoPutChar(char chr, unsigned char attr)
{
    videoWriteAttr(attr);
    videoWriteChar(chr);
}

void videoPutString(unsigned char attr, char* str)
{
    while(*str)
        videoPutChar(*str++, attr);
}

void videoFill(char chr, unsigned char attr, unsigned char cnt)
{
    unsigned char i;
    for(i=0;i<cnt;i++)
        videoPutChar(chr, attr);
}

unsigned char videoColor(unsigned char color, unsigned char bgcolor)
{
    return ((bgcolor & 0x0F) << 4) | (color & 0x0F);
}

///  Window
/// ========

void videoWindowInit(WINDOW* window, unsigned char x, unsigned char y, unsigned char w, unsigned char h)
{
    videoSetMode(0x03);
    window->window_x = x;
    window->window_y = y;
    window->window_w = w;
    window->window_h = h;
    window->cursor_x = 0;
    window->cursor_y = 0;
}

void videoWindowClear(WINDOW* window, unsigned char attr)
{
    unsigned char i,j;
    for(i=0;i<window->window_h;i++)
    {
        videoSetCursor(window->window_x, window->window_y + i);
        for(j=0;j<window->window_w;j++)
            videoWindowPutChar(window, ' ', attr);
    }
}

void videoWindowScroll(WINDOW* window, unsigned char attr)
{
    char buffer[SCREEN_WIDTH];
    unsigned char i;

    videoSetMode(0x0F);
    for(i=1; i<window->window_h ; i++)
    {
        videoSetCursor(window->window_x, window->window_y + i);
        videoReadCharBuffer(buffer, window->window_w);
        videoSetCursor(window->window_x, window->window_y + i - 1);
        videoWriteCharBuffer(buffer, window->window_w);
        videoSetCursor(window->window_x, window->window_y + i);
        videoReadAttrBuffer(buffer, window->window_w);
        videoSetCursor(window->window_x, window->window_y + i - 1);
        videoWriteAttrBuffer(buffer, window->window_w);
    }
    videoSetMode(0x03);
    videoSetCursor(window->window_x, window->window_y + window->window_h - 1);
    for(i=0; i<window->window_w ; i++)
        videoPutChar(' ', attr);
}

void videoWindowPutChar(WINDOW* window, char chr, unsigned char attr)
{
    if ((window->cursor_x == window->window_w) || chr == '\n')
    {
        if (window->cursor_y == window->window_h - 1)
        {
            videoWindowScroll(window, attr);
            window->cursor_x = 0;
        }
        else
        {
            window->cursor_x = 0;
            window->cursor_y++;
        }
    }

    if (chr != '\n')
    {
        videoSetCursor(window->window_x + window->cursor_x, window->window_y + window->cursor_y);
        videoWriteAttr(attr);
        videoWriteChar(chr);
        window->cursor_x++;
    }
}

void videoWindowSetCursor(WINDOW* window, unsigned char x, unsigned char y)
{
    window->cursor_x = x;
    window->cursor_y = y;
    videoSetCursor(window->window_x + x, window->window_y + y);
}

void videoWindowSetX(WINDOW* window, unsigned char x)
{
    window->cursor_x = x;
    videoSetX(window->window_x + x);
}

void videoWindowSetY(WINDOW* window, unsigned char y)
{
    window->cursor_y = y;
    videoSetY(window->window_y + y);
}

void videoWindowPutString(WINDOW* window, unsigned char attr, char* str)
{
    while(*str)
        videoWindowPutChar(window, *str++, attr);
}

void videoWindowPrintf(WINDOW* window, unsigned char attr, char *str, ...)
{
    char buf[SCREEN_WIDTH + 1];
    va_list argzeiger;
    va_start(argzeiger,str);
    vsprintf(buf,str,argzeiger);
    va_end(argzeiger);
    const char *pbuf = buf;
    while(*pbuf)
        videoWindowPutChar(window, *pbuf++, attr);
}

void videoWindowFrame(WINDOW* window, unsigned char frame, unsigned char attr, char* title, unsigned char tattr)
{
    unsigned char i;

    videoSetCursor(window->window_x - 1, window->window_y - 1);
    videoPutChar(Frame[0], attr);
    videoFill(Frame[1], attr, window->window_w);
    videoPutChar(Frame[2], attr);
    for(i=0;i<window->window_h;i++)
    {
        videoSetCursor(window->window_x - 1, window->window_y + i);
        videoPutChar(Frame[7], attr);
        videoSetCursor(window->window_x + window->window_w, window->window_y + i);
        videoPutChar(Frame[3], attr);
    }
    videoSetCursor(window->window_x - 1, window->window_y +window->window_h);
    videoPutChar(Frame[6], attr);
    videoFill(Frame[5], attr, window->window_w);
    videoPutChar(Frame[4], attr);

    if (strcmp(title,""))
    {
        videoSetCursor(window->window_x + 1, window->window_y - 1);
        videoPutChar(' ', tattr);
        videoPutString(tattr, title);
        videoPutChar(' ', tattr);
    }
}
