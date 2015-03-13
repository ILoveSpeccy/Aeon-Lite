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

#include <pps.h>
#include <uart.h>
#include <i2c.h>
#include "hal.h"

/// Local functions
/// ############################################################################
void PPS_Init(void);
void IO_Init(void);

/// Global functions
/// ############################################################################

void Controller_Init(void)
{
   // Disable all analog inputs
   #if defined(__PIC24FJ128GB106__) || defined(__PIC24FJ192GB106__) || defined(__PIC24FJ256GB106__)
      AD1PCFGL = 0xFFFF;
   #elif defined(__PIC24FJ128GB206__) || defined(__PIC24FJ256GB206__)
      ANSB = 0;
      ANSC = 0;
      ANSD = 0;
      ANSF = 0;
      ANSG = 0;
   #else
      #error "Unsupported MCU"
   #endif

   PPS_Init();
   IO_Init();
   SPI1_Init();
   SPI2_Init();
   UART_Init();
   I2C_Init();
}

void PPS_Init(void)
{
   PPSUnLock;
      // SPI1 (SD-Card/Flash)
      PPSInput (PPS_SDI1  , PPS_RP19   );     // RG8   SPI1 MISO
      PPSOutput(PPS_RP21  , PPS_SDO1   );     // RG6   SPI1 MOSI
      PPSOutput(PPS_RP26  , PPS_SCK1OUT);     // RG7   SPI1 SCK

      // SPI2 (FPGA Communication)
      PPSInput (PPS_SDI2  , PPS_RPI37  );     // RC14  SPI2 MISO
      PPSOutput(PPS_RP12  , PPS_SDO2   );     // RD11  SPI2 MOSI
      PPSOutput(PPS_RP4   , PPS_SCK2OUT);     // RD9   SPI2 SCK

      // USART1 (Debug Information Output)
      PPSOutput(PPS_RP13  , PPS_U1TX   );     // RB2   UART TX

      // PWM Output for Buzzer
      PPSOutput(PPS_RP16  , PPS_OC1    );     // RF3   Buzzer
   PPSLock;
}

void IO_Init(void)
{
   pd_PowerButton = pd_input;

   pd_PowerLED = pd_output;
   PowerLED_Off;

   pd_UserLED1 = pd_output;
   UserLED1_Off;

   pd_UserLED2 = pd_output;
   UserLED2_Off;

   pd_UserLED3 = pd_output;
   UserLED3_Off;

   pd_MCU_Ready = pd_output;
   MCU_NotReady;
}

void SPI2_Init(void)
{
   CCLK = 0;
   DIN = 0;
   PROG_B = 1;
   M0 = 1;
   M1 = 1;

   pd_M0 = pd_output;
   pd_M1 = pd_output;
   pd_PROG_B = pd_output;
   pd_INIT_B = pd_input;
   pd_CONF_DONE = pd_input;

   SPI2CON1 = 0b0000000100111011;
   SPI2CON2 = 0b0000000000000000;
   SPI2STATbits.SPIROV = 0;
   SPI2STATbits.SPIEN = 1;
}

unsigned char SPI2_Transfer(unsigned char data)
{
   SPI2BUF = data;
   while (!SPI2STATbits.SPIRBF);
   return (unsigned char)SPI2BUF;
}

unsigned char comm_transfer_addr(unsigned char addr)
{
   Comm_CSA = 0;
   SPI2BUF = addr;
   while (!SPI2STATbits.SPIRBF);
   Comm_CSA = 1;
   return (unsigned char)SPI2BUF;
}

unsigned char comm_transfer_data(unsigned char data)
{
   Comm_CSD = 0;
   SPI2BUF = data;
   while (!SPI2STATbits.SPIRBF);
   Comm_CSD = 1;
   return (unsigned char)SPI2BUF;
}

unsigned char commWriteRegister(unsigned char reg, unsigned char value)
{
   comm_transfer_addr(RG_WRITE | reg);
   return comm_transfer_data(value);
}

unsigned char commReadRegister(unsigned char reg)
{
   comm_transfer_addr(RG_READ | reg);
   return comm_transfer_data(0x00);
}

/// ################################################################################################
/// # SPI 1 (SD-Card/Flash)
/// ################################################################################################

void SPI1_Init(void)
{
   SDCard_Deselect;
   Flash_Deselect;
   SPI_Mux_FPGA;

   pd_SDCard_CS = pd_output;
   pd_Flash_CS = pd_output;
   pd_SPI_Mux = pd_output;

   SPI1CON1 = 0b0000000100100001;
   SPI1CON2 = 0b0000000000000000;
   SPI1STATbits.SPIROV = 0;
   SPI1STATbits.SPIEN = 1;
}

void SPI1_Setup(unsigned char data)
{
   SPI1STATbits.SPIEN = 0;
   SPI1CON1 = (SPI1CON1 & 0b1111111111100000) | data;
   SPI1STATbits.SPIEN = 1;
}

unsigned char SPI1_Transfer(unsigned char data)
{
   SPI1BUF = data;
   while (!SPI1STATbits.SPIRBF);
   return (unsigned char)SPI1BUF;
}

void SPI1_WriteBuffer(unsigned char *buffer, unsigned short length)
{
   unsigned short i;
   for(i = 0 ; i < length ; i++)
      SPI1_Transfer(buffer[i]);
}

void SPI1_ReadBuffer(unsigned char *buffer, unsigned short length)
{
   unsigned short i;
   for(i = 0 ; i < length ; i++)
      buffer[i] = SPI1_Transfer(0xFF);
}

/// ################################################################################################
/// # Debug UART 19200 boud
/// ################################################################################################
void UART_Init(void)
{
   unsigned int UMODEvalue =   UART_EN & UART_IDLE_CON & UART_IrDA_DISABLE & UART_MODE_SIMPLEX & UART_UEN_11 &
                               UART_DIS_WAKE & UART_DIS_LOOPBACK & UART_DIS_ABAUD & UART_UXRX_IDLE_ZERO &
                               UART_BRGH_FOUR & UART_NO_PAR_8BIT & UART_1STOPBIT;
   unsigned int USTAvalue =    UART_INT_TX_BUF_EMPTY & UART_IrDA_POL_INV_ZERO & UART_SYNC_BREAK_DISABLED &
                               UART_TX_ENABLE & UART_INT_RX_BUF_FUL & UART_ADR_DETECT_DIS & UART_RX_OVERRUN_CLEAR;
   OpenUART1(UMODEvalue, USTAvalue, 207);
}

/// ################################################################################################
/// # I2C (EEPROM & RTC)
/// ################################################################################################
void I2C_Init(void)
{
   I2C3BRG = 150; //358 kHz
   I2C3CONbits.I2CEN = 1;
   I2C_Idle();
}

void I2C_Start(void)
{
   I2C3CONbits.SEN = 1;
   while (I2C3CONbits.SEN);
}

void I2C_RepeatStart(void)
{
   I2C3CONbits.RSEN = 1;
   while (I2C3CONbits.RSEN);
}

unsigned char I2C_WriteByte(unsigned char value)
{
   I2C3TRN = value;
   while (I2C3STATbits.TBF);
   I2C_Idle();
   return I2C_AckStatus();
}

unsigned char I2C_ReadByte(unsigned char ack)
{
   I2C3CONbits.RCEN=1;
   while (I2C3CONbits.RCEN==1);
   I2C3CONbits.ACKDT = !ack;
   I2C3CONbits.ACKEN = 1;
   while (I2C3CONbits.ACKEN);
   I2C3CONbits.ACKDT = 0;
   return I2C3RCV;
}

void I2C_Stop(void)
{
   I2C3CONbits.PEN = 1;
   while (I2C3CONbits.PEN);
}

void I2C_Idle(void)
{
   while (I2C3STATbits.TRSTAT);
}

unsigned char I2C_AckStatus(void)
{
   return(!I2C3STATbits.ACKSTAT);
}
