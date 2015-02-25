#include <xc.h>

/* This address defines the starting addres of the user memory. */
#define BOOT_CONFIG_USER_MEMORY_START_ADDRESS                   0x00001800

#define BOOT_ERASE_BLOCK_SIZE                                   1024

/* Defines the first page to start erasing.  We will set this to the
 * first block of user program memory, but in some applications the user
 * might want to change this so there is a block of user memory that
 * doesn't ever get changed when a new app is loaded (serial number,
 * board specific calibration data, etc.).  This option allows the user
 * to make such a region at the start of the memory. */
#define	BOOT_CONFIG_USER_MEMORY_ERASE_PAGE_START                (BOOT_CONFIG_USER_MEMORY_START_ADDRESS/BOOT_ERASE_BLOCK_SIZE)

#if defined(__PIC24FJ256GB210__) || defined(__PIC24FJ256GB206__)
    /* This address defines the address at which programming ends (NOTE: this
     * address does not get programmed as it is the address where programming
     * ends).  This address must be word aligned.  This option is for if the
     * config words are not going to be programmed.
     */
    #define BOOT_CONFIG_USER_MEMORY_END_ADDRESS_NO_CONFIGS      0x0002A800

    /* This address defines the address at which programming ends (NOTE: this
     * address does not get programmed as it is the address where programming
     * ends).  This address must be word aligned.  This option is for if the
     * config words are going to be programmed.
     */
    #define BOOT_CONFIG_USER_MEMORY_END_ADDRESS_CONFIGS         0x0002ABF8

    #define BOOT_MEMORY_CONFIG_START_ADDRESS                    0x0002ABF8
    #define BOOT_MEMORY_CONFIG_END_ADDRESS                      0x0002AC00
#elif defined(__PIC24FJ128GB210__) || defined(__PIC24FJ128GB206__)
    #define BOOT_CONFIG_USER_MEMORY_END_ADDRESS_NO_CONFIGS      0x00015400
    #define BOOT_CONFIG_USER_MEMORY_END_ADDRESS_CONFIGS         0x000157F8
    #define BOOT_MEMORY_CONFIG_START_ADDRESS                    0x000157F8
    #define BOOT_MEMORY_CONFIG_END_ADDRESS                      0x00015800
#elif defined(__PIC24FJ256GB110__) || defined(__PIC24FJ256GB108__) || defined(__PIC24FJ256GB106__)
    /* This address defines the address at which programming ends (NOTE: this
     * address does not get programmed as it is the address where programming
     * ends).  This address must be word aligned.  This option is for if the
     * config words are not going to be programmed.
     */
    #define BOOT_CONFIG_USER_MEMORY_END_ADDRESS_NO_CONFIGS      0x0002A800

    /* This address defines the address at which programming ends (NOTE: this
     * address does not get programmed as it is the address where programming
     * ends).  This address must be word aligned.  This option is for if the
     * config words are going to be programmed.
     */
    #define BOOT_CONFIG_USER_MEMORY_END_ADDRESS_CONFIGS         0x0002ABF8

    #define BOOT_MEMORY_CONFIG_START_ADDRESS                    0x0002ABF8
    #define BOOT_MEMORY_CONFIG_END_ADDRESS                      0x0002AC00
#elif defined(__PIC24FJ192GB110__) || defined(__PIC24FJ192GB108__) || defined(__PIC24FJ192GB106__)
    #define BOOT_CONFIG_USER_MEMORY_END_ADDRESS_NO_CONFIGS      0x00020800
    #define BOOT_CONFIG_USER_MEMORY_END_ADDRESS_CONFIGS         0x00020BF8
    #define BOOT_MEMORY_CONFIG_START_ADDRESS                    0x00020BF8
    #define BOOT_MEMORY_CONFIG_END_ADDRESS                      0x00020C00
#elif defined(__PIC24FJ128GB110__) || defined(__PIC24FJ128GB108__) || defined(__PIC24FJ128GB106__)
    #define BOOT_CONFIG_USER_MEMORY_END_ADDRESS_NO_CONFIGS      0x00015400
    #define BOOT_CONFIG_USER_MEMORY_END_ADDRESS_CONFIGS         0x000157F8
    #define BOOT_MEMORY_CONFIG_START_ADDRESS                    0x000157F8
    #define BOOT_MEMORY_CONFIG_END_ADDRESS                      0x00015800
#elif defined(__PIC24FJ64GB110__) || defined(__PIC24FJ64GB108__) || defined(__PIC24FJ64GB106__)
    #define BOOT_CONFIG_USER_MEMORY_END_ADDRESS_NO_CONFIGS      0x0000A800
    #define BOOT_CONFIG_USER_MEMORY_END_ADDRESS_CONFIGS         0x0000ABF8
    #define BOOT_MEMORY_CONFIG_START_ADDRESS                    0x0000ABF8
    #define BOOT_MEMORY_CONFIG_END_ADDRESS                      0x0000AC00
#else
    #error "Unsupported MCU"
#endif

#define BOOT_CONFIG_USER_MEMORY_ERASE_PAGE_END_NO_CONFIGS       ((BOOT_CONFIG_USER_MEMORY_END_ADDRESS_NO_CONFIGS/BOOT_ERASE_BLOCK_SIZE)-1)
#define BOOT_CONFIG_USER_MEMORY_ERASE_PAGE_END_CONFIGS          ((BOOT_MEMORY_CONFIG_END_ADDRESS/BOOT_ERASE_BLOCK_SIZE)-1)
