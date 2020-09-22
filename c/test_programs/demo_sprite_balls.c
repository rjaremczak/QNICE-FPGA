/*  VGA Sprite demonstration
 *
 *  This program demonstrates bouncing balls using all 128 sprites.
 *
 *  How to compile: qvc demo_sprite_balls.c -O3 -c99
 *
 *  done by MJoergen in September 2020
*/

#include <stdio.h>

#include "qmon.h"
#include "sysdef.h"

// convenient mechanism to access QNICE's Memory Mapped IO registers
#define MMIO( __x ) *((unsigned int volatile *) __x )

// low level write to Sprite RAM
static void sprite_wr(unsigned int addr, unsigned int data)
{
   MMIO(VGA_SPRITE_ADDR) = addr;
   MMIO(VGA_SPRITE_DATA) = data;
} // end of sprite_wr

#define NUM_SPRITES 128


typedef unsigned int t_bitmap[32*32/4];

static const t_bitmap bitmap_r16 = {
   0x0000, 0x0000, 0x0000, 0x1111, 0x1111, 0x0000, 0x0000, 0x0000,
   0x0000, 0x0000, 0x0111, 0x1111, 0x1111, 0x1110, 0x0000, 0x0000,
   0x0000, 0x0001, 0x1111, 0x1111, 0x1111, 0x1111, 0x1000, 0x0000,
   0x0000, 0x0011, 0x1111, 0x1111, 0x1111, 0x1111, 0x1100, 0x0000,
   0x0000, 0x0111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1110, 0x0000,
   0x0000, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x0000,
   0x0001, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1000,
   0x0011, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1100,
   0x0011, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1100,
   0x0111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1110,
   0x0111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1110,
   0x0111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1110,
   0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111,
   0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111,
   0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111,
   0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111,
   0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111,
   0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111,
   0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111,
   0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111,
   0x0111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1110,
   0x0111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1110,
   0x0111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1110,
   0x0011, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1100,
   0x0011, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1100,
   0x0001, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1000,
   0x0000, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1111, 0x0000,
   0x0000, 0x0111, 0x1111, 0x1111, 0x1111, 0x1111, 0x1110, 0x0000,
   0x0000, 0x0011, 0x1111, 0x1111, 0x1111, 0x1111, 0x1100, 0x0000,
   0x0000, 0x0001, 0x1111, 0x1111, 0x1111, 0x1111, 0x1000, 0x0000,
   0x0000, 0x0000, 0x0111, 0x1111, 0x1111, 0x1110, 0x0000, 0x0000,
   0x0000, 0x0000, 0x0000, 0x1111, 0x1111, 0x0000, 0x0000, 0x0000
};

static const t_bitmap bitmap_r8 = {
   0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
   0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
   0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
   0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
   0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
   0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
   0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
   0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
   0x0000, 0x0000, 0x0000, 0x0111, 0x1110, 0x0000, 0x0000, 0x0000,
   0x0000, 0x0000, 0x0001, 0x1111, 0x1111, 0x1000, 0x0000, 0x0000,
   0x0000, 0x0000, 0x0011, 0x1111, 0x1111, 0x1100, 0x0000, 0x0000,
   0x0000, 0x0000, 0x0111, 0x1111, 0x1111, 0x1110, 0x0000, 0x0000,
   0x0000, 0x0000, 0x0111, 0x1111, 0x1111, 0x1110, 0x0000, 0x0000,
   0x0000, 0x0000, 0x1111, 0x1111, 0x1111, 0x1111, 0x0000, 0x0000,
   0x0000, 0x0000, 0x1111, 0x1111, 0x1111, 0x1111, 0x0000, 0x0000,
   0x0000, 0x0000, 0x1111, 0x1111, 0x1111, 0x1111, 0x0000, 0x0000,
   0x0000, 0x0000, 0x1111, 0x1111, 0x1111, 0x1111, 0x0000, 0x0000,
   0x0000, 0x0000, 0x1111, 0x1111, 0x1111, 0x1111, 0x0000, 0x0000,
   0x0000, 0x0000, 0x1111, 0x1111, 0x1111, 0x1111, 0x0000, 0x0000,
   0x0000, 0x0000, 0x0111, 0x1111, 0x1111, 0x1110, 0x0000, 0x0000,
   0x0000, 0x0000, 0x0111, 0x1111, 0x1111, 0x1110, 0x0000, 0x0000,
   0x0000, 0x0000, 0x0011, 0x1111, 0x1111, 0x1100, 0x0000, 0x0000,
   0x0000, 0x0000, 0x0001, 0x1111, 0x1111, 0x1000, 0x0000, 0x0000,
   0x0000, 0x0000, 0x0000, 0x0111, 0x1110, 0x0000, 0x0000, 0x0000,
   0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
   0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
   0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
   0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
   0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
   0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
   0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
   0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000
};


// Copy bitmap to sprite bitmap memory, and return address used
static unsigned int sprite_add_bitmap(const t_bitmap *pBitmap)
{
   static unsigned int bitmap_ptr = VGA_SPRITE_BITMAP;   // Initialized to first free bitmap

   for (int i=0; i<32*32/4; ++i)
   {
      sprite_wr(bitmap_ptr+i, *(((const unsigned int *)pBitmap) + i));
   }

   unsigned int addr = bitmap_ptr;
   bitmap_ptr += 32*32/4;                                // Update bitmap_ptr
   return addr;
} // sprite_add_bitmap


typedef struct
{
   int pos_x_scaled;             // Units of 1/32 pixels
   int pos_y_scaled;             // Units of 1/32 pixels
   int vel_x_scaled;             // Units of 1/32 pixels/frame
   int vel_y_scaled;             // Units of 1/32 pixels/frame
   unsigned int radius_scaled;   // Units of 1/32 pixels
   unsigned int bitmap_ptr;
   unsigned int color;
} t_ball;

t_ball balls[NUM_SPRITES];

static void sprite_init(unsigned int sprite_num, const t_ball ball)
{
   // Clear sprite palette
   unsigned int addr = VGA_SPRITE_PALETTE + sprite_num*16;
   for (int i=0; i<16; ++i)
   {
      sprite_wr(addr++, VGA_COLOR_TRANSPARENT);
   }

   // Set sprite palette index 1
   sprite_wr(VGA_SPRITE_PALETTE + 1 + sprite_num*16, ball.color);

   int pos_x = ball.pos_x_scaled / 32;
   int pos_y = ball.pos_y_scaled / 32;

   // Configure sprite
   sprite_wr(VGA_SPRITE_CONFIG + VGA_SPRITE_BITMAP_PTR + sprite_num*4, ball.bitmap_ptr);
   sprite_wr(VGA_SPRITE_CONFIG + VGA_SPRITE_CSR        + sprite_num*4, VGA_SPRITE_CSR_VISIBLE);
} // sprite_init

static unsigned int rand()
{
   static unsigned long g_seed = 3;

	const unsigned long A = 48271;

	unsigned long low  = (g_seed & 0x7fff) * A;
	unsigned long high = (g_seed >> 15)    * A;

	unsigned long x = low + ((high & 0xffff) << 15) + (high >> 16);

	x = (x & 0x7fffffff) + (x >> 31);
   g_seed = x;

   return g_seed >> 8;
}

#define NUM_ELEMENTS(x) (sizeof(x)/sizeof(*x))

static void init_all_sprites()
{
   // Enable sprites
   MMIO(VGA_STATE) |= VGA_EN_SPRITE;

   // Initialize images
   struct
   {
      unsigned int radius_scaled;
      unsigned int bitmap_ptr;
   } images[2];

   images[0].radius_scaled = 8*32;
   images[0].bitmap_ptr    = sprite_add_bitmap(&bitmap_r8);

   images[1].radius_scaled = 16*32;
   images[1].bitmap_ptr    = sprite_add_bitmap(&bitmap_r16);

   // Initialize colors
   const unsigned int colors[] = {
      VGA_COLOR_DARK_GRAY,
      VGA_COLOR_RED,
      VGA_COLOR_BLUE,
      VGA_COLOR_GREEN,
      VGA_COLOR_BROWN,
      VGA_COLOR_PURPLE,
      VGA_COLOR_LIGHT_GRAY,
      VGA_COLOR_LIGHT_GREEN,
      VGA_COLOR_LIGHT_BLUE,
      VGA_COLOR_CYAN,
      VGA_COLOR_ORANGE,
      VGA_COLOR_YELLOW,
      VGA_COLOR_TAN,
      VGA_COLOR_PINK,
      VGA_COLOR_WHITE
   };
 
   // Initialize each sprite
   for (unsigned int i=0; i<NUM_SPRITES; ++i)
   {
      int image_index = rand()%NUM_ELEMENTS(images);
      int color_index = rand()%NUM_ELEMENTS(colors);

      balls[i].pos_x_scaled  = (rand()%640)*32;
      balls[i].pos_y_scaled  = (rand()%480)*32;
      balls[i].vel_x_scaled  = rand()%64-32;
      balls[i].vel_y_scaled  = rand()%64-32;
      balls[i].radius_scaled = images[image_index].radius_scaled;
      balls[i].bitmap_ptr    = images[image_index].bitmap_ptr;
      balls[i].color         = colors[color_index];

      sprite_init(i, balls[i]);
   }
} // init_all_sprites

static void update()
{
   for (unsigned int i=0; i<NUM_SPRITES; ++i)
   {
      t_ball *pBall = &balls[i];

      pBall->pos_x_scaled += pBall->vel_x_scaled;
      pBall->pos_y_scaled += pBall->vel_y_scaled;

      if (pBall->pos_x_scaled < pBall->radius_scaled && pBall->vel_x_scaled < 0)
      {
         pBall->pos_x_scaled = pBall->radius_scaled;
         pBall->vel_x_scaled = -pBall->vel_x_scaled;
      }

      if (pBall->pos_x_scaled >= 640*32-pBall->radius_scaled && pBall->vel_x_scaled > 0)
      {
         pBall->pos_x_scaled = 640*32-1-pBall->radius_scaled;
         pBall->vel_x_scaled = -pBall->vel_x_scaled;

      }

      if (pBall->pos_y_scaled < pBall->radius_scaled && pBall->vel_y_scaled < 0)
      {
         pBall->pos_y_scaled = pBall->radius_scaled;
         pBall->vel_y_scaled = -pBall->vel_y_scaled;
      }

      if (pBall->pos_y_scaled >= 480*32-pBall->radius_scaled && pBall->vel_y_scaled > 0)
      {
         pBall->pos_y_scaled = 480*32-1-pBall->radius_scaled;
         pBall->vel_y_scaled = -pBall->vel_y_scaled;
      }

//      for (unsigned int j=i+1; j<NUM_SPRITES; ++j)
//      {
//         t_ball *pOtherBall = &balls[j];
//         long diff_pos_x_scaled = pOtherBall->pos_x_scaled - pBall->pos_x_scaled;
//         long diff_pos_y_scaled = pOtherBall->pos_y_scaled - pBall->pos_y_scaled;
//         long sum_r_scaled = pBall->radius_scaled + pOtherBall->radius_scaled;
//
//         if (diff_pos_x_scaled*diff_pos_x_scaled +
//             diff_pos_y_scaled*diff_pos_y_scaled <
//             sum_r_scaled*sum_r_scaled)
//         {
//            // The two balls have collided
//         }
//      }
   }
} // update

static void draw()
{
   for (unsigned int i=0; i<NUM_SPRITES; ++i)
   {
      t_ball *pBall = &balls[i];

      int pos_x = pBall->pos_x_scaled/32 - 16;
      int pos_y = pBall->pos_y_scaled/32 - 16;

      // Configure sprite
      sprite_wr(VGA_SPRITE_CONFIG + VGA_SPRITE_POS_X + i*4, pos_x);
      sprite_wr(VGA_SPRITE_CONFIG + VGA_SPRITE_POS_Y + i*4, pos_y);
   }
} // draw

int main()
{
   init_all_sprites();
   while (1)
   {
      while (MMIO(VGA_SCAN_LINE) == 480) {}
      while (MMIO(VGA_SCAN_LINE) != 480) {}
      update();
      draw();
      printf(".");
      fflush(stdout);
      if (MMIO(IO_UART_SRA) & 1)
         break;
   }

   qmon_gets();
   return 0;
} // main

