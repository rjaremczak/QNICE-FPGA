-- custom type and constants used by sdcardctrl
-- done by sy2002 in June 2016

library IEEE;
use IEEE.STD_LOGIC_1164.all;

package sdcardctrl_common is

   type CardType_t is (SD_CARD_E, SDHC_CARD_E);  -- Define the different types of SD cards.
     
   constant YES  : std_logic := '1';
   constant NO   : std_logic := '0';
   constant HI   : std_logic := '1';
   constant LO   : std_logic := '0';
   constant ONE  : std_logic := '1';
   constant ZERO : std_logic := '0';
   constant HIZ  : std_logic := 'Z';

end sdcardctrl_common;

package body sdcardctrl_common is
end sdcardctrl_common;