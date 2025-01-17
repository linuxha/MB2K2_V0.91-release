/*
 * ramdisk.xc
 *
 *  Created on: Jul 22, 2019
 *      Author: david
 */

/*
 * ramdisk.xc
 *
 *  Created on: 15 Jul 2019
 *      Author: david
 */

#include "ramdisk.h"

// access LEDs
on tile[1] :port p_rd_led = XS1_PORT_1L;

void ramdisk(chanend c_ramdisk) {

    unsigned param, cmd, addr, track, sector, os9, i;

    timer t;
    unsigned time, end_time;

    //clear memory
        for(i=0; i<RAMDISK_SIZE; i++) {
            rd_mem[i] = 0;
        }

        // on startup format ramdisk.
        // set up free chain (each sector points to the next)
        track = 0;
        sector = 1;
        for (i=0; i<RAMDISK_SIZE; i+=BYTES_PER_SECTOR) {

            if (sector == SECTORS_PER_TRACK) {
                track++;
                sector = 1;
            } else {
                sector++;
            }

            rd_mem[i]   = track;
            rd_mem[i+1] = sector;

        }

        // break links for last sector in free chain and last sector of track 00
        i = BYTES_PER_SECTOR * (SECTORS_PER_TRACK - 1);
        rd_mem[i]   = 0;
        rd_mem[i+1] = 0;
        i = RAMDISK_SIZE - BYTES_PER_SECTOR;
        rd_mem[i]   = 0;
        rd_mem[i+1] = 0;

        // set up System Info Record (SIR)
        i = BYTES_PER_SECTOR * (3-1);  // index to track 0, sector 3
        // break link
        rd_mem[i]   = 0;
        rd_mem[i+1] = 0;

        // set volume name
        rd_mem[i+16] = 'R';
        rd_mem[i+17] = 'A';
        rd_mem[i+18] = 'M';
        rd_mem[i+19] = 'D';
        rd_mem[i+20] = 'I';
        rd_mem[i+21] = 'S';
        rd_mem[i+22] = 'K';

        // set volume number
        rd_mem[i+27] = 0;
        rd_mem[i+28] = 1;

        // set first data sector, last data sector and total sectors in free chain
        rd_mem[i+29] = 1;
        rd_mem[i+30] = 1;

        rd_mem[i+31] = (TRACKS_PER_DISK-1);
        rd_mem[i+32] = SECTORS_PER_TRACK;

        param = (SECTORS_PER_TRACK * (TRACKS_PER_DISK-1));
        rd_mem[i+33] = (param >> 8) & 0xFF;
        rd_mem[i+34] = param & 0xFF;

        //TODO - set date from RTC?
        // creation date
        rd_mem[i+35] = 1;
        rd_mem[i+36] = 1;
        rd_mem[i+37] = 20;

        // higest track/sector
        rd_mem[i+38] = (TRACKS_PER_DISK-1);
        rd_mem[i+39] = SECTORS_PER_TRACK;


        // set valid data flag
        rd_mem[0] = 0xAA;
        rd_mem[1] = 0x55;

        track = 0;
        sector = 1;
        addr = 0;
        os9 = 0;

        while (1) {

            #pragma ordered

            select {

            case c_ramdisk :> param :

                p_rd_led <: -1;
                t :> time;
                end_time = time + 10000; //(100us)

        if (param & 0x80000000) { // write

            switch (param & 0x00000007) {
            case (CONTROL_REG) : // build extended address
                cmd = (param>>16) & 0xFF;

                i = 0;

                if (os9) {
                    addr = (BYTES_PER_SECTOR * ((track << 8) | sector));
                } else {
                    addr = BYTES_PER_SECTOR * ((track * SECTORS_PER_TRACK) + (sector-1));
                }

                break;

            case (TRACK_REG) :
                track = (param>>16) & 0xFF;
                break;

            case (SECTOR_REG) :
                sector = (param>>16) & 0xFF;
                break;

            case (DATA_REG) :
                rd_mem[addr + i] = (param>>16) & 0xFF;
                i++;
                break;

            case (MODE_REG) :
                os9 = (param>>16) & 0xFF;
                break;

            default:
                break;

            }// of switch

        } else { //read

            switch (param & 0x00000007) {
            case (CONTROL_REG) :
                c_ramdisk <: cmd;
                break;

            case (TRACK_REG) :
                c_ramdisk <: track;
                break;

            case (SECTOR_REG) :
                c_ramdisk <: sector;
                break;

            case (DATA_REG) :
                param = rd_mem[addr + i];
                c_ramdisk <: param & 0xFF;
                i++;
                break;

            case (MODE_REG) :
                c_ramdisk <: os9;
                break;

            default:
                c_ramdisk <: 0;
                break;


            }// of switch

        }// of if/else
        break;

        case t when timerafter ( end_time ) :> void : //turn off LED when timer triggers
            p_rd_led <: 0;
            break;

        } // of select

    }// of while

}


