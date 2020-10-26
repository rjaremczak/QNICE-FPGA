#include "tennis.h"

/* Game variables are declared here */

static int move_left  = 0;    // Current status of LEFT cursor key
static int move_right = 0;    // Current status of RIGHT cursor key

static t_vec position = {200, 480}; // Initial position of player


/*
 * This function is called once at start of the program
 */
void player_init()
{
   /* Define player sprite */
   t_sprite_palette palette = sprite_palette_transparent;
   palette[1] = VGA_COLOR_WHITE;
   sprite_set_palette(0, palette);
   sprite_set_bitmap(0, sprite_player);
   sprite_set_config(0, VGA_SPRITE_CSR_VISIBLE);
} // end of player_init


/*
 * This function is called once per frame, i.e. 60 times a second
 */
void player_draw()
{
   /*
    * The player is shown as a semi cirle, and the variables pos_x and pos_y
    * give the centre of this circle. However, sprite coordinates are the upper
    * left corner of the sprite. Therefore, we have to adjust the coordinates
    * with the size of the sprite.
    */
   sprite_set_position(0, position.x-PLAYER_RADIUS, position.y-PLAYER_RADIUS);
} // end of player_draw


/*
 * This function is called once per frame, i.e. 60 times a second
 */
int player_update()
{
   /* Update state of player movement keys */
   int ev = MMIO(IO_KBD_EVENT);
   switch (ev)
   {
      case KBD_CUR_LEFT              : move_left  = 1; break;
      case KBD_CUR_RIGHT             : move_right = 1; break;
      case KBD_CUR_LEFT  | KBD_BREAK : move_left  = 0; break;
      case KBD_CUR_RIGHT | KBD_BREAK : move_right = 0; break;
      case 'q'                       : return 1;   /* q   : Quit program */
      case 'Q'                       : return 1;   /* Q   : Quit program */
      case 0x1b                      : return 1;   /* ESC : Quit program */
      case 0x03                      : return 1;   /* ^C  : Quit program */
#ifdef DEBUG
      default                        : if (ev) {printf("%04x\n", ev);} break;
#endif
   }

   /* Move player */
   if (move_right && !move_left)
   {
      position.x += PLAYER_SPEED;
      if (position.x >= BAR_LEFT - PLAYER_RADIUS)
         position.x = BAR_LEFT - PLAYER_RADIUS;
   }

   if (!move_right && move_left)
   {
      position.x -= PLAYER_SPEED;
      if (position.x < SCREEN_LEFT + PLAYER_RADIUS)
         position.x = SCREEN_LEFT + PLAYER_RADIUS;
   }

   return 0;
} // end of player_update

