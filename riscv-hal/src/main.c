#include <stdbool.h>

#include "uart.h"

void main() {
    uart_init(115200);

    while(true) {
        uart_putCharBlocking(uart_getCharBlocking());
    }
}
