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

#ifndef _RTC_H_
#define _RTC_H_

/// Real Time Clock (DS1337) (для других чипов нужно изменить адреса и т.д.)
#define RTC_CHIP_DS1337

#if defined(RTC_CHIP_DS1337)
   #define RTC_ADDRESS  0b11010000
#elif defined(RTC_CHIP_XXX)
   #define RTC_ADDRESS  0b00000000
#else
   #error "No RTC-Chip defined"
#endif

uint8_t rtcWrite(uint8_t addr, uint8_t len, uint8_t *buffer);
uint8_t rtcRead(uint8_t addr, uint8_t len, uint8_t *buffer);

#endif // _RTC_H_
