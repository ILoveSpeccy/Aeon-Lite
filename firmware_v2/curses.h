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

#ifndef _CURSES_H_
#define _CURSES_H_

#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>

#define COLS                80
#define LINES               30

#define COLOR_BLACK         0
#define COLOR_BLUE          1
#define COLOR_GREEN         2
#define COLOR_CYAN          3
#define COLOR_RED           4
#define COLOR_MAGENTA       5
#define COLOR_BROWN         6
#define COLOR_GRAY          7
#define COLOR_LIGHTGRAY     8
#define COLOR_LIGHTBLUE     9
#define COLOR_LIGHTGREEN    10
#define COLOR_LIGHTCYAN     11
#define COLOR_LIGHTRED      12
#define COLOR_LIGHTMAGENTA  13
#define COLOR_YELLOW        14
#define COLOR_WHITE         15

typedef struct {
    uint8_t x;      // Window X Position
    uint8_t y;      // Window Y Position
    uint8_t w;      // Window Width
    uint8_t h;      // Window Height
    uint8_t curx;   // Cursor X Position
    uint8_t cury;   // Cursor Y Position
    uint8_t scroll; // On/Off Auto-Scroll
    uint8_t attr;   // Color Attributes
} WINDOW;

WINDOW* newwin(uint8_t x, uint8_t y, uint8_t w, uint8_t h);                         // Create new Window
void delwin(WINDOW* win);                                                           // Delete Window (Free Memory)
void initscr(void);                                                                 // Init stdscr (Screen)
void wmovecur(WINDOW* win, uint8_t x, uint8_t y);                                   // Move Cursor to Position (Window)
void movecur(uint8_t x, uint8_t y);                                                 // Move Cursor to Position (Screen)
void waddch(WINDOW* win, char ch);                                                  // Add Char to current Position (Window)
void addch(char ch);                                                                // Add Char to current Position (Screen)
void wmvaddch(WINDOW* win, uint8_t x, uint8_t y, char ch);                          // Move Cursor to Position and add Char (Window)
void mvaddch(uint8_t x, uint8_t y, char ch);                                        // Move Cursor to Position and add Char (Screen)
void wattrset(WINDOW* win, uint8_t color, uint8_t bgcolor);                         // Set Color Attribute (Window)
void attrset(uint8_t color, uint8_t bgcolor);                                       // Set Color Attribute (Screen)
void waddstr(WINDOW* win, char* str);                                               // Add String to current Position (Window)
void addstr(char* str);                                                             // Add String to current Position (Screen)
void wmvaddstr(WINDOW* win, uint8_t x, uint8_t y, char* str);                       // Move Cursor to Position and add String (Window)
void mvaddstr(uint8_t x, uint8_t y, char* str);                                     // Move Cursor to Position and add String (Screen)
void wprintw(WINDOW* win, char *str, ...);                                          // Printf to Window
void printw(char *str, ...);                                                        // Printf to Screen
void wmvprintw(WINDOW* win, uint8_t x, uint8_t y, char *str, ...);                  // Move Cursor and Printf to Window
void mvprintw(uint8_t x, uint8_t y, char *str, ...);                                // Move Cursor and Printf to Screen
void wclr(WINDOW* win);                                                             // Clear Window
void clr(void);                                                                     // Clear Screen
void wfillch(WINDOW* win, char ch, uint8_t n);                                      // Put Chars to Window
void fillch(char ch, uint8_t n);                                                    // Put Chars to Screen
void wborder(WINDOW* win, char* brd);                                               // Paint Border (Window)
void border(char* brd);                                                             // Paint Border (Screen)
void wmvborder(WINDOW* win, char* brd, uint8_t x, uint8_t y, uint8_t w, uint8_t h); // Paint Custom Border (Window)
void mvborder(char* brd, uint8_t x, uint8_t y, uint8_t w, uint8_t h);               // Paint Custom Border (Screen)
void wscroll(WINDOW* win);                                                          // Scroll Window
void scroll(void);                                                                  // Scroll Screen
void initcolor(uint8_t index, uint8_t r, uint8_t g, uint8_t b);                     // Set Color Values (RGB)

#endif // _CURSES_H_
