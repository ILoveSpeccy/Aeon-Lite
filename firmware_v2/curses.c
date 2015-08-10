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
#include "fpga.h"
#include "curses.h"

// Default Color Palette         -R-   -G-   -B-
const uint8_t palette[16][3] = {{0x00, 0x00, 0x00},
                                {0x02, 0x02, 0x09},
                                {0x03, 0x09, 0x00},
                                {0x03, 0x09, 0x09},
                                {0x09, 0x03, 0x03},
                                {0x09, 0x03, 0x09},
                                {0x09, 0x09, 0x03},
                                {0x07, 0x08, 0x08},
                                {0x0C, 0x0C, 0x0C},
                                {0x06, 0x03, 0x0F},
                                {0x03, 0x0F, 0x06},
                                {0x03, 0x0C, 0x0F},
                                {0x0F, 0x02, 0x04},
                                {0x0F, 0x02, 0x0D},
                                {0x0F, 0x0D, 0x02},
                                {0x0F, 0x0F, 0x0F}};

WINDOW* stdscr;
char buffer[COLS + 1];

/// # Local Functions
/// ###########################################################################
void fillChar(WINDOW* win, uint8_t x, uint8_t y, uint8_t len, char ch);
void fillAttr(WINDOW* win, uint8_t x, uint8_t y, uint8_t len, uint8_t attr);
void rdCharBuffer(WINDOW* win, uint8_t x, uint8_t y, uint8_t len, char* buf);
void wrCharBuffer(WINDOW* win, uint8_t x, uint8_t y, uint8_t len, char* buf);
void rdAttrBuffer(WINDOW* win, uint8_t x, uint8_t y, uint8_t len, char* buf);
void wrAttrBuffer(WINDOW* win, uint8_t x, uint8_t y, uint8_t len, char* buf);
/// ###########################################################################

void fillChar(WINDOW* win, uint8_t x, uint8_t y, uint8_t len, char ch)
{
    videoSetX(win->x + x);
    videoSetY(win->y + y);
    while(len--)
        videoCharWr(ch);
}

void fillAttr(WINDOW* win, uint8_t x, uint8_t y, uint8_t len, uint8_t attr)
{
    videoSetX(win->x + x);
    videoSetY(win->y + y);
    while(len--)
        videoAttrWr(attr);
}

void rdCharBuffer(WINDOW* win, uint8_t x, uint8_t y, uint8_t len, char* buf)
{
    videoSetX(win->x + x);
    videoSetY(win->y + y);
    while(len--)
        *buf++=videoCharRd();
}

void wrCharBuffer(WINDOW* win, uint8_t x, uint8_t y, uint8_t len, char* buf)
{
    videoSetX(win->x + x);
    videoSetY(win->y + y);
    while(len--)
        videoCharWr(*buf++);
}

void rdAttrBuffer(WINDOW* win, uint8_t x, uint8_t y, uint8_t len, char* buf)
{
    videoSetX(win->x + x);
    videoSetY(win->y + y);
    while(len--)
        *buf++=videoAttrRd();
}

void wrAttrBuffer(WINDOW* win, uint8_t x, uint8_t y, uint8_t len, char* buf)
{
    videoSetX(win->x + x);
    videoSetY(win->y + y);
    while(len--)
        videoAttrWr(*buf++);
}

/// # Global Functions
/// ###########################################################################
WINDOW* newwin(uint8_t x, uint8_t y, uint8_t w, uint8_t h)
{
    WINDOW* win = malloc(sizeof(WINDOW));

    win->x = x;
    win->y = y;
    win->w = w;
    win->h = h;
    win->curx = 0;
    win->cury = 0;
    win->scroll = 1;
    win->attr = 0x0F;

    return win;
}

void delwin(WINDOW* win)
{
    free(win);
}

void initscr(void)
{
    uint8_t i;

    stdscr = newwin(0,0,COLS, LINES);
    videoSetMode(0xFF);
    clr();

    // Set Default Color Palette
    for(i=0;i<16;i++)
        initcolor(i, palette[i][0], palette[i][1], palette[i][2]);
}

void wmovecur(WINDOW* win, uint8_t x, uint8_t y)
{
    win->curx = x;
    win->cury = y;
}

void movecur(uint8_t x, uint8_t y)
{
    wmovecur(stdscr, x, y);
}

void waddch(WINDOW* win, char ch)
{
    if ((win->curx == win->w) || (ch == '\n'))  // End of Line or String
    {
        win->curx = 0;

        if (win->cury == win->h - 1) // Last line. Scroll?
        {
            if (win->scroll)
            {
                wscroll(win);
            }
        }
        else
            win->cury++;
    }

    if (ch != '\n') // Put Char
    {
        videoSetX(win->x + win->curx);
        videoSetY(win->y + win->cury);
        videoSetAttr(win->attr);
        videoPutChar(ch);
        win->curx++;
    }
}

void addch(char ch)
{
    waddch(stdscr, ch);
}

void wmvaddch(WINDOW* win, uint8_t x, uint8_t y, char ch)
{
    wmovecur(win, x, y);
    waddch(win, ch);
}

void mvaddch(uint8_t x, uint8_t y, char ch)
{
    wmvaddch(stdscr, x, y, ch);
}

void wattrset(WINDOW* win, uint8_t color, uint8_t bgcolor)
{
    win->attr = ((bgcolor & 0x0F) << 4) | (color & 0x0F);
}

void attrset(uint8_t color, uint8_t bgcolor)
{
    wattrset(stdscr, color, bgcolor);
}

void waddstr(WINDOW* win, char* str)
{
    while(*str)
        waddch(win, *str++);
}

void addstr(char* str)
{
    waddstr(stdscr, str);
}

void wmvaddstr(WINDOW* win, uint8_t x, uint8_t y, char* str)
{
    wmovecur(win, x, y);
    waddstr(win, str);
}

void mvaddstr(uint8_t x, uint8_t y, char* str)
{
    wmvaddstr(stdscr, x, y, str);
}

void wclr(WINDOW* win)
{
    uint8_t x, y;

    wmovecur(win, 0, 0);

    for(y = 0; y < win->h; y++)
        for(x = 0; x < win->w; x++)
            waddch(win, ' ');

    wmovecur(win, 0, 0);
}

void clr(void)
{
    wclr(stdscr);
}

void vwprintw(WINDOW* win, char* str, va_list args)
{
    vsprintf(buffer, str, args);
    waddstr(win, buffer);
}

void wprintw(WINDOW* win, char *str, ...)
{
    va_list args;
    va_start(args, str);
    vwprintw(win, str, args);
    va_end(args);
}

void printw(char *str, ...)
{
    va_list args;
    va_start(args, str);
    vwprintw(stdscr, str, args);
    va_end(args);
}

void mvprintw(uint8_t x, uint8_t y, char *str, ...)
{
    movecur(x, y);
    va_list args;
    va_start(args, str);
    vwprintw(stdscr, str, args);
    va_end(args);
}

void wmvprintw(WINDOW* win, uint8_t x, uint8_t y, char *str, ...)
{
    wmovecur(win, x, y);
    va_list args;
    va_start(args, str);
    vwprintw(win, str, args);
    va_end(args);
}

void wfillch(WINDOW* win, char ch, uint8_t n)
{
    while(n--)
        waddch(win, ch);
}

void fillch(char ch, uint8_t n)
{
    wfillch(stdscr, ch, n);
}

void wborder(WINDOW* win, char* brd)
{
    wmvborder(win, brd, 0, 0, win->w, win->h);
}

void border(char* brd)
{
    wborder(stdscr, brd);
}

void wmvborder(WINDOW* win, char* brd, uint8_t x, uint8_t y, uint8_t w, uint8_t h)
{
    uint8_t i;

    wmovecur(win, x, y);
    waddch(win, brd[0]);
    wfillch(win, brd[1], w - 2);
    waddch(win, brd[2]);

    for(i=0; i<h-2; i++)
    {
        wmovecur(win, x, y+i+1);
        waddch(win,brd[7]);
        wmovecur(win, x+w-1, y+i+1);
        waddch(win,brd[3]);
    }

    wmovecur(win, x, y+h -1);
    waddch(win, brd[6]);
    wfillch(win, brd[5], w - 2);
    waddch(win, brd[4]);
}

void mvborder(char* brd, uint8_t x, uint8_t y, uint8_t w, uint8_t h)
{
    wmvborder(stdscr, brd, x, y, w, h);
}

void wscroll(WINDOW* win)
{
    char buf[COLS];
    uint8_t y;

    for(y=0;y<win->h-1;y++)
    {
        rdCharBuffer(win, 0, win->y + y + 1, win->w, buf);
        wrCharBuffer(win, 0, win->y + y, win->w, buf);
        rdAttrBuffer(win, 0, win->y + y + 1, win->w, buf);
        wrAttrBuffer(win, 0, win->y + y, win->w, buf);
    }

    fillChar(win, 0, win->h-1, win->w, ' ');
    fillAttr(win, 0, win->h-1, win->w, win->attr);
}

void scroll(void)
{
    wscroll(stdscr);
}

void initcolor(uint8_t index, uint8_t r, uint8_t g, uint8_t b)
{
    videoSetPalR(((index & 0x0F) << 4) | (r & 0x0F));
    videoSetPalG(((index & 0x0F) << 4) | (g & 0x0F));
    videoSetPalB(((index & 0x0F) << 4) | (b & 0x0F));
}
