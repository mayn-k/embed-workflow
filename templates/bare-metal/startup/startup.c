/*
 * startup.c — Cortex-M4 startup: vector table, reset handler, .data/.bss init.
 *
 * No asm needed — the Cortex-M4 ABI lets us do the whole reset path in C
 * because on reset the core pops SP from vector[0] and PC from vector[1]
 * before executing any code. So by the time Reset_Handler runs, we have a
 * valid stack and can just write C.
 */
#include <stdint.h>

/* Symbols provided by the linker script */
extern uint32_t _stack_top;
extern uint32_t _sdata, _edata, _sidata;
extern uint32_t _sbss,  _ebss;

/* Application entry */
int main(void);

void Reset_Handler(void);
void Default_Handler(void);

/* Core exception handlers — weak aliases to Default_Handler; override by
 * defining a function of the same name elsewhere. */
void NMI_Handler(void)        __attribute__((weak, alias("Default_Handler")));
void HardFault_Handler(void)  __attribute__((weak, alias("Default_Handler")));
void MemManage_Handler(void)  __attribute__((weak, alias("Default_Handler")));
void BusFault_Handler(void)   __attribute__((weak, alias("Default_Handler")));
void UsageFault_Handler(void) __attribute__((weak, alias("Default_Handler")));
void SVC_Handler(void)        __attribute__((weak, alias("Default_Handler")));
void DebugMon_Handler(void)   __attribute__((weak, alias("Default_Handler")));
void PendSV_Handler(void)     __attribute__((weak, alias("Default_Handler")));
void SysTick_Handler(void)    __attribute__((weak, alias("Default_Handler")));

/* Vector table — must be placed at the start of flash by the linker
 * (section .isr_vector). First entry = initial MSP, second = reset. */
__attribute__((section(".isr_vector"), used))
void (* const vector_table[])(void) = {
    (void (*)(void)) &_stack_top, /* 0x00: initial stack pointer            */
    Reset_Handler,                /* 0x04: Reset                             */
    NMI_Handler,                  /* 0x08: NMI                               */
    HardFault_Handler,            /* 0x0C: Hard Fault                        */
    MemManage_Handler,            /* 0x10: MPU Fault                         */
    BusFault_Handler,             /* 0x14: Bus Fault                         */
    UsageFault_Handler,           /* 0x18: Usage Fault                       */
    0, 0, 0, 0,                   /* 0x1C-0x28: reserved                     */
    SVC_Handler,                  /* 0x2C: SVCall                            */
    DebugMon_Handler,             /* 0x30: Debug Monitor                     */
    0,                            /* 0x34: reserved                          */
    PendSV_Handler,               /* 0x38: PendSV                            */
    SysTick_Handler,              /* 0x3C: SysTick                           */
    /* External IRQs (STM32L476 peripheral vectors) go here.
     * Leave empty for now — the minimum valid vector table ends at SysTick. */
};

/* Reset handler: init .data, zero .bss, call main(). */
void Reset_Handler(void) {
    /* Copy .data initializers from flash to RAM */
    uint32_t *src = &_sidata;
    uint32_t *dst = &_sdata;
    while (dst < &_edata) {
        *dst++ = *src++;
    }

    /* Zero .bss */
    dst = &_sbss;
    while (dst < &_ebss) {
        *dst++ = 0;
    }

    /* Jump to application */
    (void) main();

    /* main() should never return; if it does, spin forever */
    while (1) { }
}

/* Default trap — unhandled exceptions end up here.
 * Put a breakpoint on this symbol when debugging unexpected resets. */
void Default_Handler(void) {
    while (1) { }
}
