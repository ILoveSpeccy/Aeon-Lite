#ifndef _DEBUG_H_
#define _DEBUG_H_

#define UART_DEBUG 1

#define debug_print(a, ...) do { if (UART_DEBUG) printf(a, ##__VA_ARGS__); } while (0)

#endif // _DEBUG_H_
