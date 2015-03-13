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

#ifndef BITFILE_H
#define BITFILE_H

#include <QtCore>

class bitfile
{
    public:
        bitfile();
        ~bitfile();

        bool readBitFile(QString fileName);
        QString getDesignName(void);
        QString getPartName(void);
        QString getDate(void);
        QString getTime(void);
        unsigned long getStartPos(void);
        unsigned long getDataLength(void);
        unsigned char getError(void);

    private:
        QString designName;
        QString partName;
        QString date;
        QString time;
        unsigned long bitstreamLength;
        unsigned long bitstreamStart;
        unsigned char error;
};

#endif // BITFILE_H
