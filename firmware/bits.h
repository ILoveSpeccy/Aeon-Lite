/* Bit setzen */
#ifndef set_bit
   #define set_bit(var, bit) ((var) |= (1 << (bit)))
#endif

/* Bit löschen */
#ifndef clear_bit
   #define clear_bit(var, bit) ((var) &= (unsigned)~(1 << (bit)))
#endif

/* Bit togglen */
#ifndef toggle_bit
   #define toggle_bit(var,bit) ((var) ^= (1 << (bit)))
#endif

/* Bit abfragen */
#ifndef bit_is_set
   #define bit_is_set(var, bit) ((var) & (1 << (bit)))
#endif

#ifndef bit_is_clear
   #define bit_is_clear(var, bit) !bit_is_set(var, bit)
#endif

/* Konstante in Binärschreibweise angeben (max. 8 Bit) */
/* Beispiel: BIN(1001011)                              */
/*               ^------ ACHTUNG, stets OHNE fuehrende */
/*                       0 angeben, da sonst Oktalzahl */
#ifndef BIN
   #define BIN(x) \
          (((x)%10)\
         |((((x)/10)%10)<<1)\
         |((((x)/100)%10)<<2)\
         |((((x)/1000)%10)<<3)\
         |((((x)/10000)%10)<<4)\
         |((((x)/100000)%10)<<5)\
         |((((x)/1000000)%10)<<6)\
         |((((x)/10000000)%10)<<7)\
         )
#endif

/* Alternative mit Kommatrennung (genau 8 Bit angeben) */
/* Beispiel: BIN8(0,1,0,0,1,0,1,1)                     */
#ifndef BIN8
   #define BIN8(b7,b6,b5,b4,b3,b2,b1,b0) \
        ((b0)\
         |((b1)<<1)\
         |((b2)<<2)\
         |((b3)<<3)\
         |((b4)<<4)\
         |((b5)<<5)\
         |((b6)<<6)\
         |((b7)<<7)\
        )
#endif
