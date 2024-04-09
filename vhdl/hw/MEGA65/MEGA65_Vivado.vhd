----------------------------------------------------------------------------------
-- MEGA65 port of QNICE-FGA
--
-- Top Module for synthesizing the whole machine
-- 
-- done on-again-off-again in 2015, 2016 by sy2002
-- MEGA65 port done in April to August 2020 by sy2002
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

use work.env1_globals.all;

entity MEGA65 is
port (
   CLK            : in std_logic;                  -- 100 MHz clock
   RESET_N        : in std_logic;                  -- CPU reset button
   
   -- serial communication (rxd, txd only; rts/cts are not available)
   -- 115.200 baud, 8-N-1
   UART_RXD    : in std_logic;                     -- receive data
   UART_TXD    : out std_logic;                    -- send data
     
   -- VGA
   VGA_RED        : out std_logic_vector(7 downto 0);
   VGA_GREEN      : out std_logic_vector(7 downto 0);
   VGA_BLUE       : out std_logic_vector(7 downto 0);
   VGA_HS         : out std_logic;
   VGA_VS         : out std_logic;
   
   -- VDAC
   vdac_clk       : out std_logic;
   vdac_sync_n    : out std_logic;
   vdac_blank_n   : out std_logic;
   
   -- HDMI via ADV7511
   hdmi_vsync     : out std_logic;
   hdmi_hsync     : out std_logic;
   hdmired        : out std_logic_vector(7 downto 0);
   hdmigreen      : out std_logic_vector(7 downto 0);
   hdmiblue       : out std_logic_vector(7 downto 0);
   
   hdmi_clk       : out std_logic;      
   hdmi_de        : out std_logic;                 -- high when valid pixels being output
   
   hdmi_int       : in std_logic;                  -- interrupts by ADV7511
   hdmi_spdif     : out std_logic := '0';          -- unused: GND
   hdmi_scl       : inout std_logic;               -- I2C to/from ADV7511: serial clock
   hdmi_sda       : inout std_logic;               -- I2C to/from ADV7511: serial data
   
   -- TPD12S016 companion chip for ADV7511
   --hpd_a          : inout std_logic;
   ct_hpd         : out std_logic := '1';          -- assert to connect ADV7511 to the actual port
   ls_oe          : out std_logic := '1';          -- ditto

   -- MEGA65 smart keyboard controller
   kb_io0         : out std_logic;                 -- clock to keyboard
   kb_io1         : out std_logic;                 -- data output to keyboard
   kb_io2         : in std_logic;                  -- data input from keyboard   
   
   -- SD Card
   SD_RESET       : out std_logic;
   SD_CLK         : out std_logic;
   SD_MOSI        : out std_logic;
   SD_MISO        : in std_logic;
   
   -- Built-in HyperRAM
   hr_d           : inout unsigned(7 downto 0);    -- Data/Address
   hr_rwds        : inout std_logic;               -- RW Data strobe
   hr_reset       : out std_logic;                 -- Active low RESET line to HyperRAM
   hr_clk_p       : out std_logic;
   
   -- Optional additional HyperRAM in trap-door slot
   hr2_d          : inout unsigned(7 downto 0);    -- Data/Address
   hr2_rwds       : inout std_logic;               -- RW Data strobe
   hr2_reset      : out std_logic;                 -- Active low RESET line to HyperRAM
   hr2_clk_p      : out std_logic;
   hr_cs0         : out std_logic;
   hr_cs1         : out std_logic   
); 
end MEGA65;

architecture beh of MEGA65 is

-- QNICE CPU
component QNICE_CPU
port (
   -- clock
   CLK            : in std_logic;
   RESET          : in std_logic;
   
   WAIT_FOR_DATA  : in std_logic;                            -- 1=CPU adds wait cycles while re-reading from bus
      
   ADDR           : out std_logic_vector(15 downto 0);      -- 16 bit address bus
   
   -- bidirectional 16 bit data bus
   DATA_IN        : in std_logic_vector(15 downto 0);       -- receive data
   DATA_OUT       : out std_logic_vector(15 downto 0);      -- send data
   DATA_DIR       : out std_logic;                          -- 1=DATA is sending, 0=DATA is receiving
   DATA_VALID     : out std_logic;                          -- while DATA_DIR = 1: DATA contains valid data
   
   -- signals about the CPU state
   HALT           : out std_logic;                          -- 1=CPU halted due to the HALT command, 0=running
   INS_CNT_STROBE : out std_logic;                          -- goes high for one clock cycle for each new instruction
   
   -- interrupt system                                      -- refer to doc/intro/qnice_intro.pdf to learn how this works
   INT_N          : in std_logic   := '1';
   IGRANT_N       : out std_logic
    
);
end component;

-- ROM
component BROM is
generic (
   FILE_NAME   : string
);
port (
   clk         : in std_logic;                        -- read and write on rising clock edge
   ce          : in std_logic;                        -- chip enable, when low then zero on output
   
   address     : in std_logic_vector(14 downto 0);    -- address is for now 15 bit hard coded
   data        : out std_logic_vector(15 downto 0);   -- read data
   
   busy        : out std_logic                        -- 1=still executing, i.e. can drive CPU's WAIT_FOR_DATA               
);
end component;

-- BLOCK RAM
component BRAM is
port (
   clk      : in std_logic;                        -- read and write on rising clock edge
   ce       : in std_logic;                        -- chip enable, when low then zero on output
   
   address  : in std_logic_vector(14 downto 0);    -- address is for now 16 bit hard coded
   we       : in std_logic;                        -- write enable
   data_i   : in std_logic_vector(15 downto 0);    -- write data
   data_o   : out std_logic_vector(15 downto 0);   -- read data
   
   busy     : out std_logic                        -- 1=still executing, i.e. can drive CPU's WAIT_FOR_DATA   
);
end component;

-- VGA 80x40 monoschrome screen
component vga_textmode is
port (
   reset       : in  std_logic;    -- async reset
   clk25MHz    : in std_logic;
   clk50MHz    : in std_logic;

   -- VGA registers
   en          : in std_logic;     -- enable for reading from or writing to the bus
   we          : in std_logic;     -- write to VGA's registers via system's data bus
   reg         : in std_logic_vector(3 downto 0);     -- register selector
   data_in     : in std_logic_vector(15 downto 0);    -- system's data bus
   data_out    : out std_logic_vector(15 downto 0);   -- system's data bus
   
   -- VGA output signals, monochrome only
   R           : out std_logic;
   G           : out std_logic;
   B           : out std_logic;
   hsync       : out std_logic;
   vsync       : out std_logic;
   
   hdmi_de     : out std_logic   
);
end component;

component hdmi_i2c
generic (
   clock_frequency : integer
);
port (
   clock : in std_logic;

   -- HDMI interrupt to trigger automatic reset
   hdmi_int : in std_logic;
    
   -- I2C bus
   sda : inout std_logic;
   scl : inout std_logic
);
end component;

-- UART
component bus_uart is
generic (
   DIVISOR        : natural               -- see UART_DIVISOR in env1_globals.vhd
);
port (
   clk            : in std_logic;                       
   reset          : in std_logic;

   -- physical interface
   rx             : in std_logic;
   tx             : out std_logic;
   rts            : in std_logic;
   cts            : out std_logic;   
   
   -- conntect to CPU's address and data bus (data goes zero when en=0)
   uart_en        : in std_logic;
   uart_we        : in std_logic;
   uart_reg       : in std_logic_vector(1 downto 0);
   uart_cpu_ws    : out std_logic;   
   cpu_data_in    : in std_logic_vector(15 downto 0);
   cpu_data_out   : out std_logic_vector(15 downto 0)
);
end component;

-- MEGA65 keyboard
component keyboard is
generic (
   clk_freq      : integer
);
port (
   clk           : in std_logic;               -- system clock input
   reset         : in std_logic;               -- system reset
   
   -- MEGA65 smart keyboard controller
   kb_io0 : out std_logic;                     -- clock to keyboard
   kb_io1 : out std_logic;                     -- data output to keyboard
   kb_io2 : in std_logic;                      -- data input from keyboard   
   
   -- conntect to CPU's data bus (data goes zero when all reg_* are 0)
   kbd_en        : in std_logic;
   kbd_we        : in std_logic;
   kbd_reg       : in std_logic_vector(1 downto 0);   
   cpu_data_in   : in std_logic_vector(15 downto 0);
   cpu_data_out  : out std_logic_vector(15 downto 0);
   
   -- allow to control STDIN/STDOUT via pressing <RESTORE>+<1|2> (1=toggle STDIN, 2=toggle STDOUT)
   stdinout      : out std_logic_vector(1 downto 0)   
);
end component;

-- Interrupt generator: Timer Module
component timer_module is
generic (
   CLK_FREQ       : natural                              -- system clock in Hertz
);
port (
   clk            : in std_logic;                        -- system clock
   reset          : in std_logic;                        -- async reset
   
   -- Daisy Chaining: "left/right" comments are meant to describe a situation, where the CPU is the leftmost device
   int_n_out      : out std_logic;                        -- left device's interrupt signal input
   grant_n_in     : in std_logic;                         -- left device's grant signal output
   int_n_in       : in std_logic;                         -- right device's interrupt signal output
   grant_n_out    : out std_logic;                        -- right device's grant signal input
   
   -- Registers
   en             : in std_logic;                        -- enable for reading from or writing to the bus
   we             : in std_logic;                        -- write to the registers via system's data bus
   reg            : in std_logic_vector(2 downto 0);     -- register selector
   data_in        : in std_logic_vector(15 downto 0);    -- system's data bus
   data_out       : out std_logic_vector(15 downto 0)    -- system's data bus
);
end component;

-- impulse (cycle) counter
component cycle_counter is
port (
   clk      : in std_logic;         -- system clock
   impulse  : in std_logic;         -- impulse that is counted   
   reset    : in std_logic;         -- async reset
   
   -- cycle counter's registers
   en       : in std_logic;         -- enable for reading from or writing to the bus
   we       : in std_logic;         -- write to VGA's registers via system's data bus
   reg      : in std_logic_vector(1 downto 0);     -- register selector
   data_in  : in std_logic_vector(15 downto 0);    -- system's data bus
   data_out : out std_logic_vector(15 downto 0)    -- system's data bus
);
end component;

-- EAE - Extended Arithmetic Element (32-bit multiplication, division, modulo)
component EAE is
port (
   clk      : in std_logic;                        -- system clock
   reset    : in std_logic;                        -- system reset
   
   -- EAE registers
   en       : in std_logic;                        -- chip enable
   we       : in std_logic;                        -- write enable
   reg      : in std_logic_vector(2 downto 0);     -- register selector
   data_in  : in std_logic_vector(15 downto 0);    -- system's data bus
   data_out : out std_logic_vector(15 downto 0)    -- system's data bus
);
end component;

-- SD Card
component sdcard is
port (
   clk      : in std_logic;         -- system clock
   reset    : in std_logic;         -- async reset
   
   -- registers
   en       : in std_logic;         -- enable for reading from or writing to the bus
   we       : in std_logic;         -- write to the registers via system's data bus
   reg      : in std_logic_vector(2 downto 0);      -- register selector
   data_in  : in std_logic_vector(15 downto 0);     -- system's data bus
   data_out : out std_logic_vector(15 downto 0);    -- system's data bus
   
   -- hardware interface
   sd_reset : out std_logic;
   sd_clk   : out std_logic;
   sd_mosi  : out std_logic;
   sd_miso  : in std_logic
);
end component;

-- HyperRAM
component hyperram_ctl is
port(
   -- HyperRAM needs a base clock and then one with 2x speed and one with 4x speed
   clk         : in std_logic;      -- currently 50 MHz QNICE system clock
   clk2x       : in std_logic;      -- 100 Mhz
   clk4x       : in std_logic;      -- 200 Mhz
   
   reset       : in std_logic;
   
   -- connect to CPU's data bus (data high impedance when all reg_* are 0)
   hram_en     : in std_logic;
   hram_we     : in std_logic;
   hram_reg    : in std_logic_vector(3 downto 0); 
   hram_cpu_ws : out std_logic;              -- insert CPU wait states (aka WAIT_FOR_DATA)
   data_in     : in std_logic_vector(15 downto 0);
   data_out    : out std_logic_vector(15 downto 0);
   
   -- hardware connections
   hr_d        : inout unsigned(7 downto 0); -- Data/Address
   hr_rwds     : inout std_logic;            -- RW Data strobe
   hr_reset    : out std_logic;              -- Active low RESET line to HyperRAM
   hr_clk_p    : out std_logic;
   hr2_d       : inout unsigned(7 downto 0); -- Data/Address
   hr2_rwds    : inout std_logic;            -- RW Data strobe
   hr2_reset   : out std_logic;              -- Active low RESET line to HyperRAM
   hr2_clk_p   : out std_logic;
   hr_cs0      : out std_logic;
   hr_cs1      : out std_logic
);
end component;

-- multiplexer to control the data bus (enable/disable the different parties)
component mmio_mux is
generic (
   GD_TIL            : boolean;     -- support TIL leds (e.g. as available on the Nexys 4 DDR)
   GD_SWITCHES       : boolean;     -- support SWITCHES (e.g. as available on the Nexys 4 DDR)
   GD_HRAM           : boolean      -- support HyperRAM (e.g. as available on the MEGA65)
);
port (
   -- input from hardware
   HW_RESET          : in std_logic;
   CLK               : in std_logic;

   -- input from CPU
   addr              : in std_logic_vector(15 downto 0);
   data_dir          : in std_logic;
   data_valid        : in std_logic;
   cpu_halt          : in std_logic;
   cpu_igrant_n      : in std_logic; -- if this goes to 0, then all devices need to leave the DATA bus alone,
                                     -- because the interrupt device will put the ISR address on the bus
   
   -- let the CPU wait for data from the bus
   cpu_wait_for_data : out std_logic;
   
   -- ROM is enabled when the address is < $8000 and the CPU is reading
   rom_enable        : out std_logic;
   rom_busy          : in std_logic;
   
   -- RAM is enabled when the address is in ($8000..$FEFF)
   ram_enable        : out std_logic;
   ram_busy          : in std_logic;
   
   -- PORE ROM (PowerOn & Reset Execution ROM)
   pore_rom_enable   : out std_logic;
   pore_rom_busy     : in std_logic;
   
   -- SWITCHES is $FF00
   switch_reg_enable : out std_logic;
   
   -- TIL register range: $FF01..$FF02
   til_reg0_enable   : out std_logic;
   til_reg1_enable   : out std_logic;
   
   -- Keyboard register range $FF04..$FF07
   kbd_en            : buffer std_logic;
   kbd_we            : out std_logic;
   kbd_reg           : out std_logic_vector(1 downto 0);
      
   -- Cycle counter register range $FF08..$FF0B
   cyc_en            : buffer std_logic;
   cyc_we            : out std_logic;
   cyc_reg           : out std_logic_vector(1 downto 0);

   -- Instruction counter register range $FF0C..$FF0F
   ins_en            : buffer std_logic;
   ins_we            : out std_logic;
   ins_reg           : out std_logic_vector(1 downto 0);

   -- UART register range $FF10..$FF13
   uart_en           : buffer std_logic;
   uart_we           : out std_logic;
   uart_reg          : out std_logic_vector(1 downto 0);
   uart_cpu_ws       : in std_logic;
   
   -- Extended Arithmetic Element register range $FF18..$FF1F
   eae_en            : buffer std_logic;
   eae_we            : out std_logic;
   eae_reg           : out std_logic_vector(2 downto 0);

   -- SD Card register range $FF20..FF27
   sd_en             : buffer std_logic;
   sd_we             : out std_logic;
   sd_reg            : out std_logic_vector(2 downto 0);

   -- Timer Interrupt Generator range $FF28 .. $FF2F
   tin_en            : buffer std_logic;
   tin_we            : out std_logic;
   tin_reg           : out std_logic_vector(2 downto 0);
   
   -- VGA register range $FF30..$FF3F
   vga_en            : buffer std_logic;
   vga_we            : out std_logic;
   vga_reg           : out std_logic_vector(3 downto 0);

   -- HyerRAM register range $FFF0 .. $FFF3
   hram_en           : buffer std_logic;
   hram_we           : out std_logic;
   hram_reg          : out std_logic_vector(3 downto 0); 
   hram_cpu_ws       : in std_logic; -- insert CPU wait states (aka WAIT_FOR_DATA)   
 
   -- global state and reset management
   reset_pre_pore    : out std_logic;
   reset_post_pore   : out std_logic
);
end component;

-- CPU control signals
signal cpu_addr               : std_logic_vector(15 downto 0);
signal cpu_data_in            : std_logic_vector(15 downto 0);
signal cpu_data_out           : std_logic_vector(15 downto 0);
signal cpu_data_dir           : std_logic;
signal cpu_data_valid         : std_logic;
signal cpu_wait_for_data      : std_logic;
signal cpu_halt               : std_logic;
signal cpu_ins_cnt_strobe     : std_logic;
signal cpu_int_n              : std_logic;
signal cpu_igrant_n           : std_logic;

-- MMIO control signals
signal rom_enable             : std_logic;
signal rom_busy               : std_logic;
signal rom_data_out           : std_logic_vector(15 downto 0);
signal ram_enable             : std_logic;
signal ram_busy               : std_logic;
signal ram_data_out           : std_logic_vector(15 downto 0);
signal pore_rom_enable        : std_logic;
signal pore_rom_busy          : std_logic;
signal pore_rom_data_out      : std_logic_vector(15 downto 0);
signal til_reg0_enable        : std_logic;
signal til_reg1_enable        : std_logic;
signal switch_reg_enable      : std_logic;
signal switch_data_out        : std_logic_vector(15 downto 0);
signal kbd_en                 : std_logic;
signal kbd_we                 : std_logic;
signal kbd_reg                : std_logic_vector(1 downto 0);
signal kbd_data_out           : std_logic_vector(15 downto 0);
signal tin_en                 : std_logic;
signal tin_we                 : std_logic;
signal tin_reg                : std_logic_vector(2 downto 0);
signal timer_data_out         : std_logic_vector(15 downto 0);
signal vga_en                 : std_logic;
signal vga_we                 : std_logic;
signal vga_reg                : std_logic_vector(3 downto 0);
signal vga_data_out           : std_logic_vector(15 downto 0);
signal uart_en                : std_logic;
signal uart_we                : std_logic;
signal uart_reg               : std_logic_vector(1 downto 0);
signal uart_data_out          : std_logic_vector(15 downto 0);
signal uart_cpu_ws            : std_logic;
signal cyc_en                 : std_logic;
signal cyc_we                 : std_logic;
signal cyc_reg                : std_logic_vector(1 downto 0);
signal cyc_data_out           : std_logic_vector(15 downto 0);
signal ins_en                 : std_logic;
signal ins_we                 : std_logic;
signal ins_reg                : std_logic_vector(1 downto 0);
signal ins_data_out           : std_logic_vector(15 downto 0);
signal eae_en                 : std_logic;
signal eae_we                 : std_logic;
signal eae_reg                : std_logic_vector(2 downto 0);
signal eae_data_out           : std_logic_vector(15 downto 0);
signal sd_en                  : std_logic;
signal sd_we                  : std_logic;
signal sd_reg                 : std_logic_vector(2 downto 0);
signal sd_data_out            : std_logic_vector(15 downto 0);
signal hram_en                : std_logic;
signal hram_we                : std_logic;
signal hram_reg               : std_logic_vector(3 downto 0);
signal hram_data_out          : std_logic_vector(15 downto 0);
signal hram_cpu_ws            : std_logic;   

signal reset_pre_pore         : std_logic;
signal reset_post_pore        : std_logic;

-- VGA control signals
signal vga_r                  : std_logic;
signal vga_g                  : std_logic;
signal vga_b                  : std_logic;
signal vga_hsync              : std_logic;
signal vga_vsync              : std_logic;

-- 50 MHz as long as we did not solve the timing issues of the register file
signal SLOW_CLOCK             : std_logic := '0';

-- Pixelclock and fast clock for HRAM
signal CLK1x                  : std_logic;   -- 100 MHz clock created by mmcme2 for congruent phase
signal CLK2x                  : std_logic;   -- 4x SLOW_CLOCK = 200 MHz
signal clk25MHz               : std_logic;   -- 25.175 MHz pixelclock for 640x480 @ 60 Hz
signal pll_locked_main        : std_logic;
signal clk_fb_main            : std_logic;

-- combined pre- and post pore reset
signal reset_ctl              : std_logic;

-- enable displaying of address bus on system halt, if switch 2 is on
signal i_til_reg0_enable      : std_logic;
signal i_til_data_in          : std_logic_vector(15 downto 0);

-- emulate the switches on the Nexys4 dev board to toggle VGA and PS/2
signal SWITCHES               : std_logic_vector(15 downto 0);

begin

   -- Merge data outputs from all devices into a single data input to the CPU.
   -- This requires that all devices output 0's when not selected.
   cpu_data_in <= pore_rom_data_out or
                  rom_data_out      or
                  ram_data_out      or
                  switch_data_out   or
                  kbd_data_out      or
                  vga_data_out      or
                  uart_data_out     or
                  timer_data_out    or
                  cyc_data_out      or
                  ins_data_out      or
                  eae_data_out      or
                  sd_data_out       or
                  hram_data_out;

  clk_main: mmcme2_base
  generic map
  (
    clkin1_period    => 10.0,       --   100 MHz (10 ns)
    clkfbout_mult_f  => 8.0,        --   800 MHz common multiply
    divclk_divide    => 1,          --   800 MHz /1 common divide to stay within 600MHz-1600MHz range
    clkout0_divide_f => 31.75,      --   Should be 25.175 MHz, but actual value is 25.197 MHz
    clkout1_divide   => 8,          --   100 MHz /8
    clkout2_divide   => 16,         --   50  MHz /16
    clkout3_divide   => 4          --    200 MHz /4
  )
  port map
  (
    pwrdwn   => '0',
    rst      => '0',
    clkin1   => CLK,
    clkfbin  => clk_fb_main,
    clkfbout => clk_fb_main,
    clkout0  => clk25MHz,           --  pixelclock
    clkout1  => CLK1x,              --  100 MHz
    clkout2  => SLOW_CLOCK,         --  50 MHz
    clkout3  => CLK2x,              --  200 MHz
    locked   => pll_locked_main
  );

   -- QNICE CPU
   cpu : QNICE_CPU
      port map (
         CLK => SLOW_CLOCK,
         RESET => reset_ctl,
         WAIT_FOR_DATA => cpu_wait_for_data,
         ADDR => cpu_addr,
         DATA_IN => cpu_data_in,
         DATA_OUT => cpu_data_out,
         DATA_DIR => cpu_data_dir,
         DATA_VALID => cpu_data_valid,
         HALT => cpu_halt,
         INS_CNT_STROBE => cpu_ins_cnt_strobe,
         INT_N => cpu_int_n,
         IGRANT_N => cpu_igrant_n
      );

   -- ROM: up to 64kB consisting of up to 32.000 16 bit words
   rom : BROM
      generic map (
         FILE_NAME   => ROM_FILE
      )
      port map (
         clk         => SLOW_CLOCK,
         ce          => rom_enable,
         address     => cpu_addr(14 downto 0),
         data        => rom_data_out,
         busy        => rom_busy
      );
     
   -- RAM: up to 64kB consisting of up to 32.000 16 bit words
   ram : BRAM
      port map (
         clk         => SLOW_CLOCK,
         ce          => ram_enable,
         address     => cpu_addr(14 downto 0),
         we          => cpu_data_dir,         
         data_i      => cpu_data_out,
         data_o      => ram_data_out,
         busy        => ram_busy         
      );
      
   -- PORE ROM: Power On & Reset Execution ROM
   -- contains code that is executed during power on and/or during reset
   -- MMIO is managing the PORE process
   pore_rom : BROM
      generic map (
         FILE_NAME   => PORE_ROM_FILE
      )
      port map (
         clk         => SLOW_CLOCK,
         ce          => pore_rom_enable,
         address     => cpu_addr(14 downto 0),
         data        => pore_rom_data_out,
         busy        => pore_rom_busy
      );
                 
   -- VGA: 80x40 textmode VGA adaptor
   vga_screen : vga_textmode
      port map (
         reset => reset_ctl,
         clk25MHz => clk25MHz,
         clk50MHz => SLOW_CLOCK,
         R => vga_r,
         G => vga_g,
         B => vga_b,
         hsync => vga_hsync,
         vsync => vga_vsync,
         hdmi_de => hdmi_de,
         en => vga_en,
         we => vga_we,
         reg => vga_reg,
         data_in => cpu_data_out,
         data_out => vga_data_out
      );
      
   -- I2C communication with the HDMI transcoder ADV7511
   hdmi_i2c2: hdmi_i2c
      generic map (
         clock_frequency => 50000000
      )
      port map (
         clock => SLOW_CLOCK,
         hdmi_int => '1',     
         sda => hdmi_sda,
         scl => hdmi_scl
      );

   -- special UART with FIFO that can be directly connected to the CPU bus
   uart : bus_uart
      generic map (
         DIVISOR => UART_DIVISOR
      )
      port map (
         clk => SLOW_CLOCK,
         reset => reset_ctl,
         rx => UART_RXD,
         tx => UART_TXD,
         rts => '0',
         cts => open,
         uart_en => uart_en,
         uart_we => uart_we,
         uart_reg => uart_reg,
         uart_cpu_ws => uart_cpu_ws,         
         cpu_data_in => cpu_data_out,
         cpu_data_out => uart_data_out
      );

   -- MEGA65 keyboard
   kbd : keyboard
      generic map (
         clk_freq => 50000000
      )
      port map (
         clk => SLOW_CLOCK,
         reset => reset_ctl,
         kb_io0 => kb_io0,
         kb_io1 => kb_io1,
         kb_io2 => kb_io2,
         kbd_en => kbd_en,
         kbd_we => kbd_we,
         kbd_reg => kbd_reg,
         cpu_data_in => cpu_data_out,
         cpu_data_out => kbd_data_out,
         stdinout => SWITCHES(1 downto 0)
      );

   timer_interrupt : timer_module   
      generic map (
         CLK_FREQ => 50000000
      )
      port map (
         clk => SLOW_CLOCK,
         reset => reset_ctl,
         int_n_out => cpu_int_n,
         grant_n_in => cpu_igrant_n,
         int_n_in => '1',        -- no more devices to in Daisy Chain: 1=no interrupt
         grant_n_out => open,    -- ditto: open=grant goes nowhere
         en => tin_en,
         we => tin_we,
         reg => tin_reg,
         data_in => cpu_data_out,
         data_out => timer_data_out
      );            
            
   -- cycle counter
   cyc : cycle_counter
      port map (
         clk => SLOW_CLOCK,
         impulse => '1',
         reset => reset_ctl,
         en => cyc_en,
         we => cyc_we,
         reg => cyc_reg,
         data_in => cpu_data_out,
         data_out => cyc_data_out
      );
      
   -- instruction counter
   ins : cycle_counter
      port map (
         clk => SLOW_CLOCK,
         impulse => cpu_ins_cnt_strobe,
         reset => reset_ctl,
         en => ins_en,
         we => ins_we,
         reg => ins_reg,
         data_in => cpu_data_out,
         data_out => ins_data_out
      );
      
   -- EAE - Extended Arithmetic Element (32-bit multiplication, division, modulo)
   eae_inst : eae
      port map (
         clk => SLOW_CLOCK,
         reset => reset_ctl,
         en => eae_en,
         we => eae_we,
         reg => eae_reg,
         data_in => cpu_data_out,
         data_out => eae_data_out
      );

   -- SD Card
   sd_card : sdcard
      port map (
         clk => SLOW_CLOCK,
         reset => reset_ctl,
         en => sd_en,
         we => sd_we,
         reg => sd_reg,
         data_in => cpu_data_out,
         data_out => sd_data_out,
         sd_reset => SD_RESET,
         sd_clk => SD_CLK,
         sd_mosi => SD_MOSI,
         sd_miso => SD_MISO
      );
      
   -- HyperRAM
   HRAM : hyperram_ctl
      port map (
         clk => SLOW_CLOCK,
         clk2x => CLK1x,
         clk4x => CLK2x,
         reset => reset_ctl,
         hram_en => hram_en,
         hram_we => hram_we,
         hram_reg => hram_reg,
         hram_cpu_ws => hram_cpu_ws,
         data_in => cpu_data_out,
         data_out => hram_data_out,
         hr_d => hr_d,
         hr_rwds => hr_rwds,
         hr_reset => hr_reset,
         hr_clk_p => hr_clk_p,
         hr2_d => hr2_d,
         hr2_rwds => hr2_rwds,
         hr2_reset => hr2_reset,
         hr2_clk_p => hr2_clk_p,
         hr_cs0 => hr_cs0,
         hr_cs1 => hr_cs1
      );
                        
   -- memory mapped i/o controller
   mmio_controller : mmio_mux
      generic map (
         GD_TIL => false,      -- no support for TIL leds on MEGA65
         GD_SWITCHES => true,  -- we emulate the switch register as described in doc/README.md
         GD_HRAM => true       -- support HyperRAM
      )
      port map (
         HW_RESET => not RESET_N,
         CLK => SLOW_CLOCK,                  -- @TODO change debouncer bitsize when going to 100 MHz
         addr => cpu_addr,
         data_dir => cpu_data_dir,
         data_valid => cpu_data_valid,
         cpu_wait_for_data => cpu_wait_for_data,
         cpu_halt => cpu_halt,
         cpu_igrant_n => cpu_igrant_n,         
         rom_enable => rom_enable,
         rom_busy => rom_busy,
         ram_enable => ram_enable,
         ram_busy => ram_busy,
         pore_rom_enable => pore_rom_enable,
         pore_rom_busy => pore_rom_busy,
         switch_reg_enable => switch_reg_enable,      
         kbd_en => kbd_en,
         kbd_we => kbd_we,
         kbd_reg => kbd_reg,
         tin_en => tin_en,
         tin_we => tin_we,
         tin_reg => tin_reg,         
         vga_en => vga_en,
         vga_we => vga_we,
         vga_reg => vga_reg,
         uart_en => uart_en,
         uart_we => uart_we,
         uart_reg => uart_reg,
         uart_cpu_ws => uart_cpu_ws,
         cyc_en => cyc_en,
         cyc_we => cyc_we,
         cyc_reg => cyc_reg,
         ins_en => ins_en,
         ins_we => ins_we,
         ins_reg => ins_reg,         
         eae_en => eae_en,
         eae_we => eae_we,
         eae_reg => eae_reg,
         sd_en => sd_en,
         sd_we => sd_we,
         sd_reg => sd_reg,
         hram_en => hram_en,
         hram_we => hram_we,
         hram_reg => hram_reg,
         hram_cpu_ws => hram_cpu_ws,         
         
         -- no TIL leds on the MEGA65         ,
         til_reg0_enable => open,
         til_reg1_enable => open,
         
         reset_pre_pore => reset_pre_pore,
         reset_post_pore => reset_post_pore
      );
   
   -- emulate the toggle switches as described in doc/README.md
   switch_driver : process(switch_reg_enable, SWITCHES)
   begin
      if switch_reg_enable = '1' then
         switch_data_out <= SWITCHES;
      else
         switch_data_out <= (others => '0');
      end if;
   end process;
                       
   video_signal_latches : process(clk25MHz)
   begin
      if rising_edge(clk25MHz) then
         -- VGA: wire the simplified color system of the VGA component to the VGA outputs         
         VGA_RED     <= vga_r & vga_r & vga_r & vga_r & vga_r & vga_r & vga_r & vga_r;
         VGA_GREEN   <= vga_g & vga_g & vga_g & vga_g & vga_g & vga_g & vga_g & vga_g;
         VGA_BLUE    <= vga_b & vga_b & vga_b & vga_b & vga_b & vga_b & vga_b & vga_b;
         
         -- VGA horizontal and vertical sync
         VGA_HS      <= vga_hsync;
         VGA_VS      <= vga_vsync;
         
         -- HDMI: color signal
         hdmired     <= vga_r & vga_r & vga_r & vga_r & vga_r & vga_r & vga_r & vga_r;
         hdmigreen   <= vga_g & vga_g & vga_g & vga_g & vga_g & vga_g & vga_g & vga_g;
         hdmiblue    <= vga_b & vga_b & vga_b & vga_b & vga_b & vga_b & vga_b & vga_b;
      end if;
   end process;

   -- make the VDAC output the image    
   vdac_sync_n <= '0';
   vdac_blank_n <= '1';
   
   -- Fix of the Vivado induced "blurry VGA screen":
   -- As of the  time writing this (June 2020): it is absolutely unclear for me, why I need to
   -- invert the phase of the vdac_clk when use Vivado 2019.2. When using ISE 14.7, it works
   -- fine without the phase shift.   
   vdac_clk <= not clk25MHz;

   -- HDMI   
   hdmi_hsync  <= vga_hsync;
   hdmi_vsync  <= vga_vsync;            
   hdmi_clk    <= clk25MHz;

   -- emulate the switches on the Nexys4 to toggle VGA and PS/2 keyboard
   -- bit #0: use UART as STDIN (0)  / use MEGA65 keyboard as STDIN (1)
   -- bit #1: use UART AS STDOUT (0) / use VGA as STDOUT (1)
   SWITCHES(15 downto 2) <= "00000000000000";
   
   -- generate the general reset signal
   reset_ctl <= '1' when (reset_pre_pore = '1' or reset_post_pore = '1' or pll_locked_main = '0') else '0';   
   
end beh;
