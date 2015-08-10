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

#include "timer.h"
#include "fat/diskio.h"
#include "hal.h"

volatile uint16_t clockTickCounter = 0;
volatile uint8_t  clockTick = 0;
volatile uint8_t  clockFlash = 0;

// *****************************************************************************
// * Timer 1 Interrupt Handler
// *****************************************************************************
void __attribute__((interrupt, auto_psv)) _T1Interrupt (void)
{
   static uint16_t powerButtonTick = 0;

   _T1IF = 0;			   // Clear irq flag
   disk_timerproc();    // SD-Card Timeouts

   if (++clockTickCounter == 999)
   {
      clockTick = 1;
      clockTickCounter = 0;
      clockFlash = !clockFlash;
   }

   // Power Button handler
   if (powerButtonIsPressed)
      powerButtonTick++;

   if ((powerButtonIsPressed && powerButtonTick > 2000) ||
       (!powerButtonIsPressed && powerButtonTick != 0))
   {
      __asm__ volatile ("reset");
   }
}

// *****************************************************************************
// * Timer 1 Init (1000Hz)
// *****************************************************************************
void timerInit(void)
{
   PR1 = FCY / 256 / 1000;    // 1000Hz
   _TCKPS0 = 1;	            // Select prescaler FCY/256
   _TCKPS1 = 1;               // --^
   _TON = 1;		            // Start Timer1
   _T1IE = 1;		            // Enable Timer1 interrupt
}

void timerResetClockTick(void)
{
   clockTick = 0;
}

uint8_t timerGetClockTick(void)
{
   return clockTick;
}

uint8_t timerGetClockFlash(void)
{
   return clockFlash;
}
