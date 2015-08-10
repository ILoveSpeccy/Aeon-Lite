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

#include <xc.h>
#include <stdint.h>

#define FOSC    (32000000ULL)
#define FCY     (FOSC/2)

#include <libpic30.h>

#define DEBUG                    1
#define DEBUG_UART_BAUDRATE      115200

#define TRUE                     1
#define FALSE                    0

// #############################################################################
// ##
// ## µC I/O Configuration
// ##
// #############################################################################

#define dirInput                 1
#define dirOutput                0

// Power Button
#define dirPowerButton        TRISEbits.TRISE5
#define pinPowerButton        PORTEbits.RE5
#define powerButtonIsPressed  (!pinPowerButton)

// Power LED
#define dirPowerLed           TRISGbits.TRISG9
#define pinPowerLed           LATGbits.LATG9
#define powerLedOn            pinPowerLed = 1
#define powerLedOff           pinPowerLed = 0

// Red LED
#define dirRedLed             TRISDbits.TRISD7
#define pinRedLed             LATDbits.LATD7
#define redLedOn              pinRedLed = 0
#define redLedOff             pinRedLed = 1

// Yellow LED
#define dirYellowLed          TRISFbits.TRISF0
#define pinYellowLed          LATFbits.LATF0
#define yellowLedOn           pinYellowLed = 0
#define yellowLedOff          pinYellowLed = 1

// Green LED
#define dirGreenLed           TRISFbits.TRISF1
#define pinGreenLed           LATFbits.LATF1
#define greenLedOn            pinGreenLed = 0
#define greenLedOff           pinGreenLed = 1

// Buzzer
#define dirBuzzer             TRISFbits.TRISF3
#define pinBuzzer             LATFbits.LATF3

// MCU Ready
#define dirMcuReady           TRISCbits.TRISC13
#define pinMcuReady           LATCbits.LATC13
#define mcuReady              pinMcuReady = 1
#define mcuNotReady           pinMcuReady = 0

// #############################################################################
// ##
// ## SPI 1 (SD-Card & DataFlash)
// ##
// #############################################################################

// SPI Mux - select SPI master: MCU / FPGA
#define dirSpiMux             TRISEbits.TRISE4
#define pinSpiMux             LATEbits.LATE4
#define muxMcu                0
#define muxFpga               1
#define spiMuxMcu             pinSpiMux = muxMcu
#define spiMuxFpga            pinSpiMux = muxFpga

// SD-Card chip select
#define dirSdcardCs           TRISEbits.TRISE3
#define pinSdcardCs           LATEbits.LATE3

// Flash chip select
#define dirDataflashCs        TRISEbits.TRISE2
#define pinDataFlashCs        LATEbits.LATE2

// SD-Card detect
#define dirSdcardDetect       TRISEbits.TRISE1
#define pinSdcardDetect       PORTEbits.RE1

// SD-Card write protect
#define dirSdcardWriteProtect TRISEbits.TRISE0
#define pinSdcardWriteProtect PORTEbits.RE0

// #############################################################################
// ##
// ## SPI 2 (FPGA Communication)
// ##
// #############################################################################

// SPI2 chip select (address) / FPGA M0
#define dirM0                 TRISDbits.TRISD10
#define pinM0                 LATDbits.LATD10
#define pinCommCsA            LATDbits.LATD10

// SPI2 chip select (data) / FPGA M1
#define dirM1                 TRISDbits.TRISD0
#define pinM1                 LATDbits.LATD0
#define pinCommCsD            LATDbits.LATD0

// FPGA PROG_B
#define dirProgB              TRISDbits.TRISD6
#define pinProgB              LATDbits.LATD6

// FPGA REQ/ACK / INIT_B
#define dirInitB              TRISDbits.TRISD5
#define pinInitB              PORTDbits.RD5
#define pinCommReq            PORTDbits.RD5

// FPGA CONF_DONE
#define dirConfDone           TRISDbits.TRISD8
#define pinConfDone           PORTDbits.RD8

void ioInit(void);
void ppsInit(void);
void spiInit(void);
void commInit(void);
void uartInit(void);

void spiInit(void);
void spiSckSlow(void);
void spiSckFast(void);
uint8_t spiTransfer(uint8_t data);
void spiWriteBuffer(uint8_t *buffer, uint16_t length);
void spiReadBuffer(uint8_t *buffer, uint16_t length);

void commInit(void);
uint8_t commTransfer(uint8_t data);
uint8_t commTransferAddr(uint8_t addr);
uint8_t commTransferData(uint8_t data);
uint8_t commTransferReg(uint8_t addr, uint8_t data);

void uartInit(void);

// #############################################################################
// ##
// ## I2C (Inter-Integrated Curcuit IIC) for RTC/EEPROM
// ##
// #############################################################################

#define I2C_WRITE                0
#define I2C_READ                 1

void iicInit(void);
void iicStart(void);
void iicRepeatStart(void);
uint8_t iicWriteByte(uint8_t value);
uint8_t iicReadByte(uint8_t ack);
void iicStop(void);
void iicIdle(void);
uint8_t iicAckStatus(void);

#endif //_HAL_H_
