// Copyright (c) 2016, XMOS Ltd, All rights reserved

#include <platform.h>
#include <xs1.h>

#include "xcore_c.h"
#include <quadflashlib.h>
#ifdef USB_SERIAL
#include "usb.h"
#include "xud_cdc.h"
#endif
#ifdef FTDI_SERIAL
#include "uart.h"
#endif


extern void cpu_execute(chanend c_addrData);
extern void decodeMem(chanend c_addrData, chanend c_acia, chanend c_rtc,
                      chanend c_pia, chanend c_ramdisk, chanend c_promdisk,
                      chanend c_gdc, chanend c_tmr);

#ifdef USB_SERIAL
extern void acia(client interface usb_cdc_interface cdc0, client interface usb_cdc_interface cdc1, chanend c_acia);
#endif

#ifdef FTDI_SERIAL
extern void acia(client uart_tx_if i_tx0, client uart_rx_if i_rx0, // (WD2123)
                 client uart_tx_if i_tx1, client uart_rx_if i_rx1,
                 chanend c_acia);
#endif
extern void rtc(chanend c_rtc);
extern void pia(chanend c_pia, chanend c_bell);
extern void ramdisk(chanend c_ramdisk);
extern void promdisk(chanend c_promdisk);
extern void gdc(chanend c_disp, chanend c_gdc, chanend c_bell);
extern void gdcDisplay(chanend c_disp);
extern void tmr(chanend c_tmr);
// DEBUG led
on tile[1] : out port p_debug_led = XS1_PORT_1B;

#ifdef FTDI_SERIAL
// serial port I/O
on tile[1] :port p_uart_tx0 = XS1_PORT_1M;
on tile[1] :port p_uart_rx0 = XS1_PORT_1N;
on tile[1] :port p_uart_tx1 = XS1_PORT_1O;
on tile[1] :port p_uart_rx1 = XS1_PORT_1P;
#endif

// USB Endpoint Defines
#define XUD_EP_COUNT_OUT   3    //Includes EP0 (1 OUT EP0 + 1 BULK OUT EP)
#define XUD_EP_COUNT_IN    5    //Includes EP0 (1 IN EP0 + 1 INTERRUPT IN EP + 1 BULK IN EP)

#define FLASH_PERIOD    500000

// flash a led to show that we're alive
void DasBlinkenLights(out port p_debug_led) {
    timer tmr;
    unsigned int t, on_time, off_time, i;

    tmr :> t;
    while (1) {

        on_time = FLASH_PERIOD/2;
        off_time = FLASH_PERIOD/2;

        for (i=0; i<FLASH_PERIOD/2000; i++) {
            p_debug_led <: -1; // -1 always works with differing port widths
            t += on_time;
            tmr when timerafter(t) :> int _;
            p_debug_led <: 0;
            t += off_time;
            tmr when timerafter(t) :> int _;
            if (on_time >= 2000) {
                on_time-=1000;
            }
            if (off_time < FLASH_PERIOD) {
                off_time+=1000;
            }
        }//of for

        for (i=0; i<FLASH_PERIOD/2000; i++) {
            p_debug_led <: -1;
            t += on_time;
            tmr when timerafter(t) :> int _;
            p_debug_led <: 0;
            t += off_time;
            tmr when timerafter(t) :> int _;
            if (off_time >= 2000) {
                off_time-=1000;
            }
            if (on_time < FLASH_PERIOD) {
                on_time+=1000;
            }
        }//of for

    }// of while
}


int main() {

#ifdef FTDI_SERIAL
#define RX_BUFFER_SIZE 512
#define BAUD_RATE 115200
    interface uart_rx_if i_rx0, i_rx1;
    interface uart_tx_if i_tx0, i_tx1;
    input_gpio_if i_gpio_rx0[1], i_gpio_rx1[1];
    output_gpio_if i_gpio_tx0[1], i_gpio_tx1[1];
#endif

#ifdef USB_SERIAL
    interface usb_cdc_interface cdc_data[2];
    chan c_ep_out[XUD_EP_COUNT_OUT], c_ep_in[XUD_EP_COUNT_IN];
#endif
    chan c_addrData, c_acia, c_rtc, c_pia, c_ramdisk, c_promdisk, c_disp, c_gdc, c_bell, c_tmr;

    par {
        on tile[0]: cpu_execute(c_addrData);                 // (6809)
        on tile[0]: decodeMem(c_addrData, c_acia, c_rtc,     // (MC6883)
                              c_pia, c_ramdisk, c_promdisk,
                              c_gdc, c_tmr);

        on tile[0]: rtc(c_rtc);                              // (MC146818) I2C -> external RTC/EEPROM
        on tile[0]: pia(c_pia, c_bell);                      // (MC6821) includes PS/2 keyboard interface
        on tile[0]: promdisk(c_promdisk);                    // external QSPI flash (1/2MB -> 3MB)
        on tile[0]: gdc(c_disp, c_gdc, c_bell);              // (uPD7220A) graphics engine
        on tile[0]: gdcDisplay(c_disp);                      // (uPD7220A) display interface
        on tile[0]: tmr(c_tmr);                              // 20ms timer
        //on tile[0]: fdc(c_fdc);                            // (WD1770)


        on tile[1]: DasBlinkenLights(p_debug_led);
        on tile[1]: ramdisk(c_ramdisk);                      // 40track DS/SD emulation (200KB)

#ifdef FTDI_SERIAL
        on tile[1]: acia(i_tx0, i_rx0, i_tx1, i_rx1, c_acia);// (WD2123)

        on tile[1]: output_gpio(i_gpio_tx0, 1, p_uart_tx0, null);
        on tile[1]: uart_tx(i_tx0, null, BAUD_RATE, UART_PARITY_NONE, 8, 1, i_gpio_tx0[0]);

        on tile[1]: input_gpio_with_events(i_gpio_rx0, 1, p_uart_rx0, null);
        on tile[1]: uart_rx(i_rx0, null, RX_BUFFER_SIZE, BAUD_RATE, UART_PARITY_NONE, 8, 1, i_gpio_rx0[0]);

        on tile[1]: output_gpio(i_gpio_tx1, 1, p_uart_tx1, null);
        on tile[1]: uart_tx(i_tx1, null, BAUD_RATE, UART_PARITY_NONE, 8, 1, i_gpio_tx1[0]);

        on tile[1]: input_gpio_with_events(i_gpio_rx1, 1, p_uart_rx1, null);
        on tile[1]: uart_rx(i_rx1, null, RX_BUFFER_SIZE, BAUD_RATE, UART_PARITY_NONE, 8, 1, i_gpio_rx1[0]);
  #endif

#ifdef USB_SERIAL
        on tile[1]: acia(cdc_data[0], cdc_data[1], c_acia); // (WD2123)
        // USB interface
        on tile[1]: xud(c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN, null, XUD_SPEED_HS, XUD_PWR_SELF);
        on tile[1]: Endpoint0(c_ep_out[0], c_ep_in[0]);
        on tile[1]: CdcEndpointsHandler(c_ep_in[CDC_NOTIFICATION_EP_NUM1],
                                         c_ep_out[CDC_DATA_RX_EP_NUM1],
                                         c_ep_in[CDC_DATA_TX_EP_NUM1],
                                         cdc_data[0]);
        on tile[1]: CdcEndpointsHandler(c_ep_in[CDC_NOTIFICATION_EP_NUM2],
                                         c_ep_out[CDC_DATA_RX_EP_NUM2],
                                         c_ep_in[CDC_DATA_TX_EP_NUM2],
                                         cdc_data[1]);
#endif

    }// of par
    return 0;
}
