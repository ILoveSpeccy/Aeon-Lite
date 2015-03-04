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
#include <stdlib.h>
#include "wd1793.h"
#include "bits.h"
#include "fat/ff.h"

// Status Bits
#define stsBusy            0
#define stsDRQ             1
#define stsIndexImpuls     1
#define stsTrack0          2
#define stsLostData        2
#define stsCRCError        3
#define stsSeekError       4
#define stsRecordNotFound  4
#define stsLoadHead        5
#define stsRecordType      5
#define stsWriteError      5
#define stsWriteProtect    6
#define stsNotReady        7

// State Values
#define stIDLE             0
#define stDELAY            1
#define stWRITETOCMDREG    2
#define stCMDTYPE1STATUS   4
#define stREADINGSECTOR    6

#define  SectorLength      1024
#define  SectorsPerTrack   5

unsigned char Delay;
unsigned char State;
unsigned char NextState;
unsigned char IndexCounter;
unsigned short CurrentByte;

unsigned char t;

   FATFS fss;
   FIL fsrcc;
   FRESULT res;
   unsigned char buf;
   unsigned char i;
   unsigned int br;

typedef struct
{
   unsigned char DataRegister;
   unsigned char SectorRegister;
   unsigned char TrackRegister;
   unsigned char CommandRegister;
   unsigned char StatusRegister;
   unsigned char RealTrack;        // Текущая дорожка, но которой находится головка
   unsigned char Direction;        // 0 = к центру, 1 = от центра
   unsigned char DRQ;
   unsigned char INTRQ;
   unsigned char Side;
}  WD1793_struct;

WD1793_struct WD1793;

unsigned char SIDE = 0;
unsigned char DRV = 5;

void WD1793_Config(unsigned char Value)
{
   SIDE = (Value >> 2) & 0b1;
   if (DRV != (Value & 0b11))
      {
         DRV = Value & 0b11;
         WD1793_Reset(DRV);
      }
}

unsigned long DiskPosition(unsigned char Sector, unsigned char Track, unsigned char Side)
{
   return (((unsigned long)Track * (10UL * 1024UL)) + ((unsigned long)Side * 5UL * 1024UL) + (unsigned long)Sector * 1024UL);
}

void WD1793_Reset(unsigned char drive)
{
   printf("Mount FileSystem... ");
   res = f_mount(&fss, "", 0);
   if (res)
      printf("error\n");
   else
      printf("ok!\n");

   printf("Open File disk%i.kdi... ", drive+1);
   if (drive == 0)
       f_open(&fsrcc, "disk1.kdi", FA_OPEN_EXISTING | FA_READ);
   else if (drive == 1)
       f_open(&fsrcc, "disk2.kdi", FA_OPEN_EXISTING | FA_READ);
   else if (drive == 2)
       f_open(&fsrcc, "disk3.kdi", FA_OPEN_EXISTING | FA_READ);
   else
       f_open(&fsrcc, "disk4.kdi", FA_OPEN_EXISTING | FA_READ);

   if (res)
      printf("error\n");
   else
      printf("ok!\n");
}

void WD1793_Execute(void)
{
   IndexCounter++;

   while(1)
   {
      switch (State)
      {
         case stIDLE :
            clear_bit(WD1793.StatusRegister, stsBusy);
            WD1793.DRQ = 0;
            WD1793.INTRQ = 1;
            return;

         case stWRITETOCMDREG : // Write to Command Register

            if ((WD1793.CommandRegister & 0xF0) == 0xD0) // Force Interrupt
            {
               State = stIDLE;
               break;
            }

            if (bit_is_set(WD1793.StatusRegister, stsBusy)) // Register Writing not allowed
               return;

            WD1793.StatusRegister = 0x01; // All bits clear but "Busy" set
            WD1793.INTRQ = 0;
            WD1793.DRQ = 0;

            switch (WD1793.CommandRegister & 0xF0) // Command Decoder
            {
               case 0x00: // Restore
                  WD1793.TrackRegister = 0;
                  WD1793.RealTrack = 0;
                  WD1793.Direction = 0;
                  Delay = 3;
                  NextState = stCMDTYPE1STATUS;
                  State = stDELAY;
                  break;

               case 0x10: // Seek
                  if (WD1793.TrackRegister > WD1793.DataRegister)
                     WD1793.Direction = 1;
                  else
                     WD1793.Direction = 0;

                  WD1793.TrackRegister = WD1793.DataRegister;
                  WD1793.RealTrack = WD1793.TrackRegister;
                  Delay = 3;
                  NextState = stCMDTYPE1STATUS;
                  State = stDELAY;
                  break;

               case 0x20:
               case 0x30: // Step
                  State = stIDLE;
                  break;

               case 0x40:
               case 0x50: // Step In
                  if (WD1793.TrackRegister < 80)
                     WD1793.TrackRegister++;
                  WD1793.RealTrack = WD1793.TrackRegister;
                  Delay = 3;
                  NextState = stCMDTYPE1STATUS;
                  State = stDELAY;
                  break;

               case 0x60:
               case 0x70: // Step Out
                  if (WD1793.TrackRegister > 0)
                     WD1793.TrackRegister--;
                  WD1793.RealTrack = WD1793.TrackRegister;
                  Delay = 3;
                  NextState = stCMDTYPE1STATUS;
                  State = stDELAY;
                  break;

               case 0x80:
               case 0x90: // Read Sector
  //                printf("RD SEC %i, TRK %i, SIDE %i - %ld\n", WD1793.SectorRegister, WD1793.TrackRegister, SIDE, DiskPosition(WD1793.SectorRegister - 1, WD1793.TrackRegister, SIDE?1:0) );
                  f_lseek(&fsrcc,DiskPosition(WD1793.SectorRegister - 1, WD1793.TrackRegister, SIDE?1UL:0UL));
                  //res = f_read(&fsrcc, buf, 1024, &br);
                  CurrentByte = 0;
                  Delay = 3;
                  NextState = stREADINGSECTOR;
                  State = stDELAY;
                  break;

               case 0xA0:
               case 0xB0: // Write Sector
                  State = stIDLE;
                  break;

               case 0xC0: // Read Address
                  State = stIDLE;
                  break;

               case 0xE0: // Read Track
                  State = stIDLE;
                  break;

               case 0xF0: // Write Track
                  State = stIDLE;
                  break;
            }

            break;

         case stCMDTYPE1STATUS:
         {
            if (IndexCounter & 0x0E)
               set_bit(WD1793.StatusRegister, stsIndexImpuls);

            if (WD1793.RealTrack == 0)
               set_bit(WD1793.StatusRegister, stsTrack0);

            State = stIDLE;
            break;
         }

         case stREADINGSECTOR:
         {
            if (CurrentByte == 1024)
            {
               State = stIDLE;
               break;
            }

//            if (!(CurrentByte & 0xFF))
//            {
//               pf_read(&TrackData, 1, &br);
//            }

            res = f_read(&fsrcc, &buf, 1, &br);
            WD1793.DataRegister = buf;
            CurrentByte++;
//            WD1793.DataRegister = TrackData[CurrentByte++&0xFF];
            WD1793.DRQ = 1;
            set_bit(WD1793.StatusRegister, stsDRQ);
            Delay = 3;
            NextState = stREADINGSECTOR;
            State = stDELAY;
            break;
         }

         case stDELAY :
         {
            if (Delay--)
               return;
            else
            {
               State = NextState;
               break;
            }
         }

      }
   }
}

// Hier werden die Register des WD1793 geschrieben
///////////////////////////////////////////////////////////////////////////////////////////

void WD1793_Write(unsigned char Address, unsigned char Value)
{
   WD1793_Execute();

//   printf("W%02X,%02X\n", Address & 0x03, Value);

   switch (Address & 0x03)
   {
      case 0 : // Write to Command Register
         WD1793.CommandRegister = Value;
         State = stWRITETOCMDREG;
         break;
      case 1 : // Write to Track Register
         WD1793.TrackRegister = Value;
         break;
      case 2 : // Write to Sector Register
         WD1793.SectorRegister = Value;
         break;
      case 3 : // Write to Data Register
         clear_bit(WD1793.StatusRegister, stsDRQ);
         WD1793.DRQ = 0;
         WD1793.DataRegister = Value;
         break;
   }
}

// Hier werden die Register des WD1793 gelesen
///////////////////////////////////////////////////////////////////////////////////////////

unsigned char WD1793_Read(unsigned char Address)
{
   unsigned char Value = 0xFF;

   WD1793_Execute();

   switch (Address & 0x03)
   {
      case 0 : // Read from Status Register
         WD1793.INTRQ = 0;
         Value = WD1793.StatusRegister;
         break;
      case 1 : // Read from Track Register
         Value = WD1793.TrackRegister;
         break;
      case 2 : // Read from Sector Register
         Value = WD1793.SectorRegister;
         break;
      case 3 : // Read from Data Register
         clear_bit(WD1793.StatusRegister, stsDRQ);
         WD1793.DRQ = 0;
         Value = WD1793.DataRegister;
         break;
   }
//   printf("R%02X,%02X\n", Address & 0x03, Value);

   return Value;
}
