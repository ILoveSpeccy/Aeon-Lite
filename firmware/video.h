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

#ifndef _VIDEO_H_
#define _VIDEO_H_

#define SCREEN_WIDTH  80
#define SCREEN_HEIGHT 30

typedef struct {
    unsigned char window_x;
    unsigned char window_y;
    unsigned char window_w;
    unsigned char window_h;
    unsigned char cursor_x;
    unsigned char cursor_y;
} WINDOW;

#define videoSetMode(a)                 commWriteRegister(0x00,a)
#define videoSetX(a)                    commWriteRegister(0x01,a)
#define videoSetY(a)                    commWriteRegister(0x02,a)
#define videoWriteAttr(a)               commWriteRegister(0x03,a)
#define videoWriteChar(a)               commWriteRegister(0x04,a)

#define videoGetMode()                  commReadRegister(0x00)
#define videoGetX()                     commReadRegister(0x01)
#define videoGetY()                     commReadRegister(0x02)
#define videoReadAttr()                 commReadRegister(0x03)
#define videoReadChar()                 commReadRegister(0x04)

void videoWriteBuffer (unsigned char addr, char* buffer, unsigned char cnt);
void videoReadBuffer (unsigned char addr, char* buffer, unsigned char cnt);

#define videoWriteCharBuffer(a,b)       videoWriteBuffer(0x04,a,b)
#define videoReadCharBuffer(a,b)        videoReadBuffer(0x04,a,b)
#define videoWriteAttrBuffer(a,b)       videoWriteBuffer(0x01,a,b)
#define videoReadAttrBuffer(a,b)        videoReadBuffer(0x01,a,b)

void videoSetCursor(unsigned char x, unsigned char y);
void videoPutChar(char chr, unsigned char attr);
void videoPutString(unsigned char attr, char* str);
void videoFill(char chr, unsigned char attr, unsigned char cnt);
unsigned char videoColor(unsigned char color, unsigned char bgcolor);

/// Window Functions
void videoWindowInit(WINDOW* window, unsigned char x, unsigned char y, unsigned char w, unsigned char h);
void videoWindowClear(WINDOW* window, unsigned char attr);
void videoWindowSetCursor(WINDOW* window, unsigned char x, unsigned char y);
void videoWindowSetX(WINDOW* window, unsigned char x);
void videoWindowSetY(WINDOW* window, unsigned char y);
void videoWindowScroll(WINDOW* window, unsigned char attr);
void videoWindowPutChar(WINDOW* window, char chr, unsigned char attr);
void videoWindowPutString(WINDOW* window, unsigned char attr, char* str);
void videoWindowPrintf(WINDOW* window, unsigned char attr, char *str, ...);
void videoWindowFrame(WINDOW* window, unsigned char frame, unsigned char attr, char* title, unsigned char tattr);

/// Colors
#define clBlack    0
#define clDBlue    1
#define clDGreen   2
#define clDCyan    3
#define clDRed     4
#define clDMagenta 5
#define clDYellow  6
#define clDWhite   7
#define clGray     8
#define clBBlue    9
#define clBGreen   10
#define clBCyan    11
#define clBRed     12
#define clBMagenta 13
#define clBYellow  14
#define clBWhite   15

#endif // _VIDEO_H_
