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

#ifndef _INIPARSER_H_
#define _INIPARSER_H_

#define INI_BUFFER_SIZE 80

unsigned char iniBrowseSections(char* filename, unsigned char index, char* section);
unsigned char iniBrowseKeys(char* filename, char* section, unsigned char index, char* key, char* value);
unsigned char iniGetKey(char* filename, char* section, char* key, unsigned char index, char* value);
//unsigned char iniGetKey(char* filename, char* section, char* key, char* value);
unsigned char iniResolveROM(char* source, char* filename, unsigned long* address, unsigned char* offset);
unsigned char iniResolveRAM(char* source, unsigned long* address, unsigned long* length, unsigned char* value, unsigned char* offset);
unsigned char iniBool(char* source);
unsigned char iniCompare(char* value1, char* value2);
unsigned long iniLong(char* source);

#endif
