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

#ifndef _HARDWARE_H_
#define _HARDWARE_H_

#if defined (__PIC24FJ128GB106__)
#include <P24FJ128GB106.h>
#elif defined(__PIC24FJ256GB106__)
#include <P24FJ256GB106.h>
#elif defined(__PIC24FJ128GB206__)
#include <P24FJ128GB206.h>
#elif defined(__PIC24FJ256GB206__)
#include <P24FJ256GB206.h>
#else
    #error "Unsupported MCU"
#endif

#define FCY                     16000000UL

#define Input                   1
#define Output                  0
#define High                    1
#define Low                     0

/// # Controller I/O Configuration
/// ############################################################################

// Power Button
#define TrisPowerButton         TRISEbits.TRISE5
#define PowerButton             (!PORTEbits.RE5)

// Power LED
#define TrisPowerLED            TRISGbits.TRISG9
#define PowerLED                LATGbits.LATG9
#define PowerLED_On             PowerLED = 1
#define PowerLED_Off            PowerLED = 0

// User LED 1 (Red)
#define TrisUserLED1            TRISDbits.TRISD7
#define UserLED1                LATDbits.LATD7
#define UserLED1_On             UserLED1 = 0
#define UserLED1_Off            UserLED1 = 1

// User LED 2 (Yellow)
#define TrisUserLED2            TRISFbits.TRISF0
#define UserLED2                LATFbits.LATF0
#define UserLED2_On             UserLED2 = 0
#define UserLED2_Off            UserLED2 = 1

// User LED 3 (Green)
#define TrisUserLED3            TRISFbits.TRISF1
#define UserLED3                LATFbits.LATF1
#define UserLED3_On             UserLED3 = 0
#define UserLED3_Off            UserLED3 = 1

// Buzzer
#define TrisBuzzer              TRISFbits.TRISF3
#define Buzzer                  LATFbits.LATF3

// FPGA Configuration & SPI-Communication

#define TrisM0                  TRISDbits.TRISD10
#define M0                      LATDbits.LATD10
#define Comm_CSA                LATDbits.LATD10

#define TrisM1                  TRISDbits.TRISD0
#define M1                      LATDbits.LATD0
#define Comm_CSD                LATDbits.LATD0

#define TrisCCLK                TRISDbits.TRISD9
#define CCLK                    LATDbits.LATD9

#define TrisDIN                 TRISDbits.TRISD11
#define DIN                     LATDbits.LATD11

#define TrisPROG_B              TRISDbits.TRISD6
#define PROG_B                  LATDbits.LATD6

#define TrisINIT_B              TRISDbits.TRISD5
#define INIT_B                  PORTDbits.RD5
#define Comm_REQ                PORTDbits.RD5

#define TrisCONF_DONE           TRISDbits.TRISD8
#define CONF_DONE               PORTDbits.RD8

// SD-Card & SPI-Falsh
#define TrisSPI_Mux             TRISEbits.TRISE4
#define SPI_Mux                 LATEbits.LATE4
#define SPI_Mux_PIC24           SPI_Mux = 0
#define SPI_Mux_FPGA            SPI_Mux = 1

#define TrisSDCard_CS           TRISEbits.TRISE3
#define SDCard_CS               LATEbits.LATE3
#define SDCard_Select           SDCard_CS = 0
#define SDCard_Deselect         SDCard_CS = 1

#define TrisFlash_CS            TRISEbits.TRISE2
#define Flash_CS                LATEbits.LATE2
#define Flash_Select            Flash_CS = 0
#define Flash_Deselect          Flash_CS = 1

#define TrisSDCardDetect        TRISEbits.TRISE1
#define SDCardDetect            (!PORTEbits.RE1)

#define TrisSDCardWriteProtect  TRISEbits.TRISE1
#define SDCardWriteProtect      (!PORTEbits.RE1)

#define TrisSPI1_MOSI           TRISGbits.TRISG6
#define SPI1_MOSI               LATGbits.LATG6
#define PPS_SPI1_MOSI           PPS_RP21

#define TrisSPI1_MISO           TRISGbits.TRISG8
#define SPI1_MISO               LATGbits.LATG8
#define PPS_SPI1_MISO           PPS_RP19

#define TrisSPI1_SCK            TRISGbits.TRISG7
#define SPI1_SCK                LATGbits.LATG7
#define PPS_SPI1_SCK            PPS_RP26

void InitController(void);
void InitPPS(void);
void InitIO(void);

void InitSPI2(void);
unsigned char TransferSPI2(unsigned char data);
unsigned char Comm_transfer_addr(unsigned char addr);
unsigned char Comm_transfer_data(unsigned char data);
unsigned char commWriteRegister(unsigned char reg, unsigned char value);
unsigned char commReadRegister(unsigned char reg);

#define RG_READ 0
#define RG_WRITE 0x80
#define videoTransferAddr(a) Comm_transfer_addr(a)
#define videoTransferData(d) Comm_transfer_data(d)

void InitSPI1(void);
void SetupSPI1(unsigned char data);
unsigned char TransferSPI1(unsigned char data);

void InitUART(void);

/// ################################################################################################
/// # I2C (EEPROM & RTC)
/// ################################################################################################
#define I2C_WRITE               0
#define I2C_READ                1


void I2C_Init(void);
void I2C_Start(void);
void I2C_RepeatStart(void);
unsigned char I2C_WriteByte(unsigned char value);
unsigned char I2C_ReadByte(unsigned char ack);
void I2C_Stop(void);
void I2C_Idle(void);
unsigned char I2C_AckStatus(void);

#endif //_HARDWARE_H_
