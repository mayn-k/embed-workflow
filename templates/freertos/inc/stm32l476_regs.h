/*
 * stm32l476_regs.h — minimal peripheral register definitions
 *
 * This is NOT a HAL. It's just a typed view of the bare hardware registers,
 * so you can write:
 *
 *     GPIOA->MODER |= (1 << (5*2));
 *
 * instead of:
 *
 *     *(volatile uint32_t*)0x48000000 |= (1 << (5*2));
 *
 * Only peripherals needed for blinky are defined here. Add more as you go —
 * every register address comes from the STM32L476 Reference Manual (RM0351).
 *
 * Reference: STM32L476xx Reference Manual RM0351
 *            https://www.st.com/resource/en/reference_manual/rm0351-*.pdf
 */

#ifndef STM32L476_REGS_H
#define STM32L476_REGS_H

#include <stdint.h>

/* ─── Memory-map base addresses (RM0351 Table 1 / Fig 1) ──────────────── */
#define PERIPH_BASE       0x40000000UL
#define AHB1PERIPH_BASE   (PERIPH_BASE + 0x00020000UL)  /* 0x40020000 */
#define AHB2PERIPH_BASE   0x48000000UL

/* ─── RCC — Reset & Clock Control (RM0351 §6.4) ───────────────────────── */
#define RCC_BASE          (AHB1PERIPH_BASE + 0x1000UL)  /* 0x40021000 */

typedef struct {
    volatile uint32_t CR;           /* 0x00 Clock control */
    volatile uint32_t ICSCR;        /* 0x04 Internal clock sources calibration */
    volatile uint32_t CFGR;         /* 0x08 Clock configuration */
    volatile uint32_t PLLCFGR;      /* 0x0C PLL configuration */
    volatile uint32_t PLLSAI1CFGR;  /* 0x10 */
    volatile uint32_t PLLSAI2CFGR;  /* 0x14 */
    volatile uint32_t CIER;         /* 0x18 Clock interrupt enable */
    volatile uint32_t CIFR;         /* 0x1C Clock interrupt flag */
    volatile uint32_t CICR;         /* 0x20 Clock interrupt clear */
    uint32_t _RESERVED0;            /* 0x24 */
    volatile uint32_t AHB1RSTR;     /* 0x28 AHB1 peripheral reset */
    volatile uint32_t AHB2RSTR;     /* 0x2C AHB2 peripheral reset */
    volatile uint32_t AHB3RSTR;     /* 0x30 AHB3 peripheral reset */
    uint32_t _RESERVED1;            /* 0x34 */
    volatile uint32_t APB1RSTR1;    /* 0x38 */
    volatile uint32_t APB1RSTR2;    /* 0x3C */
    volatile uint32_t APB2RSTR;     /* 0x40 */
    uint32_t _RESERVED2;            /* 0x44 */
    volatile uint32_t AHB1ENR;      /* 0x48 AHB1 peripheral clock enable */
    volatile uint32_t AHB2ENR;      /* 0x4C AHB2 peripheral clock enable */
    volatile uint32_t AHB3ENR;      /* 0x50 AHB3 peripheral clock enable */
    uint32_t _RESERVED3;            /* 0x54 */
    volatile uint32_t APB1ENR1;     /* 0x58 */
    volatile uint32_t APB1ENR2;     /* 0x5C */
    volatile uint32_t APB2ENR;      /* 0x60 */
} RCC_TypeDef;

#define RCC  ((RCC_TypeDef*) RCC_BASE)

/* RCC_AHB2ENR bit definitions (the ones you'll actually use) */
#define RCC_AHB2ENR_GPIOAEN  (1U << 0)
#define RCC_AHB2ENR_GPIOBEN  (1U << 1)
#define RCC_AHB2ENR_GPIOCEN  (1U << 2)
#define RCC_AHB2ENR_GPIODEN  (1U << 3)
#define RCC_AHB2ENR_GPIOEEN  (1U << 4)
#define RCC_AHB2ENR_GPIOFEN  (1U << 5)
#define RCC_AHB2ENR_GPIOGEN  (1U << 6)
#define RCC_AHB2ENR_GPIOHEN  (1U << 7)

/* ─── GPIO (RM0351 §8.4) ──────────────────────────────────────────────── */
typedef struct {
    volatile uint32_t MODER;    /* 0x00 mode (00=in, 01=out, 10=AF, 11=analog) */
    volatile uint32_t OTYPER;   /* 0x04 output type (0=push-pull, 1=open-drain) */
    volatile uint32_t OSPEEDR;  /* 0x08 output speed */
    volatile uint32_t PUPDR;    /* 0x0C pull-up/pull-down */
    volatile uint32_t IDR;      /* 0x10 input data register */
    volatile uint32_t ODR;      /* 0x14 output data register */
    volatile uint32_t BSRR;     /* 0x18 bit set/reset (atomic) */
    volatile uint32_t LCKR;     /* 0x1C lock */
    volatile uint32_t AFRL;     /* 0x20 alternate function low */
    volatile uint32_t AFRH;     /* 0x24 alternate function high */
    volatile uint32_t BRR;      /* 0x28 bit reset */
} GPIO_TypeDef;

#define GPIOA_BASE  (AHB2PERIPH_BASE + 0x0000UL)  /* 0x48000000 */
#define GPIOB_BASE  (AHB2PERIPH_BASE + 0x0400UL)
#define GPIOC_BASE  (AHB2PERIPH_BASE + 0x0800UL)
#define GPIOD_BASE  (AHB2PERIPH_BASE + 0x0C00UL)
#define GPIOE_BASE  (AHB2PERIPH_BASE + 0x1000UL)
#define GPIOF_BASE  (AHB2PERIPH_BASE + 0x1400UL)
#define GPIOG_BASE  (AHB2PERIPH_BASE + 0x1800UL)
#define GPIOH_BASE  (AHB2PERIPH_BASE + 0x1C00UL)

#define GPIOA  ((GPIO_TypeDef*) GPIOA_BASE)
#define GPIOB  ((GPIO_TypeDef*) GPIOB_BASE)
#define GPIOC  ((GPIO_TypeDef*) GPIOC_BASE)
#define GPIOD  ((GPIO_TypeDef*) GPIOD_BASE)
#define GPIOE  ((GPIO_TypeDef*) GPIOE_BASE)
#define GPIOF  ((GPIO_TypeDef*) GPIOF_BASE)
#define GPIOG  ((GPIO_TypeDef*) GPIOG_BASE)
#define GPIOH  ((GPIO_TypeDef*) GPIOH_BASE)

/* GPIO MODER values */
#define GPIO_MODE_INPUT   0x0U
#define GPIO_MODE_OUTPUT  0x1U
#define GPIO_MODE_AF      0x2U
#define GPIO_MODE_ANALOG  0x3U

/* ─── SysTick (Cortex-M4 Generic User Guide) ──────────────────────────── */
typedef struct {
    volatile uint32_t CTRL;   /* 0xE000E010 control & status */
    volatile uint32_t LOAD;   /* 0xE000E014 reload value */
    volatile uint32_t VAL;    /* 0xE000E018 current value */
    volatile uint32_t CALIB;  /* 0xE000E01C calibration */
} SysTick_TypeDef;

#define SysTick_BASE  0xE000E010UL
#define SysTick       ((SysTick_TypeDef*) SysTick_BASE)

#define SysTick_CTRL_ENABLE     (1U << 0)
#define SysTick_CTRL_TICKINT    (1U << 1)
#define SysTick_CTRL_CLKSOURCE  (1U << 2)  /* 0=HCLK/8, 1=HCLK */
#define SysTick_CTRL_COUNTFLAG  (1U << 16)

#endif /* STM32L476_REGS_H */
