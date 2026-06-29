#ifndef XNX_I2C_H
#define XNX_I2C_H

/*
 * xnx_i2c.h — personal I2C utility library
 *
 * SETUP (in your main.c or wherever you use this):
 *
 *   #define XNX_I2C_BUS  (&hi2c1)   // point to any I2CX handle
 *   #include "xnx_i2c.h"
 *
 * The HAL header must be included before this file (main.h already does it).
 * Works on any STM32 — just change XNX_I2C_BUS.
 */

#include <stdint.h>

/* -------------------------------------------------------------------------
 * Result type for I2C scan
 * -------------------------------------------------------------------------
 * Addresses 0x00–0x07 and 0x78–0x7F are reserved by the I2C spec.
 * Usable range is 0x08–0x77 → 112 addresses maximum.
 * -------------------------------------------------------------------------*/
typedef struct {
    uint8_t addr[112];
    uint8_t count;
} xnx_i2c_scan_t;

/* -------------------------------------------------------------------------
 * xnx_i2c_scan_ex — scan with explicit bus handle
 *
 *   hi2c   : pointer to any I2C_HandleTypeDef (hi2c1, hi2c2, ...)
 *   result : pointer to xnx_i2c_scan_t to fill
 *   returns: number of devices found
 * -------------------------------------------------------------------------*/
static inline uint8_t xnx_i2c_scan_ex(I2C_HandleTypeDef *hi2c,
                                       xnx_i2c_scan_t    *result)
{
    result->count = 0;

    for (uint8_t addr = 0x08; addr <= 0x77; addr++) {
        /* HAL expects 8-bit address (7-bit << 1) */
        HAL_StatusTypeDef s = HAL_I2C_IsDeviceReady(hi2c, (uint16_t)(addr << 1), 2, 10);
        if (s == HAL_OK) {
            result->addr[result->count++] = addr;
        }
    }

    return result->count;
}

/* -------------------------------------------------------------------------
 * xnx_i2c_scan — scan using the configured default bus (XNX_I2C_BUS)
 *
 * Implemented as a macro so XNX_I2C_BUS expands at the call site,
 * not at include time — avoids forward-declaration issues with CubeMX
 * globals that are declared after the includes block.
 *
 * Requires: #define XNX_I2C_BUS (&hi2cX) before including this header
 * -------------------------------------------------------------------------*/
#ifdef XNX_I2C_BUS
#define xnx_i2c_scan(result) xnx_i2c_scan_ex(XNX_I2C_BUS, (result))
#endif /* XNX_I2C_BUS */

#endif /* XNX_I2C_H */
