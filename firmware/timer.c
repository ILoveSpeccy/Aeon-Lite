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
#include "hardware.h"

// Timer 1 Interrupt 1000Hz
/////////////////////////////////////////////////////////////

void __attribute__((interrupt, auto_psv)) _T1Interrupt (void)
{
	_T1IF = 0;			// Clear irq flag
	disk_timerproc();
}

// Timer 1 1000Hz Init
/////////////////////////////////////////////////////////////

void InitTimer(void)
{
   PR1 = FCY / 256 / 1000; // 1000Hz
   _TCKPS0 = 1;	         // Select prescaler Fcy/256
   _TCKPS1 = 1;            // --^
   _TON = 1;		         // Start Timer1
   _T1IE = 1;		         // Enable Timer1 interrupt
}
