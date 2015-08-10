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
#include "hal.h"
#include "ui.h"
#include "curses.h"
#include "iniparser.h"
#include "fat/ff.h"
#include "fpga.h"
#include "debug.h"
#include "errors.h"
#include "timer.h"
#include "rtc.h"

char brd[8]     = {0x99,0x9D,0x8B,0x8A,0x8C,0x9D,0x98,0x8A};
char thinbrd[8] = {0xAA,0x94,0x8F,0x83,0xA9,0x94,0x90,0x83};

#define tabCount 6
const char tabItems[tabCount][15] = {"Configurations","Setup","Diagnose","Information","Help","Service"};
const uint8_t tabItemsPos[tabCount + 1] = {3, 21, 30, 42, 57, 65, 76};

#define CONFIG_FILE_NAME    "config.ini"
#define CONFIG_MAX          32
#define CONFIG_PAINT_MAX    19

typedef struct
{
   char name[CONFIG_MAX][24];
   uint8_t count;
   uint8_t currentItem;
   uint8_t startPosition;
   uint8_t currentPosition;
} CONFIGS;

struct
{
   char selected_section[80];
   char selected_key[80];
} ui;

static WINDOW* tabwin;
static WINDOW* mainwin;

static uint8_t key, lastkey;
static uint8_t tab_changed = 1;

static uint8_t timeBuffer[7];

enum states
{
   st_init = 0,   // Board initialisation, load service core
   st_autostart,
   st_ui,
   st_config,
   st_loop
};

static enum states state = st_init;
static enum states nextstate = st_init;

static uint8_t current_tab = 0;

/// ### Local Functions
/// ###########################################################################

// Main State Machine
uint8_t uiInit(void);
uint8_t uiAutoStart(void);
uint8_t uiMainLoop(void);
uint8_t uiConfig(void);
uint8_t uiLoop(void);

void uiPaintMainScreen(void);
void uiPaintTabs(uint8_t tab);

uint8_t tabHandlerConfigurations(void);
void paintConfigs(CONFIGS* conf);
void clearConfigs(void);
void paintStatusBar(char* status, uint8_t color, uint8_t bgcolor);

void tabHandlerSetup(void);
void tabHandlerDiagnose(void);
void tabHandlerInformation(void);
void tabHandlerHelp(void);
void tabHandlerService(void);

uint8_t readConfigurationFile(CONFIGS* conf);

/// ### State Machine
/// ############################################################################
void uiHandler(void)
{
   switch (state)
   {
      case st_init:
         if (uiInit())
            nextstate = st_autostart;
         else
            nextstate = st_loop;
         break;

      case st_autostart:
         if (uiAutoStart())
            nextstate = st_config;
         else
            nextstate = st_ui;
         break;

      case st_config:
         if (uiConfig())
            nextstate = st_loop;
         else
         {
            // ERROR!!!
            error_handler(5);
            nextstate = st_loop;
         }
         break;

      case st_ui:
         if (uiMainLoop())
            nextstate = st_config;
         break;

      case st_loop:
         uiLoop();
         break;
   }

   state = nextstate;
}

/// State ST_INIT
/// ============================================================================
uint8_t uiInit(void)
{
   spiMuxMcu;

   debug_print("\n\n\n");
   debug_print("=================================================\n");
   debug_print(" Aeon Lite - Open Source Reconfigurable Computer\n");
   debug_print("=================================================\n");
   debug_print(" http://www.speccyland.net '2015\n");
   debug_print(" v0.2.0 build 20150729 by ILoveSpeccy\n");
   debug_print("===============================================\n\n");
   debug_print("Welcome!!!\n");

   debug_print("Loading service configuration from DataFlash (slot 0)..\n");
   if (fpgaConfigureFromDataflash(0))
   {
      debug_print("Error. FPGA Configuration failed.\n");
      error_handler(4);
   }
   else
   {
      fpgaGetConfigId(); // Onetime dummy transfer. Needed for correctly communication with FPGA
      if (fpgaGetConfigId() != 0xEE)
      {
         debug_print("Error. Wrong service core ID\n");
         error_handler(3);
      }
      else
      {
         error_handler(0);
         debug_print("Initialisation done. Aeon Lite is now ready!\n");

         initscr();
         tabwin = newwin(0,1,80,28);
         mainwin = newwin(1,4,78,24);
         uiPaintMainScreen();
         uiPaintTabs(0);

         return TRUE;
      }
   }

   debug_print("Initialisation error. Board running in recovery mode\n");
   return FALSE;
}

/// State ST_AUTOSTART
/// Check for "autostart" key and load default configuration, when exists
/// ============================================================================
uint8_t uiAutoStart(void)
{
   uint8_t i = 0;

   debug_print("Search for \"autostart\" key...\n");

   while(1)
      if (!iniBrowseSections(CONFIG_FILE_NAME, i++, ui.selected_section))
         break;
      else
         if (iniGetKey(CONFIG_FILE_NAME, ui.selected_section, "autostart", 0, ui.selected_key))
            if (iniBool(ui.selected_key))
            {
               debug_print("\"autostart\" key found. Section: \"%s\"\n", ui.selected_section);
               return TRUE;
            }

   debug_print("No \"autostart\" key found.\n");
   return FALSE;
}

/// State ST_MAINLOOP
/// ============================================================================
uint8_t uiMainLoop(void)
{
   uint8_t result = FALSE;

   /// ============================================================================
   /// ============================================================================
   /// ============================================================================
   /// Temporary...
   /// If FPGA not configured, return.
   /// ============================================================================
   /// ============================================================================
   /// ============================================================================
   if (!pinConfDone)
      return result;

    key = videoKeybRd();
    if (lastkey != key)
    {
        if (videoKeybRd() & 0x08)
        {
            if (current_tab < 5)
                current_tab++;
            else
                current_tab = 0;

            uiPaintTabs(current_tab);
            tab_changed = 1;
        }
    }
    lastkey = key;

    switch (current_tab)
    {
        case 0: // Configurations
            result = tabHandlerConfigurations();
            break;

        case 1: // Setup
            tabHandlerSetup();
            break;

        case 2: // Diagnose (Selftest)
            tabHandlerDiagnose();
            break;

        case 3: // Information
            tabHandlerInformation();
            break;

        case 4: // Help
            tabHandlerHelp();
            break;

        case 5: // Service
            tabHandlerService();
            break;
    }
    tab_changed = 0;

   /// Clock
   /// -----------------------------------------------------
   if (timerGetClockTick())
   {
      timerResetClockTick();
      rtcRead(0, 7, timeBuffer);
      attrset(COLOR_YELLOW, COLOR_BLUE);
      mvprintw(74, 0, "%01X%01X%c%01X%01X", timeBuffer[2] >> 4, timeBuffer[2] & 0x0f, timerGetClockFlash()?':':' ', timeBuffer[1] >> 4, timeBuffer[1] & 0x0f);

   }

    return result;
}

/// State ST_CONFIG
/// ============================================================================
uint8_t uiConfig(void)
{
   static char buffer[80];
   static char filename[80];
   static uint32_t addr, length;
   static uint8_t mode, value;

   uint8_t index = 0;

   debug_print("Configuration state... Loading configuration \"%s\"\n", ui.selected_section);

   wprintw(mainwin, "Loading...\n");

   // =========================================================================
   // "ROM" Sections
   // =========================================================================
   while (iniGetKey(CONFIG_FILE_NAME, ui.selected_section, "rom", index++, buffer))
   {
      iniResolveROM(buffer, filename, &addr, &mode);
      debug_print("Load ROM from File \"%s\", Addr: 0x%06lX, Mode: %i\n", filename, addr, mode);
      fpgaInitRamFromFile(filename, addr, mode);
   }

   // =========================================================================
   // "RAMCLEAR" Sections
   // =========================================================================
   index = 0;

   while (iniGetKey(CONFIG_FILE_NAME, ui.selected_section, "ramclear", index++, buffer))
   {
      iniResolveRAM(buffer, &addr, &length, &value, &mode);
      debug_print("Clear RAM (0x%06lX, 0x%06lX, 0x%02X, %u)\n",  addr, length, value, mode);
      fpgaFillRam(addr, length, value, mode);
   }

   // =========================================================================
   // "BITSTREAM" & "RAWBITSTREAM" Sections
   // =========================================================================
   if (iniGetKey(CONFIG_FILE_NAME, ui.selected_section, "bitstream", 0, buffer))
      fpgaConfigureFromFile(buffer);
   else if (iniGetKey(CONFIG_FILE_NAME, ui.selected_section, "rawbitstream", 0, buffer))
      fpgaConfigureFromRawFile(buffer);
   else
   {
      waddstr(mainwin, "No bitstream section found\n");
      return FALSE;
   }

   // =========================================================================
   // "SPIMASTER" Section
   // =========================================================================
   iniGetKey(CONFIG_FILE_NAME, ui.selected_section, "spimaster", 0, buffer);

   if(!(strcmp(buffer,"fpga")))
      spiMuxFpga;
   else
      spiMuxMcu;

   __delay_ms(100);
   mcuReady;
   __delay_ms(100);

   return TRUE;
}

/// State ST_LOOP
/// ============================================================================
uint8_t uiLoop(void)
{
   /// Floppy for "Korvet PK-8020" here????
   return TRUE;
}

void uiPaintMainScreen(void)
{
    attrset(COLOR_YELLOW, COLOR_BLUE);
    mvprintw(0,       0, " Aeon Lite - Open Source Reconfigurable Computer                                ");
    mvprintw(0, LINES-1, " Service Core v2.0 build 20150709               http://www.speccyland.net '2015 ");

    wattrset(tabwin, COLOR_LIGHTGRAY, COLOR_BLACK);
    wborder(tabwin, brd);
}

void uiPaintTabs(uint8_t tab)
{
    uint8_t q;

    wmovecur(tabwin, 1, 1);
    wfillch(tabwin, ' ', 78);
    for(q=0;q<tabCount;q++)
    {
        if (q==tab)
            wattrset(tabwin, COLOR_BLACK, COLOR_LIGHTGRAY);
        else
            wattrset(tabwin, COLOR_GRAY, COLOR_BLACK);
        wmvprintw(tabwin, tabItemsPos[q], 1, "  %s  ", tabItems[q]);
    }
    wattrset(tabwin, COLOR_LIGHTGRAY, COLOR_BLACK);
    wmovecur(tabwin, 0, 2);
    waddch(tabwin, '\x97');
    for(q=1;q<tabItemsPos[tab]-1;q++)
        waddch(tabwin, '\x94');
    waddch(tabwin, '\xA9');
    for(q=tabItemsPos[tab];q<tabItemsPos[tab+1];q++)
        waddch(tabwin, ' ');
    waddch(tabwin, '\x90');
    for(q=tabItemsPos[tab+1]+1;q<79;q++)
        waddch(tabwin, '\x94');
    waddch(tabwin, '\x86');
    wmvaddch(tabwin, tabItemsPos[tab]-1, 1, '\xAA');
    wmvaddch(tabwin, tabItemsPos[tab+1], 1, '\x8F');
}

/// Configurations Tab
/// ============================================================================
uint8_t tabHandlerConfigurations(void)
{
    /// Проверить наличие карточки в слоте. Если карты нет, выставить флаг, что её нет и вывести сообщение на экран.
    /// Если есть, то попробовать считать конфигурационный файл. Если всё в норме, ставим флаг что конфа считана и выводится список с файлами.
    /// Если файла нет или ошибка в описании конфигураций или ешё чего подобное, то выводим сообщение на экран

    /// если карта в слоте и выставлен флаг готовности списка конфигураций, опрашиваются кнопки выбора

    static CONFIGS conf;
    static uint8_t sdcard_in_socket = 0;
    static uint8_t config_is_readed = 0;
    static uint8_t key, lastkey;

    if (tab_changed)
    {
        wattrset(mainwin, COLOR_GRAY, COLOR_BLACK);
        wclr(mainwin);
        wmvborder(mainwin, thinbrd, 1, 0, 30, 23);
        wmvborder(mainwin, thinbrd, 30, 0, 47, 23);
        wmvaddch(mainwin, 30, 0, '\x92');
        wmvaddch(mainwin, 30, 22, '\x91');
        wmvaddstr(mainwin, 1, 2, "\x93\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x95");
        waddstr(mainwin, "\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94");
        waddstr(mainwin, "\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x94\x84");

        wattrset(mainwin, COLOR_WHITE, COLOR_BLACK);
        wmvaddstr(mainwin, 4, 1, "Available Configurations");
        wmvaddstr(mainwin, 33, 1, "Description");

        sdcard_in_socket = pinSdcardDetect; // Force reading configurations from sd-card
    }

    if (!sdcard_in_socket && !pinSdcardDetect)     // SD-Card Inserted
    {
        __delay_ms(200);

        sdcard_in_socket = 1;

        // Try to Open "config.ini"
        if (readConfigurationFile(&conf))
        {
            config_is_readed = 1;
            paintConfigs(&conf);
            paintStatusBar("Use UP/DOWN/ENTER - Keys for configuration select", COLOR_WHITE, COLOR_GREEN);
        }
        else
        {
           clearConfigs();
           paintStatusBar("Configuration file error or not found", COLOR_BLACK, COLOR_LIGHTRED);
        }

    }

    if (sdcard_in_socket && pinSdcardDetect)     // SD-Card Removed
    {
        sdcard_in_socket = 0;
        config_is_readed = 0;
        clearConfigs();
        paintStatusBar("Please insert SD-Card", COLOR_BLACK, COLOR_YELLOW);
    }

    if (config_is_readed)
    {
        key = videoKeybRd();

        if (lastkey != key)
        {

            if (videoKeybRd() & 0x10)   // Down key pressed
            {
                if (conf.currentItem < (conf.count-1))
                {
                    conf.currentItem++;
                    if (conf.currentItem >= (conf.startPosition + CONFIG_PAINT_MAX))
                        conf.startPosition++;
                    else
                        conf.currentPosition++;

                    paintConfigs(&conf);
                }
            }
            else if (videoKeybRd() & 0x20)   // Up key pressed
            {
                if (conf.currentItem > 0)
                {
                    conf.currentItem--;
                    if (conf.currentItem < conf.startPosition)
                        conf.startPosition--;
                    else
                        conf.currentPosition--;

                    paintConfigs(&conf);
                }
            }
            else if (videoKeybRd() & 0x01)   // Enter key pressed
            {
                /// Configuration file selected. Parse INI and configure FPGA!!!
                  strcpy(ui.selected_section, conf.name[conf.currentItem]);
                  return TRUE;
//                ui.selected_section = conf.name[conf.currentItem];
               /// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            }
        }
        lastkey = key;
    }

    return FALSE;
}

uint8_t readConfigurationFile(CONFIGS* conf)
{
    uint8_t i;
    for(i=0; i<CONFIG_MAX; i++)
        if (!iniBrowseSections(CONFIG_FILE_NAME, i, conf->name[i]))
            break;
    conf->count = i;
    conf->currentItem = 0;
    conf->startPosition = 0;
    conf->currentPosition = 0;
    return i;
}

void paintConfigs(CONFIGS* conf)
{
   uint8_t i;
//   static char buffer[80];

   for(i=0; i< ((conf->count<CONFIG_PAINT_MAX) ? conf->count:CONFIG_PAINT_MAX);i++)
   {
       if (i==(conf->currentItem - conf->startPosition))
            wattrset(mainwin, COLOR_WHITE, COLOR_RED);
        else
            wattrset(mainwin, COLOR_GRAY, COLOR_BLACK);

        wmvprintw(mainwin, 3, i+3, " %-24s ", conf->name[conf->startPosition + i]);
   }

//    for(i=0;i<CONFIG_PAINT_MAX;i++)
//    if (!iniGetKey(CONFIG_FILE_NAME, conf->name[conf->currentItem], "description", i, buffer))
//        break;
//    else
//        wmvprintw(mainwin, 32, i+3, "%30s", buffer);
}

void clearConfigs(void)
{
   uint8_t i;

   for(i=0; i< CONFIG_PAINT_MAX;i++)
   {
        wattrset(mainwin, COLOR_GRAY, COLOR_BLACK);
        wmvprintw(mainwin, 3, i+3, " %-24s ", "");
   }
}

void paintStatusBar(char* status, uint8_t color, uint8_t bgcolor)
{
    wattrset(mainwin, color, bgcolor);
    wmvprintw(mainwin, 1, 23, " %-74s ", status);
}

/// Setup Tab
/// ============================================================================
void tabHandlerSetup(void)
{
    if (!tab_changed)
        return;

    wattrset(mainwin, COLOR_RED, COLOR_BLACK);
    wclr(mainwin);
    waddstr(mainwin, " Setup (coming soon)\n");
}

/// Diagnose Tab
/// ============================================================================
void tabHandlerDiagnose(void)
{
    if (!tab_changed)
        return;

    wattrset(mainwin, COLOR_CYAN, COLOR_BLACK);
    wclr(mainwin);
    waddstr(mainwin, " Diagnose (coming soon)\n");
}

/// Information Tab
/// ============================================================================
void tabHandlerInformation(void)
{
    if (!tab_changed)
        return;

    wattrset(mainwin, COLOR_GREEN, COLOR_BLACK);
    wclr(mainwin);
    waddstr(mainwin, " Information (coming soon)\n");
}

/// Help Tab
/// ============================================================================
void tabHandlerHelp(void)
{
    if (!tab_changed)
        return;

    wattrset(mainwin, COLOR_MAGENTA, COLOR_BLACK);
    wclr(mainwin);
    waddstr(mainwin, " Help (coming soon)\n");
}

/// Service Tab
/// ============================================================================
void tabHandlerService(void)
{
    if (!tab_changed)
        return;

    wattrset(mainwin, COLOR_BROWN, COLOR_BLACK);
    wclr(mainwin);
    waddstr(mainwin, " Service (coming soon)\n");
}
