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

#ifndef _HAL_H_
#define _HAL_H_

#if defined (__PIC24FJ128GB106__)
#include <P24FJ128GB106.h>
#elif defined(__PIC24FJ192GB106__)
#include <P24FJ192GB106.h>
#elif defined(__PIC24FJ256GB106__)
#include <P24FJ256GB106.h>
#elif defined(__PIC24FJ128GB206__)
#include <P24FJ128GB206.h>
#elif defined(__PIC24FJ256GB206__)
#include <P24FJ256GB206.h>
#else
    #error "Unsupported MCU"
#endif

// CPU clock
#define FCY                      16000000UL

// I/O pin direction
#define pd_input                 1
#define pd_output                0

/// Global functions
/// ############################################################################

void Controller_Init(void);

/// # Controller I/O Configuration
/// ############################################################################

// Power Button
#define pd_PowerButton           TRISEbits.TRISE5
#define PowerButton              (!PORTEbits.RE5)

// Power LED
#define pd_PowerLED              TRISGbits.TRISG9
#define PowerLED                 LATGbits.LATG9
#define PowerLED_On              PowerLED = 1
#define PowerLED_Off             PowerLED = 0

// User LED 1 (Red)
#define pd_UserLED1              TRISDbits.TRISD7
#define UserLED1                 LATDbits.LATD7
#define UserLED1_On              UserLED1 = 0
#define UserLED1_Off             UserLED1 = 1

// User LED 2 (Yellow)
#define pd_UserLED2              TRISFbits.TRISF0
#define UserLED2                 LATFbits.LATF0
#define UserLED2_On              UserLED2 = 0
#define UserLED2_Off             UserLED2 = 1

// User LED 3 (Green)
#define pd_UserLED3              TRISFbits.TRISF1
#define UserLED3                 LATFbits.LATF1
#define UserLED3_On              UserLED3 = 0
#define UserLED3_Off             UserLED3 = 1

// Buzzer
#define pd_Buzzer                TRISFbits.TRISF3
#define Buzzer                   LATFbits.LATF3

// MCU Ready
#define pd_MCU_Ready             TRISCbits.TRISC13
#define MCU_Ready                LATCbits.LATC13 = 1
#define MCU_NotReady             LATCbits.LATC13 = 0

/// === SD-Card & SPI-Flash (SPI1)
/// ============================================================================

// SPI Mux - select SPI master: MCU / FPGA
#define pd_SPI_Mux               TRISEbits.TRISE4
#define SPI_Mux                  LATEbits.LATE4
#define SPI_Mux_PIC24            SPI_Mux = 0
#define SPI_Mux_FPGA             SPI_Mux = 1

// SD-Card chip select
#define pd_SDCard_CS             TRISEbits.TRISE3
#define SDCard_CS                LATEbits.LATE3
#define SDCard_Select            SDCard_CS = 0
#define SDCard_Deselect          SDCard_CS = 1

// Flash chip select
#define pd_Flash_CS              TRISEbits.TRISE2
#define Flash_CS                 LATEbits.LATE2
#define Flash_Select             Flash_CS = 0
#define Flash_Deselect           Flash_CS = 1

// SD-Card detect
#define pd_SDCard_Detect         TRISEbits.TRISE1
#define SDCard_Detect            (!PORTEbits.RE1)

// SD-Card write protect
#define pd_SDCard_WriteProtect   TRISEbits.TRISE0
#define SDCard_WriteProtect      (!PORTEbits.RE0)

#define SPI_Speed_8MHz           0b11011
#define SPI_Speed_250KHz         0b11100

void SPI1_Init(void);
void SPI1_Setup(unsigned char data);
unsigned char SPI1_Transfer(unsigned char data);
void SPI1_WriteBuffer(unsigned char *buffer, unsigned short length);
void SPI1_ReadBuffer(unsigned char *buffer, unsigned short length);

/// # FPGA Configuration & SPI-Communication (SPI2)
/// ############################################################################

// SPI2 chip select (address) / FPGA M0
#define pd_M0                    TRISDbits.TRISD10
#define M0                       LATDbits.LATD10
#define Comm_CSA                 LATDbits.LATD10

// SPI2 chip select (data) / FPGA M1
#define pd_M1                    TRISDbits.TRISD0
#define M1                       LATDbits.LATD0
#define Comm_CSD                 LATDbits.LATD0

// SPI2 CCLK
#define pd_CCLK                  TRISDbits.TRISD9
#define CCLK                     LATDbits.LATD9

// SPI2 MOSI
#define pd_DIN                   TRISDbits.TRISD11
#define DIN                      LATDbits.LATD11

// FPGA PROG_B
#define pd_PROG_B                TRISDbits.TRISD6
#define PROG_B                   LATDbits.LATD6

// FPGA CPI2 communication REQ/ACK / INIT_B
#define pd_INIT_B                TRISDbits.TRISD5
#define INIT_B                   PORTDbits.RD5
#define Comm_REQ                 PORTDbits.RD5

// FPGA CONF_DONE
#define pd_CONF_DONE             TRISDbits.TRISD8
#define CONF_DONE                PORTDbits.RD8

#define RG_READ                  0
#define RG_WRITE                 0x80

void SPI2_Init(void);
unsigned char SPI2_Transfer(unsigned char data);
unsigned char comm_transfer_addr(unsigned char addr);
unsigned char comm_transfer_data(unsigned char data);
unsigned char commWriteRegister(unsigned char reg, unsigned char value);
unsigned char commReadRegister(unsigned char reg);

/// === I2C (EEPROM & RTC)
/// ============================================================================
#define I2C_WRITE                0
#define I2C_READ                 1

void I2C_Init(void);
void I2C_Start(void);
void I2C_RepeatStart(void);
unsigned char I2C_WriteByte(unsigned char value);
unsigned char I2C_ReadByte(unsigned char ack);
void I2C_Stop(void);
void I2C_Idle(void);
unsigned char I2C_AckStatus(void);

void UART_Init(void);

#endif //_HAL_H_
