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
