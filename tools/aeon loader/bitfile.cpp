#include "bitfile.h"

char xilinxHeader[13] = {0x00, 0x09, 0x0F, 0xF0, 0x0F, 0xF0, 0x0F, 0xF0, 0x0F, 0xF0, 0x00, 0x00, 0x01};

bitfile::bitfile()
{

}

bitfile::~bitfile()
{

}

bool bitfile::readBitFile(QString fileName)
{
    char buffer[256];
    int count;
    int length;

    QFile file(fileName);

    if (!file.open(QIODevice::ReadOnly)) {
        error = 1;
        return false;
    }

    file.read(buffer,13);
    for(count=0; count<13; count++)
        if (xilinxHeader[count] != buffer[count]) {
            error = 2;
            return false;
        }

    file.read(buffer,1);
    if (buffer[0] != 'a') {
        error = 3;
        return false;
    }

    file.read(buffer, 2);
    length = (buffer[0] << 8) | buffer[1];

    file.read(buffer, length);
    designName = QString::fromLatin1(buffer, length - 1);

    file.read(buffer,1);
    if (buffer[0] != 'b') {
        error = 4;
        return false;
    }

    file.read(buffer, 2);
    length = (buffer[0] << 8) | buffer[1];

    file.read(buffer, length);
    partName = QString::fromLatin1(buffer, length - 1);

    file.read(buffer,1);
    if (buffer[0] != 'c') {
        error = 5;
        return false;
    }

    file.read(buffer, 2);
    length = (buffer[0] << 8) | buffer[1];

    file.read(buffer, length);
    date = QString::fromLatin1(buffer, length - 1);

    file.read(buffer,1);
    if (buffer[0] != 'd') {
        error = 6;
        return false;
    }

    file.read(buffer, 2);
    length = (buffer[0] << 8) | buffer[1];

    file.read(buffer, length);
    time = QString::fromLatin1(buffer, length - 1);

    file.read(buffer,1);
    if (buffer[0] != 'e') {
        error = 7;
        return false;
    }

    file.read(buffer, 4);
    bitstreamLength = (buffer[0] << 24) | (buffer[1] << 16) | (buffer[2] << 8) | buffer[3];
    bitstreamStart = file.pos();

    file.close();
    error = 0;
    return true;
}

QString bitfile::getDesignName()
{
    return designName;
}

QString bitfile::getPartName()
{
    return partName;
}

QString bitfile::getDate()
{
    return date;
}

QString bitfile::getTime()
{
    return time;
}

unsigned long bitfile::getStartPos()
{
    return bitstreamStart;
}

unsigned long bitfile::getDataLength()
{
    return bitstreamLength;
}

unsigned char bitfile::getError()
{
    return error;
}
