typedef struct
{
  char filename[255];
  char part[255];
  char date[255];
  char time[255];
  unsigned long position;
  unsigned long  length;
} bithead;

unsigned char ReadBitHeader(bithead *BitHeader, char *FileName);
