/*  VGA Fractional Scaling demonstration
 *
 *  How to compile: qvc vga_fractional.c conio.c -O3 -c99
 *
 *  done by MJoergen in November 2020
*/

#include <qmon.h>
#include "conio.h"

//convenient mechanism to access QNICE's Memory Mapped IO registers
#define MMIO( __x ) *((unsigned int volatile *) __x )

const char text[][30] = {
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "It is a period  of civil war.\0",
   "                             \0",
   "Rebel  spaceships,   striking\0",
   "                             \0",
   "from  a hidden base, have won\0",
   "                             \0",
   "their  first  victory against\0",
   "                             \0",
   "the   evil  Galactic  Empire.\0",
   "                             \0",
   "                             \0",
   "                             \0",
   "During   the   battle,  Rebel\0",
   "                             \0",
   "spies managed to steal secret\0",
   "                             \0",
   "plans     to   the   Empire's\0",
   "                             \0",
   "ultimate   weapon,  the DEATH\0",
   "                             \0",
   "STAR,   an   armored    space\0",
   "                             \0",
   "station with enough  power to\0",
   "                             \0",
   "destroy   an  entire  planet.\0",
   "                             \0",
   "                             \0",
   "                             \0",
   "Pursued   by   the   Empire's\0",
   "                             \0",
   "sinister   agents,   Princess\0",
   "                             \0",
   "Leia  races  home  aboard her\0",
   "                             \0",
   "starship,  custodian  of  the\0",
   "                             \0",
   "stolen plans  that  can  save\0",
   "                             \0",
   "her    people   and   restore\0",
   "                             \0",
   "freedom  to   the  galaxy....\0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0",
   "                             \0"};

int main()
{
   MMIO(VGA_STATE) &= ~VGA_EN_HW_CURSOR;  // Disable hardware cursor.
   qmon_vga_cls();                        // Clear screen.

#define PERIOD 3  // Scrolling speed of 20 pixels/second.
   int counter = 12*PERIOD;
   int startline = 0;
   while (1)
   {
      int dy = counter/PERIOD;

      if (counter >= 12*PERIOD)
      {
         counter = 0;
         dy = 0;
         MMIO(VGA_ADJUST_Y) = 0;
         startline += 1;

         // Display text on screen
         for (int y=0; y<26; ++y)
         {
            cputsxy(5, y+14, text[y+startline], 0);
         }
      }
      MMIO(VGA_ADJUST_Y) = dy;

      int y;
      while ((y = MMIO(VGA_SCAN_LINE)) >= 480)
      {}
      while ((y = MMIO(VGA_SCAN_LINE)) < 480)
      {
         int z=((y+dy)/12)*12-dy;
         MMIO(VGA_PIXEL_X_SCALE) = (120*256)/(z/2);
         MMIO(VGA_ADJUST_X) = ((z/2)-240)*160/(z/2);
      }

      if (MMIO(IO_UART_SRA) & 1)
      {
         unsigned int tmp = MMIO(IO_UART_RHRA);
         break;
      }
      if (MMIO(IO_KBD_STATE) & KBD_NEW_ANY)
      {
         unsigned int tmp = MMIO(IO_KBD_DATA);
         break;
      }

      counter += 1; // Should increment once every frame, i.e. at 60 Hz.
   } // while

   MMIO(VGA_PIXEL_X_SCALE) = 0x0100;
   MMIO(VGA_PIXEL_Y_SCALE) = 0x0100;
   MMIO(VGA_ADJUST_X) = 0;
   MMIO(VGA_ADJUST_Y) = 0;
   return 0;
} // int main()
