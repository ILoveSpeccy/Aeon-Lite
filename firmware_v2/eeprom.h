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

#ifndef _EEPROM_H_
#define _EEPROM_H_

#define EEPROM_ADDRESS  0b10100000

uint8_t eepromWrite(uint8_t chip, uint16_t addr, uint8_t *buffer, uint8_t len);
uint8_t eepromRead(uint8_t chip, uint16_t addr, uint8_t *buffer, uint8_t len);

#endif // _EEPROM_H_
