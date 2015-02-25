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
#include "hardware.h"

void InitController(void)
{
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

    InitPPS();
    InitIO();
    InitSPI1();
    InitSPI2();
    InitUART();
    I2C_Init();
}

void InitPPS(void)
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

void InitIO(void)
{
    // = Init LED's and Buttons
    // ========================================================
    TrisPowerButton = Input;
    TrisPowerLED = Output;
    TrisUserLED1 = Output;
    TrisUserLED2 = Output;
    TrisUserLED3 = Output;

    PowerLED_Off;
    UserLED1_Off;
    UserLED2_Off;
    UserLED3_Off;
}

void InitSPI2(void)
{
    CCLK = 0;
    DIN = 0;
    PROG_B = 1;
    M0 = 1;
    M1 = 1;

    TrisM0 = Output;
    TrisM1 = Output;
//    TrisCCLK = Output;
//    TrisDIN = Output;
    TrisPROG_B = Output;
    TrisINIT_B = Input;
    TrisCONF_DONE = Input;

    SPI2CON1 = 0b0000000100111011;
    SPI2CON2 = 0b0000000000000000;
    SPI2STATbits.SPIROV = 0;
    SPI2STATbits.SPIEN = 1;
}

unsigned char TransferSPI2(unsigned char data)
{
    SPI2BUF = data;
    while (!SPI2STATbits.SPIRBF);
    return (unsigned char)SPI2BUF;
}

unsigned char Comm_transfer_addr(unsigned char addr)
{
    Comm_CSA = 0;
    SPI2BUF = addr;
    while (!SPI2STATbits.SPIRBF);
    Comm_CSA = 1;
    return (unsigned char)SPI2BUF;
}

unsigned char Comm_transfer_data(unsigned char data)
{
    Comm_CSD = 0;
    SPI2BUF = data;
    while (!SPI2STATbits.SPIRBF);
    Comm_CSD = 1;
    return (unsigned char)SPI2BUF;
}

unsigned char commWriteRegister(unsigned char reg, unsigned char value)
{
    videoTransferAddr(RG_WRITE | reg);
    return videoTransferData(value);
}

unsigned char commReadRegister(unsigned char reg)
{
    videoTransferAddr(RG_READ | reg);
    return videoTransferData(0x00);
}

/// ################################################################################################
/// # SPI 1 (SD-Card/Flash)
/// ################################################################################################

void InitSPI1(void)
{
    SDCard_Deselect;
    Flash_Deselect;
    SPI_Mux_FPGA;

    TrisSDCard_CS = Output;
    TrisFlash_CS = Output;
    TrisSPI_Mux = Output;

    SPI1CON1 = 0b0000000100100001;
    SPI1CON2 = 0b0000000000000000;
    SPI1STATbits.SPIROV = 0;
    SPI1STATbits.SPIEN = 1;
}

void SetupSPI1(unsigned char data)
{
    /// 8MHz   - PRI 1:1    SEC 2:1    0b11011
    /// 250KHz - PRI 64:1   SEC 1:1    0b11100
    SPI1STATbits.SPIEN = 0;
    SPI1CON1 = (SPI1CON1 & 0b1111111111100000) | data;
    SPI1STATbits.SPIEN = 1;
}

unsigned char TransferSPI1(unsigned char data)
{
    SPI1BUF = data;
    while (!SPI1STATbits.SPIRBF);
    return (unsigned char)SPI1BUF;
}

/// ################################################################################################
/// # Debug UART 19200 boud
/// ################################################################################################
void InitUART(void)
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
