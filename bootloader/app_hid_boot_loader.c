/********************************************************************
 Software License Agreement:

 The software supplied herewith by Microchip Technology Incorporated
 (the �Company�) for its PIC� Microcontroller is intended and
 supplied to you, the Company�s customer, for use solely and
 exclusively on Microchip PIC Microcontroller products. The
 software is owned by the Company and/or its supplier, and is
 protected under applicable copyright laws. All rights are reserved.
 Any use in violation of the foregoing restrictions may subject the
 user to criminal sanctions under applicable laws, as well as to
 civil liability for the breach of the terms and conditions of this
 license.

 THIS SOFTWARE IS PROVIDED IN AN �AS IS� CONDITION. NO WARRANTIES,
 WHETHER EXPRESS, IMPLIED OR STATUTORY, INCLUDING, BUT NOT LIMITED
 TO, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 PARTICULAR PURPOSE APPLY TO THIS SOFTWARE. THE COMPANY SHALL NOT,
 IN ANY CIRCUMSTANCES, BE LIABLE FOR SPECIAL, INCIDENTAL OR
 CONSEQUENTIAL DAMAGES, FOR ANY REASON WHATSOEVER.
********************************************************************/

/** INCLUDES *******************************************************/

#include <usb/usb.h>
#include <usb/usb_device_hid.h>
#include <boot.h>


/** C O N S T A N T S **********************************************************/

//Switch State Variable Choices
#define	QUERY_DEVICE				0x02    //Command that the host uses to learn about the device (what regions can be programmed, and what type of memory is the region)
#define	UNLOCK_CONFIG				0x03    //Note, this command is used for both locking and unlocking the config bits (see the "//Unlock Configs Command Definitions" below)
#define ERASE_DEVICE				0x04    //Host sends this command to start an erase operation.  Firmware controls which pages should be erased.
#define PROGRAM_DEVICE				0x05    //If host is going to send a full RequestDataBlockSize to be programmed, it uses this command.
#define	PROGRAM_COMPLETE			0x06    //If host send less than a RequestDataBlockSize to be programmed, or if it wished to program whatever was left in the buffer, it uses this command.
#define GET_DATA                                0x07    //The host sends this command in order to read out memory from the device.  Used during verify (and read/export hex operations)
#define	RESET_DEVICE				0x08    //Resets the microcontroller, so it can update the config bits (if they were programmed, and so as to leave the bootloader (and potentially go back into the main application)

//Unlock Configs Command Definitions
#define UNLOCKCONFIG				0x00    //Sub-command for the ERASE_DEVICE command
#define LOCKCONFIG                              0x01    //Sub-command for the ERASE_DEVICE command

//Query Device Response "Types" 
#define	TypeProgramMemory                       0x01    //When the host sends a QUERY_DEVICE command, need to respond by populating a list of valid memory regions that exist in the device (and should be programmed)
#define TypeEEPROM                              0x02
#define TypeConfigWords                         0x03
#define	TypeEndOfTypeList                       0xFF    //Sort of serves as a "null terminator" like number, which denotes the end of the memory region list has been reached.


//BootState Variable States
#define	IdleState                               0x00
#define NotIdleState                            0x01

//OtherConstants
#define InvalidAddress                          0xFFFFFFFF

//Application and Microcontroller constants
#define BytesPerFlashAddress                    0x02    //For Flash memory: One byte per address on PIC18, two bytes per address on PIC24

#define	TotalPacketSize                         0x40
#define WORDSIZE                                0x02    //PIC18 uses 2 byte instruction words, PIC24 uses 3 byte "instruction words" (which take 2 addresses, since each address is for a 16 bit word; the upper word contains a "phantom" byte which is unimplemented.).

#define RequestDataBlockSize                    56      //Number of bytes in the "Data" field of a standard request to/from the PC.  Must be an even number from 2 to 56.
#define BufferSize                              0x20    //32 16-bit words of buffer

/** PRIVATE PROTOTYPES *********************************************/
void EraseFlash(void);
void WriteFlashSubBlock(void);
void BootApplication(void);
uint32_t ReadProgramMemory(uint32_t);

/** T Y P E  D E F I N I T I O N S ************************************/

typedef union __attribute__ ((packed)) _USB_HID_BOOTLOADER_COMMAND
{
    unsigned char Contents[64];

    struct __attribute__ ((packed)) {
        unsigned char Command;
        uint16_t AddressHigh;
        uint16_t AddressLow;
        unsigned char Size;
        unsigned char PadBytes[(TotalPacketSize - 6) - (RequestDataBlockSize)];
        unsigned int Data[RequestDataBlockSize/WORDSIZE];
    };

        struct __attribute__ ((packed)) {
        unsigned char Command;
        uint32_t Address;
        unsigned char Size;
        unsigned char PadBytes[(TotalPacketSize - 6) - (RequestDataBlockSize)];
        unsigned int Data[RequestDataBlockSize/WORDSIZE];
    };

    struct __attribute__ ((packed)){
        unsigned char Command;
        unsigned char PacketDataFieldSize;
        unsigned char BytesPerAddress;
        unsigned char Type1;
        unsigned long Address1;
        unsigned long Length1;
        unsigned char Type2;
        unsigned long Address2;
        unsigned long Length2;
        unsigned char Type3;		//End of sections list indicator goes here, when not programming the vectors, in that case fill with 0xFF.
        unsigned long Address3;
        unsigned long Length3;
        unsigned char Type4;		//End of sections list indicator goes here, fill with 0xFF.
        unsigned char ExtraPadBytes[33];
    };

    struct __attribute__ ((packed)){						//For lock/unlock config command
        unsigned char Command;
        unsigned char LockValue;
    };
} PacketToFromPC;

typedef union
{
    uint32_t Val;
    uint16_t w[2] __attribute__((packed));
    uint8_t v[4];
    struct __attribute__((packed))
    {
        uint16_t LW;
        uint16_t HW;
    } word;
    struct __attribute__((packed))
    {
        uint8_t LB;
        uint8_t HB;
        uint8_t UB;
        uint8_t MB;
    } byte;
} uint32_t_VAL;

/** VARIABLES ******************************************************/
PacketToFromPC PacketFromPC;		//64 byte buffer for receiving packets on EP1 OUT from the PC
PacketToFromPC PacketToPC;			//64 byte buffer for sending packets on EP1 IN to the PC
PacketToFromPC PacketFromPCBuffer;

USB_HANDLE USBOutHandle = 0;
USB_HANDLE USBInHandle = 0;
bool blinkStatusValid = true;

unsigned char MaxPageToErase;
unsigned long ProgramMemStopAddress;
unsigned char BootState;
unsigned char ErasePageTracker;
unsigned int ProgrammingBuffer[BufferSize];
unsigned char BufferedDataIndex;
unsigned long ProgrammedPointer;
unsigned char ConfigsProtected;


void APP_HIDBootLoaderInitialize(void)
{   
    //initialize the variable holding the handle for the last
    // transmission
    USBOutHandle = 0;
    USBInHandle = 0;

    //Initialize bootloader state variables
    MaxPageToErase = BOOT_CONFIG_USER_MEMORY_ERASE_PAGE_END_NO_CONFIGS;		//Assume we will not allow erase/programming of config words (unless host sends override command)
    ProgramMemStopAddress = BOOT_CONFIG_USER_MEMORY_END_ADDRESS_NO_CONFIGS;
    ConfigsProtected = LOCKCONFIG;					//Assume we will not erase or program the vector table at first.  Must receive unlock config bits/vectors command first.
    BootState = IdleState;
    ProgrammedPointer = InvalidAddress;
    BufferedDataIndex = 0;

    //enable the HID endpoint
    USBEnableEndpoint(CUSTOM_DEVICE_HID_EP,USB_IN_ENABLED|USB_OUT_ENABLED|USB_HANDSHAKE_ENABLED|USB_DISALLOW_SETUP);
    //Arm the OUT endpoint for the first packet
    USBOutHandle = HIDRxPacket(CUSTOM_DEVICE_HID_EP,(uint8_t*)&PacketFromPCBuffer,64);
}//end UserInit



/******************************************************************************
 * Function:        void ProcessIO(void)
 *
 * PreCondition:    None
 *
 * Input:           None
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        This function is a place holder for other user routines.
 *                  It is a mixture of both USB and non-USB tasks.
 *
 * Note:            None
 *****************************************************************************/
void APP_HIDBootLoaderTasks(void)
{
    unsigned char i;
    unsigned int j;
    uint32_t_VAL FlashMemoryValue;

    if(BootState == IdleState)
    {
        //Are we done sending the last response.  We need to be before we 
        //  receive the next command because we clear the PacketToPC buffer
        //  once we receive a command
        if(!USBHandleBusy(USBInHandle))
        {
            if(!USBHandleBusy(USBOutHandle))		//Did we receive a command?
            {
                for(i = 0; i < TotalPacketSize; i++)
                {
                    PacketFromPC.Contents[i] = PacketFromPCBuffer.Contents[i];
                }
                
                USBOutHandle = USBRxOnePacket(CUSTOM_DEVICE_HID_EP,(uint8_t*)&PacketFromPCBuffer,64);
                BootState = NotIdleState;
                
                //Prepare the next packet we will send to the host, by initializing the entire packet to 0x00.	
                for(i = 0; i < TotalPacketSize; i++)
                {
                    //This saves code space, since we don't have to do it independently in the QUERY_DEVICE and GET_DATA cases.
                    PacketToPC.Contents[i] = 0;	
                }
            }
        }
    }
    else //(BootState must be in NotIdleState)
    {
        switch(PacketFromPC.Command)
        {
            case QUERY_DEVICE:
            {
                //Prepare a response packet, which lets the PC software know about the memory ranges of this device.
                PacketToPC.Command = (unsigned char)QUERY_DEVICE;
                PacketToPC.PacketDataFieldSize = (unsigned char)RequestDataBlockSize;
                PacketToPC.BytesPerAddress = (unsigned char)BytesPerFlashAddress;

                PacketToPC.Type1 = (unsigned char)TypeProgramMemory;
                PacketToPC.Address1 = (unsigned long)BOOT_CONFIG_USER_MEMORY_START_ADDRESS;
                PacketToPC.Length1 = (unsigned long)(ProgramMemStopAddress - BOOT_CONFIG_USER_MEMORY_START_ADDRESS);	//Size of program memory area
                PacketToPC.Type2 = (unsigned char)TypeEndOfTypeList;

                if(ConfigsProtected == UNLOCKCONFIG)
                {
                    PacketToPC.Type2 = (unsigned char)TypeConfigWords;
                    PacketToPC.Address2 = (unsigned long)BOOT_MEMORY_CONFIG_START_ADDRESS;
                    PacketToPC.Length2 = (unsigned long)(BOOT_MEMORY_CONFIG_END_ADDRESS - BOOT_MEMORY_CONFIG_START_ADDRESS);
                    PacketToPC.Type3 = (unsigned char)TypeEndOfTypeList;
                }

                //Init pad bytes to 0x00...  Already done after we received the QUERY_DEVICE command (just after calling HIDRxPacket()).

                if(!USBHandleBusy(USBInHandle))
                {
                    USBInHandle = USBTxOnePacket(CUSTOM_DEVICE_HID_EP,(uint8_t*)&PacketToPC,64);
                    BootState = IdleState;
                }
                break;
            }

            case UNLOCK_CONFIG:
            {
                if(PacketFromPC.LockValue == UNLOCKCONFIG)
                {
                        MaxPageToErase = BOOT_CONFIG_USER_MEMORY_ERASE_PAGE_END_CONFIGS;		//Assume we will not allow erase/programming of config words (unless host sends override command)
                        ProgramMemStopAddress = BOOT_CONFIG_USER_MEMORY_END_ADDRESS_CONFIGS;
                        ConfigsProtected = UNLOCKCONFIG;
                }
                else	//LockValue must be == LOCKCONFIG
                {
                        MaxPageToErase = BOOT_CONFIG_USER_MEMORY_ERASE_PAGE_END_NO_CONFIGS;
                        ProgramMemStopAddress = BOOT_CONFIG_USER_MEMORY_END_ADDRESS_NO_CONFIGS;
                        ConfigsProtected = LOCKCONFIG;
                }
                
                BootState = IdleState;
                break;
            }

            case ERASE_DEVICE:
            {
                for(ErasePageTracker = BOOT_CONFIG_USER_MEMORY_ERASE_PAGE_START; ErasePageTracker < (MaxPageToErase + 1); ErasePageTracker++)
                {
                    EraseFlash();
                    USBDeviceTasks(); 	//Call USBDriverService() periodically to prevent falling off the bus if any SETUP packets should happen to arrive.
                }

                NVMCONbits.WREN = 0;		//Good practice to clear WREN bit anytime we are not expecting to do erase/write operations, further reducing probability of accidental activation.
                BootState = IdleState;
                break;
            }

            case PROGRAM_DEVICE:
            {
                if(ProgrammedPointer == (unsigned long)InvalidAddress)
                {
                    ProgrammedPointer = PacketFromPC.Address;
                }

                if(ProgrammedPointer == (unsigned long)PacketFromPC.Address)
                {
                    for(i = 0; i < (PacketFromPC.Size/WORDSIZE); i++)
                    {
                        unsigned int index;

                        index = (RequestDataBlockSize-PacketFromPC.Size)/WORDSIZE+i;
                        ProgrammingBuffer[BufferedDataIndex] = PacketFromPC.Data[(RequestDataBlockSize-PacketFromPC.Size)/WORDSIZE+i];	//Data field is right justified.  Need to put it in the buffer left justified.
                        BufferedDataIndex++;
                        ProgrammedPointer++;
                        if(BufferedDataIndex == (RequestDataBlockSize/WORDSIZE))	//Need to make sure it doesn't call WriteFlashSubBlock() unless BufferedDataIndex/2 is an integer
                        {
                            WriteFlashSubBlock();
                        }
                    }
                }
                //else host sent us a non-contiguous packet address...  to make this firmware simpler, host should not do this without sending a PROGRAM_COMPLETE command in between program sections.
                BootState = IdleState;
                break;
            }

            case PROGRAM_COMPLETE:
            {
                WriteFlashSubBlock();
                ProgrammedPointer = InvalidAddress;		//Reinitialize pointer to an invalid range, so we know the next PROGRAM_DEVICE will be the start address of a contiguous section.
                BootState = IdleState;
                break;
            }

            case GET_DATA:
            {
                if(!USBHandleBusy(USBInHandle))
                {
                    //Init pad bytes to 0x00...  Already done after we received the QUERY_DEVICE command (just after calling HIDRxReport()).
                    PacketToPC.Command = GET_DATA;
                    PacketToPC.Address = PacketFromPC.Address;
                    PacketToPC.Size = PacketFromPC.Size;

                    for(i = 0; i < (PacketFromPC.Size/2); i=i+2)
                    {
                        FlashMemoryValue.Val = ReadProgramMemory(PacketFromPC.Address + i);
                        PacketToPC.Data[RequestDataBlockSize/WORDSIZE + i - PacketFromPC.Size/WORDSIZE] = FlashMemoryValue.word.LW;		//Low word, pure 16-bits of real data
                        FlashMemoryValue.byte.MB = 0x00;	//Set the "phantom byte" = 0x00, since this is what is in the .HEX file generatd by MPLAB.
                                                                            //Needs to be 0x00 so as to match, and successfully verify, even though the actual table read yeilded 0xFF for this phantom byte.
                        PacketToPC.Data[RequestDataBlockSize/WORDSIZE + i + 1 - PacketFromPC.Size/WORDSIZE] = FlashMemoryValue.word.HW;	//Upper word, which contains the phantom byte
                    }

                    USBInHandle = USBTxOnePacket(CUSTOM_DEVICE_HID_EP,(uint8_t*)&PacketToPC.Contents[0],64);
                    BootState = IdleState;
                }
                break;
            }

                        
            case RESET_DEVICE:
            {
                U1CON = 0x0000;				//Disable USB module
                //And wait awhile for the USB cable capacitance to discharge down to disconnected (SE0) state.
                //Otherwise host might not realize we disconnected/reconnected when we do the reset.
                //A basic for() loop decrementing a 16 bit number would be simpler, but seems to take more code space for
                //a given delay.  So do this instead:
                for(j = 0; j < 0xFFFF; j++)
                {
                    Nop();
                }
                asm("reset");
                break;
            }
        }//End switch
    }//End if/else

}//End ProcessIO()



void EraseFlash(void)
{
    uint32_t_VAL MemAddressToErase = {0x00000000};
    MemAddressToErase.Val = (((uint32_t)ErasePageTracker) * BOOT_ERASE_BLOCK_SIZE);

	NVMCON = 0x4042;				//Erase page on next WR

    TBLPAG = MemAddressToErase.byte.UB;
    __builtin_tblwtl(MemAddressToErase.word.LW, 0xFFFF);

    asm("DISI #16");					//Disable interrupts for next few instructions for unlock sequence
    __builtin_write_NVM();
    while(NVMCONbits.WR == 1){}

//	EECON1bits.WREN = 0;  //Good practice now to clear the WREN bit, as further protection against any future accidental activation of self write/erase operations.
}	


void WriteFlashSubBlock(void)		//Use word writes to write code chunks less than a full 64 byte block size.
{
    unsigned int i = 0;
    uint32_t_VAL Address;

	NVMCON = 0x4003;		//Perform WORD write next time WR gets set = 1.

    while(BufferedDataIndex > 0)		//While data is still in the buffer.
    {
        Address.Val = ProgrammedPointer - BufferedDataIndex;
        TBLPAG = Address.word.HW;

        __builtin_tblwtl(Address.word.LW, ProgrammingBuffer[i]);		//Write the low word to the latch
        __builtin_tblwth(Address.word.LW, ProgrammingBuffer[i + 1]);	//Write the high word to the latch (8 bits of data + 8 bits of "phantom data")
        i = i + 2;

        asm("DISI #16");					//Disable interrupts for next few instructions for unlock sequence
        __builtin_write_NVM();
        while(NVMCONbits.WR == 1){}

        BufferedDataIndex = BufferedDataIndex - 2;		//Used up 2 (16-bit) words from the buffer.
    }

    NVMCONbits.WREN = 0;		//Good practice to clear WREN bit anytime we are not expecting to do erase/write operations, further reducing probability of accidental activation.
}


/*********************************************************************
 * Function:        uint32_t ReadProgramMemory(uint32_t address)
 *
 * PreCondition:    None
 *
 * Input:           Program memory address to read from.  Should be 
 *                            an even number.
 *
 * Output:          Program word at the specified address.  For the 
 *                            PIC24, dsPIC, etc. which have a 24 bit program 
 *                            word size, the upper byte is 0x00.
 *
 * Side Effects:    None
 *
 * Overview:        Modifies and restores TBLPAG.  Make sure that if 
 *                            using interrupts and the PSV feature of the CPU 
 *                            in an ISR that the TBLPAG register is preloaded 
 *                            with the correct value (rather than assuming 
 *                            TBLPAG is always pointing to the .const section.
 *
 * Note:            None
 ********************************************************************/
uint32_t ReadProgramMemory(uint32_t address)
{  
    uint32_t_VAL dwvResult;
    uint16_t wTBLPAGSave;
 
    wTBLPAGSave = TBLPAG;
    TBLPAG = ((uint32_t_VAL*)&address)->w[1];

    dwvResult.w[1] = __builtin_tblrdh((uint16_t)address);
    dwvResult.w[0] = __builtin_tblrdl((uint16_t)address);
    TBLPAG = wTBLPAGSave;
 
    return dwvResult.Val;
}

