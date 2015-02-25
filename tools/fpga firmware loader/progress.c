#include <stdio.h>
#include <string.h>
#include "progress.h"

void progress_bar(int progress)
{
  char bar[255];
  unsigned char i;
  strcpy(bar,"Progress | ");
  for(i=0;i<50;i++)
  {
    if((i*2)<progress)
      strcat(bar,"#");
    else
      strcat(bar," ");
  }
  printf("\r");
  printf(bar);
  printf(" | %3i%%", progress);
}

void progress(int maxvalue, int progress)
{
  static int last_value, value;
  value = (progress * 100)/ maxvalue;
  if(value != last_value)
    progress_bar(value);
  last_value = value;
}
