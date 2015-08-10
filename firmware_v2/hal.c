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

#include <PPS.h>
#include <uart.h>
#include "hal.h"

// *****************************************************************************
// * Init Microcontroller
// *****************************************************************************
void ioInit(void)
{
   // Disable analog pins
   #if defined(__PIC24FJ128GB106__) || defined(__PIC24FJ192GB106__) || defined(__PIC24FJ256GB106__)
      AD1PCFGL = 0xFFFF;
   #elif defined(__PIC24FJ128GB206__) || defined(__PIC24FJ256GB206__) || defined(__PIC24FJ128DA106__) || defined(__PIC24FJ256DA106__) || defined(__PIC24FJ128DA206__) || defined(__PIC24FJ256DA206__)
      ANSB = 0;
      ANSC = 0;
      ANSD = 0;
      ANSF = 0;
      ANSG = 0;
   #else
      #error "Unsupported MCU"
   #endif

   // Init LED's & Buttons
   dirPowerButton = dirInput;
   dirPowerLed    = dirOutput;
   dirRedLed      = dirOutput;
   dirYellowLed   = dirOutput;
   dirGreenLed    = dirOutput;

   powerLedOff;
   redLedOff;
   yellowLedOff;
   greenLedOff;

   dirMcuReady    = dirOutput;
   mcuNotReady;
}

// *****************************************************************************
// * PPS (Peripheral Pin Select)
// *****************************************************************************
void ppsInit(void)
{
   PPSUnLock;
   // SPI1 (SD-Card/Flash)
   PPSInput (PPS_SDI1  , PPS_RP19   );    // RG8   SPI1 MISO
   PPSOutput(PPS_RP21  , PPS_SDO1   );    // RG6   SPI1 MOSI
   PPSOutput(PPS_RP26  , PPS_SCK1OUT);    // RG7   SPI1 SCK

   // SPI2 (FPGA Communication)
   PPSInput (PPS_SDI2  , PPS_RPI37  );    // RC14  SPI2 MISO
   PPSOutput(PPS_RP12  , PPS_SDO2   );    // RD11  SPI2 MOSI
   PPSOutput(PPS_RP4   , PPS_SCK2OUT);    // RD9   SPI2 SCK

   // USART1 (Debug Information Output)
   PPSOutput(PPS_RP13  , PPS_U1TX   );    // RB2   USART1 TX

   // PWM Output for Buzzer
   PPSOutput(PPS_RP16  , PPS_OC1    );    // RF3   Buzzer PWM (OC1)
   PPSLock;
}

// #############################################################################
// ##
// ## UART 1 (Output Debug Information)
// ##
// #############################################################################
void uartInit(void)
{
   uint16_t UMODEvalue =   UART_EN & UART_IDLE_CON & UART_IrDA_DISABLE &
                           UART_MODE_SIMPLEX & UART_UEN_11 & UART_DIS_WAKE &
                           UART_DIS_LOOPBACK & UART_DIS_ABAUD &
                           UART_UXRX_IDLE_ZERO & UART_BRGH_FOUR &
                           UART_NO_PAR_8BIT & UART_1STOPBIT;
   uint16_t USTAvalue =    UART_INT_TX_BUF_EMPTY & UART_IrDA_POL_INV_ZERO &
                           UART_SYNC_BREAK_DISABLED & UART_TX_ENABLE &
                           UART_INT_RX_BUF_FUL & UART_ADR_DETECT_DIS &
                           UART_RX_OVERRUN_CLEAR;
   uint16_t BRGvalue =     (FCY / (4 * DEBUG_UART_BAUDRATE)) - 1;
   OpenUART1(UMODEvalue, USTAvalue, BRGvalue);
}

// #############################################################################
// ##
// ## SPI 1 (SD-Card & DataFlash)
// ##
// #############################################################################

// *****************************************************************************
// * Init SPI
// *****************************************************************************
void spiInit(void)
{
   pinSdcardCs = 1;
   pinDataFlashCs = 1;
   spiMuxMcu;

   dirSdcardCs = dirOutput;
   dirDataflashCs = dirOutput;
   dirSpiMux = dirOutput;

   SPI1CON1 = 0b0000000100100001;
   SPI1CON2 = 0b0000000000000000;
   SPI1STATbits.SPIROV = 0;
   SPI1STATbits.SPIEN = 1;
}

// *****************************************************************************
// * Set SPI SCK Speed to 250 kHz
// *****************************************************************************
void spiSckSlow(void)
{
   SPI1STATbits.SPIEN = 0;
   SPI1CON1 = 0b0000000100111100;
   SPI1STATbits.SPIEN = 1;
}

// *****************************************************************************
// * Set SPI SCK Speed to 8 MHz
// *****************************************************************************
void spiSckFast(void)
{
   SPI1STATbits.SPIEN = 0;
   SPI1CON1 = 0b0000000100111011;
   SPI1STATbits.SPIEN = 1;
}

// *****************************************************************************
// * Transfer 1 Byte (Read and Write)
// *****************************************************************************
uint8_t spiTransfer(uint8_t data)
{
   SPI1BUF = data;
   while (!SPI1STATbits.SPIRBF);
   return (uint8_t)SPI1BUF;
}

// *****************************************************************************
// * Write <length> Bytes from Buffer
// *****************************************************************************
void spiWriteBuffer(uint8_t *buffer, uint16_t length)
{
   uint16_t i;
   for(i = 0 ; i < length ; i++)
      spiTransfer(buffer[i]);
}

// *****************************************************************************
// * Read <length> Bytes to Buffer
// *****************************************************************************
void spiReadBuffer(uint8_t *buffer, uint16_t length)
{
   uint16_t i;
   for(i = 0 ; i < length ; i++)
      buffer[i] = spiTransfer(0xFF);
}

// #############################################################################
// ##
// ## SPI 2 (FPGA Communication)
// ##
// #############################################################################

// *****************************************************************************
// * Init SPI 2 for FPGA Communication, SCK Frequency = 8MHz
// *****************************************************************************
void commInit(void)
{
   pinM0 = 1;
   pinM1 = 1;
   pinProgB = 1;

   dirM0 = dirOutput;
   dirM1 = dirOutput;
   dirProgB = dirOutput;
   dirInitB = dirInput;
   dirConfDone= dirInput;

   SPI2CON1 = 0b0000000100111011;
   SPI2CON2 = 0b0000000000000000;
   SPI2STATbits.SPIROV = 0;
   SPI2STATbits.SPIEN = 1;
}

// *****************************************************************************
// * Transfer Byte
// *****************************************************************************
uint8_t commTransfer(uint8_t data)
{
   SPI2BUF = data;
   while (!SPI2STATbits.SPIRBF);
   return (uint8_t)SPI2BUF;
}

// *****************************************************************************
// * Transfer Address Byte
// *****************************************************************************
uint8_t commTransferAddr(uint8_t addr)
{
   pinCommCsA = 0;
   SPI2BUF = addr;
   while (!SPI2STATbits.SPIRBF);
   pinCommCsA = 1;
   return (uint8_t)SPI2BUF;
}

// *****************************************************************************
// * Transfer Data Byte
// *****************************************************************************
uint8_t commTransferData(uint8_t data)
{
   pinCommCsD = 0;
   SPI2BUF = data;
   while (!SPI2STATbits.SPIRBF);
   pinCommCsD = 1;
   return (uint8_t)SPI2BUF;
}

// *****************************************************************************
// * Transfer Register (Address and Byte)
// *****************************************************************************
uint8_t commTransferReg(uint8_t addr, uint8_t data)
{
    commTransferAddr(addr);
    return commTransferData(data);
}

// #############################################################################
// ##
// ## I2C (Inter-Integrated Curcuit IIC) for RTC/EEPROM
// ##
// #############################################################################

/// TO-DO !!!! Handle errors !!!!

// *****************************************************************************
// * I2C Init
// *****************************************************************************
void iicInit(void)
{
   I2C3BRG = 150; //358 kHz
   I2C3CONbits.I2CEN = 1;
   iicIdle();
}

// *****************************************************************************
// * I2C Start
// *****************************************************************************
void iicStart(void)
{
   I2C3CONbits.SEN = 1;
   while (I2C3CONbits.SEN);
}

// *****************************************************************************
// * I2C Repeat Start
// *****************************************************************************
void iicRepeatStart(void)
{
   I2C3CONbits.RSEN = 1;
   while (I2C3CONbits.RSEN);
}

// *****************************************************************************
// * I2C Write Byte
// *****************************************************************************
uint8_t iicWriteByte(uint8_t value)
{
   I2C3TRN = value;
   while (I2C3STATbits.TBF);
   iicIdle();
   return iicAckStatus();
}

// *****************************************************************************
// * I2C Read Byte
// *****************************************************************************
uint8_t iicReadByte(uint8_t ack)
{
   I2C3CONbits.RCEN=1;
   while (I2C3CONbits.RCEN==1);
   I2C3CONbits.ACKDT = !ack;
   I2C3CONbits.ACKEN = 1;
   while (I2C3CONbits.ACKEN);
   I2C3CONbits.ACKDT = 0;
   return I2C3RCV;
}

// *****************************************************************************
// * I2C Stop
// *****************************************************************************
void iicStop(void)
{
   I2C3CONbits.PEN = 1;
   while (I2C3CONbits.PEN);
}

// *****************************************************************************
// * I2C Idle
// *****************************************************************************
void iicIdle(void)
{
   while (I2C3STATbits.TRSTAT);
}

// *****************************************************************************
// * I2C Get Acknowledge Status
// *****************************************************************************
uint8_t iicAckStatus(void)
{
   return(!I2C3STATbits.ACKSTAT);
}
