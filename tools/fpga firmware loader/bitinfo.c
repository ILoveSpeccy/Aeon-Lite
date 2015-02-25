#include <stdio.h>
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>

#include "bitinfo.h"

unsigned char XilinxHeader[14] = {0, 9, 15, 240, 15, 240, 15, 240, 15, 240, 0, 0, 1, 97};
int FileHandle;
unsigned char BitstreamFileHeader[14];
unsigned char FieldLengthBytes[2], i;
int FieldLength;

unsigned char ReadBitHeader(bithead *BitHeader, char *FileName)
{
  BitHeader->position = 0;

  if ((FileHandle = open(FileName, O_RDONLY | O_BINARY)) == -1)
    return 1;

  read(FileHandle,BitstreamFileHeader,14);
  for(i=0;i<14;i++)
    if (!(XilinxHeader[i] == BitstreamFileHeader[i]))
    {
      close(FileHandle);
      return 2;
    }

  BitHeader->position+=14;

  if (!(read(FileHandle,FieldLengthBytes,2)))
  {
    close(FileHandle);
    return 3;
  }
  FieldLength = (FieldLengthBytes[0]<<8) + FieldLengthBytes[1];
  if (!(read(FileHandle,BitHeader->filename,FieldLength)))
  {
    close(FileHandle);
    return 3;
  }
  BitHeader->position+=FieldLength+2;

  lseek(FileHandle, 1, SEEK_CUR);
  if (!(read(FileHandle,FieldLengthBytes,2)))
  {
    close(FileHandle);
    return 3;
  }
  FieldLength = (FieldLengthBytes[0]<<8) + FieldLengthBytes[1];
  if (!(read(FileHandle,BitHeader->part,FieldLength)))
  {
    close(FileHandle);
    return 3;
  }
  BitHeader->position+=FieldLength+3;

  lseek(FileHandle, 1, SEEK_CUR);
  if (!(read(FileHandle,FieldLengthBytes,2)))
  {
    close(FileHandle);
    return 3;
  }
  FieldLength = (FieldLengthBytes[0]<<8) + FieldLengthBytes[1];
  if (!(read(FileHandle,BitHeader->date,FieldLength)))
  {
    close(FileHandle);
    return 3;
  }
  BitHeader->position+=FieldLength+3;

  lseek(FileHandle, 1, SEEK_CUR);
  if (!(read(FileHandle,FieldLengthBytes,2)))
  {
    close(FileHandle);
    return 3;
  }
  FieldLength = (FieldLengthBytes[0]<<8) + FieldLengthBytes[1];
  if (!(read(FileHandle,BitHeader->time,FieldLength)))
  {
    close(FileHandle);
    return 3;
  }
  BitHeader->position+=FieldLength+3;

  lseek(FileHandle, 1, SEEK_CUR);
  if (!(read(FileHandle,FieldLengthBytes,4)))
  {
    close(FileHandle);
    return 3;
  }
  FieldLength = (FieldLengthBytes[0]<<24) + (FieldLengthBytes[1]<<16) + (FieldLengthBytes[2]<<8) + FieldLengthBytes[3];
  BitHeader->length = FieldLength;
  BitHeader->position+=5;

  close(FileHandle);
  return 0;
}
