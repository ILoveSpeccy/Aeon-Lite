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

#include "hardware.h"
#include <libpic30.h>

void Beep(void)
{
    OC1CON1 = 0;                    /// Clear OCxCON1 register
    OC1CON2 = 0;                    /// Clear OCxCON2 register
    OC1CON1bits.OCTSEL = 0b111;     /// Select peripheral clock (Fcy)
    OC1CON2bits.SYNCSEL = 0b11111;  /// Trigger/sync. source by this OCx module
    OC1R = 0;                       /// Set duty cycle
    OC1RS = 0xFF;                   /// Set period (OC1TMR counted up to 0xFF)
    OC1CON1bits.OCM = 0b110;        /// Edge-aligned PWM mode
    int i;
    for(i=1023;i>0;i--)
    {
        OC1R = i>>2;
        __delay_us(200);
        OC1R = 0;
        __delay_us(200);
    }
}
