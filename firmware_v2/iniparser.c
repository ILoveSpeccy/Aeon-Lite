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

#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdlib.h>
#include "iniparser.h"
#include "fat/ff.h"

static char buffer[INI_BUFFER_SIZE];

// Local functions

void StringToLoverCase(char* p);
void RemoveLeadingSpaces(char* source);
void RemoveSpaces(char* source);
unsigned char GetSectionName(char* source);
unsigned char GetKey(char *source, char* value);

void StringToLoverCase(char* p)
{
    for ( ; *p; ++p) *p = tolower(*p);
}

void RemoveLeadingSpaces(char* source)
{
    unsigned char t = 0;
    char* i = source;
    char* j = source;
    while(*j != 0)
    {
        *i = *j++;
        if(*i > 32 || t)
        {
            t = 1;
            i++;
        }
    }
    *i = 0;
}

void RemoveSpaces(char* source)
{
    char* i = source;
    char* j = source;
    while(*j != 0)
    {
        *i = *j++;
        if(*i > 32)
            i++;
    }
    *i = 0;
}

unsigned char GetSectionName(char* source)
{
    unsigned char result = 0;
    char* i = source;
    char* j = source + 1;
    while(*j != 0 && *j != ']' && *j != ';' && *j != '#')
    {
        *i++ = *j++;
        if (*j == ']')
            result = 1;
    }
    *i = 0;
    return result;
}

unsigned char GetKey(char *source, char* value)
{
    unsigned char result = 0;
    char* i = source;
    char* j = source;
    char* k = value;
    while(*j != 0 && *j != ';' && *j != '#')
    {
        if (result)
            *k++ = *j;
        if (*j == ':' || *j == '=')
            result = 1;
        if (!result)
            *i++ = *j;
        j++;
    }
    *i = 0;
    *k = 0;
    return result;
}

// Global functions

unsigned char iniBrowseSections(char* filename, unsigned char index, char* section)
{
    FATFS FileSystem;
    FIL inifile;
    unsigned char count = 0;
    unsigned char result = 0;
    f_mount(&FileSystem, "", 0);
    if (f_open(&inifile, filename, FA_READ) == FR_OK)
    {
        while(f_gets(buffer, INI_BUFFER_SIZE, &inifile))
        {
            RemoveLeadingSpaces(buffer);
            if (buffer[0] == '[')
            {
                strcpy(section, buffer);
                if (GetSectionName(section))
                    if (count++ == index)
                    {
                        result = 1;
                        break;
                    }
            }
        }
       f_close(&inifile);
    }
    return result;
}

unsigned char iniBrowseKeys(char* filename, char* section, unsigned char index, char* key, char* value)
{
    FATFS FileSystem;
    unsigned char count = 0;
    unsigned char result = 0;
    FIL inifile;
    f_mount(&FileSystem, "", 0);
    if (f_open(&inifile, filename, FA_READ) == FR_OK)
    {
        while(f_gets(buffer, INI_BUFFER_SIZE, &inifile) && !result)
        {
            RemoveLeadingSpaces(buffer);
            if (buffer[0] == '[')
            {
                GetSectionName(buffer);
                if (!strcmp(section, buffer)) // Section found!
                    while(f_gets(buffer, INI_BUFFER_SIZE, &inifile))
                    {
                        RemoveSpaces(buffer);
                        StringToLoverCase(buffer);
                        if (buffer[0] == '[')
                            break;

                        if (buffer[0] != 0 && buffer[0] != ';' && buffer[0] != '#')
                        {
                            strcpy(key, buffer);
                            if (GetKey(key, value))
                                if (count++ == index)
                                {
                                    result = 1;
                                    break;
                                }
                        }
                    }
            }
        }
    f_close(&inifile);
    }
    return result;
}

unsigned char iniGetKey(char* filename, char* section, char* key, unsigned char index, char* value)
{
    char tmp[INI_BUFFER_SIZE];
    unsigned char count = 0;
    int s = 0;
    int k;

    while(iniBrowseSections(filename, s++, tmp))
    {
        if (!strcmp(tmp, section))
        {
            k = 0;
            while(iniBrowseKeys(filename, section, k++, tmp, value))
                if (!strcmp(tmp, key))
                     if (count++ == index)
                        return 1;
        }
    }
    return 0;
}

unsigned char iniResolveROM(char* source, char* filename, unsigned long* address, unsigned char* offset)
{
    char* i = source;
    char* j = buffer;
    unsigned char param = 0;

    while(*i != 0)
    {
        *j++ = *i++;
        if(*i == ',')
        {
            *j = 0;
            i++;
            if (++param == 1)
                strcpy(filename, buffer);
            else
            {
                *address = iniLong(buffer);
                if (*i == '0')
                    *offset = 0b00000000;
                else
                    *offset = 0b00000001;
                return 1;
            }
            j = buffer;
        }
    }
    return 0;
}

unsigned char iniResolveRAM(char* source, unsigned long* address, unsigned long* length, unsigned char* value, unsigned char* offset)
{
    char* i = source;
    char* j = buffer;
    unsigned char param = 0;

    while(*i != 0)
    {
        *j++ = *i++;
        if(*i == ',')
        {
            *j = 0;
            i++;
            if (++param == 1)
                *address = iniLong(buffer);
            else if (param == 2)
            {
                *length = iniLong(buffer);
            }
            else
            {
                *value = iniLong(buffer);
                if (*i == '0')
                    *offset = 0b00000000;
                else
                    *offset = 0b00000001;
                return 1;
            }
            j = buffer;
        }
    }
    return 0;
}

unsigned char iniBool(char* source)
{
    if (!strcmp(source, "true") || !strcmp(source, "yes") || !strcmp(source, "1"))
        return 1;
    return 0;
}

unsigned char iniCompare(char* value1, char* value2)
{
    if (!strcmp(value1, value2))
        return 1;
    return 0;
}

unsigned long iniLong(char* source)
{
    if (source[1] == 'x')
        return strtoul(&buffer[2], NULL, 16);
    else
        return strtoul(buffer, NULL, 10);
}

