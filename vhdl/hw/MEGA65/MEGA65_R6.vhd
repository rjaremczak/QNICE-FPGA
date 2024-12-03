----------------------------------------------------------------------------------
-- MEGA65 port of QNICE-FGA
--
-- Top Module for synthesizing the whole machine
--
-- done on-again-off-again in 2015, 2016 by sy2002
-- MEGA65 port done in April to August 2020 by sy2002
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

use work.env1_globals.all;

entity MEGA65 is
  port (
    clk_i          : in std_logic; -- Onboard crystal oscillator = 100 MHz
    reset_button_i : in std_logic; -- Reset button on the side of the machine, active high

    -- USB-RS232 Interface
    uart_rxd_i : in std_logic;
    uart_txd_o : out std_logic;

    -- VGA via VDAC. U3 = ADV7125BCPZ170
    vga_red_o      : out std_logic_vector(7 downto 0);
    vga_green_o    : out std_logic_vector(7 downto 0);
    vga_blue_o     : out std_logic_vector(7 downto 0);
    vga_hs_o       : out std_logic;
    vga_vs_o       : out std_logic;
    vga_scl_io     : inout std_logic;
    vga_sda_io     : inout std_logic;
    vdac_clk_o     : out std_logic;
    vdac_sync_n_o  : out std_logic;
    vdac_blank_n_o : out std_logic;
    vdac_psave_n_o : out std_logic;

    -- HDMI. U10 = PTN3363BSMP
    -- I2C address 0x40

    tmds_data_p_o  : out std_logic_vector(2 downto 0);
    tmds_data_n_o  : out std_logic_vector(2 downto 0);
    tmds_clk_p_o   : out std_logic;
    tmds_clk_n_o   : out std_logic;
    hdmi_hiz_en_o  : out std_logic; -- Connect to U10.HIZ_EN
    hdmi_ls_oe_n_o : out std_logic; -- Connect to U10.OE#
    hdmi_hpd_i     : in std_logic; -- Connect to U10.HPD_SOURCE
    hdmi_scl_io    : inout std_logic; -- Connect to U10.SCL_SOURCE
    hdmi_sda_io    : inout std_logic; -- Connect to U10.SDA_SOURCE

    -- MEGA65 smart keyboard controller
    kb_io0_o    : out std_logic; -- clock to keyboard
    kb_io1_o    : out std_logic; -- data output to keyboard
    kb_io2_i    : in std_logic; -- data input from keyboard
    kb_tck_o    : out std_logic;
    kb_tdo_i    : in std_logic;
    kb_tms_o    : out std_logic;
    kb_tdi_o    : out std_logic;
    kb_jtagen_o : out std_logic;

    -- SD Card
    SD_RESET : out std_logic;
    SD_CLK   : out std_logic;
    SD_MOSI  : out std_logic;
    SD_MISO  : in std_logic;
    sd_cd_i  : in std_logic;
    sd_d1_i  : in std_logic;
    sd_d2_i  : in std_logic;

    -- SD Connector (this is the slot at the bottom side of the case under the cover)
    sd2_reset_o : out std_logic;
    sd2_clk_o   : out std_logic;
    sd2_mosi_o  : out std_logic;
    sd2_miso_i  : in std_logic;
    sd2_cd_i    : in std_logic;
    sd2_wp_i    : in std_logic;
    sd2_d1_i    : in std_logic;
    sd2_d2_i    : in std_logic;

    -- Audio DAC. U37 = AK4432VT
    -- I2C address 0x19
    audio_mclk_o   : out std_logic; -- Master Clock Input Pin,       12.288 MHz
    audio_bick_o   : out std_logic; -- Audio Serial Data Clock Pin,   3.072 MHz
    audio_sdti_o   : out std_logic; -- Audio Serial Data Input Pin,  16-bit LSB justified
    audio_lrclk_o  : out std_logic; -- Input Channel Clock Pin,      48.0 kHz
    audio_pdn_n_o  : out std_logic; -- Power-Down & Reset Pin
    audio_i2cfil_o : out std_logic; -- I2C Interface Mode Select Pin
    audio_scl_io   : inout std_logic; -- Control Data Clock Input Pin
    audio_sda_io   : inout std_logic; -- Control Data Input/Output Pin

    -- Joysticks and Paddles
    fa_up_n_i    : in std_logic;
    fa_down_n_i  : in std_logic;
    fa_left_n_i  : in std_logic;
    fa_right_n_i : in std_logic;
    fa_fire_n_i  : in std_logic;
    fa_fire_n_o  : out std_logic; -- 0: Drive pin low (output). 1: Leave pin floating (input)
    fa_up_n_o    : out std_logic;
    fa_left_n_o  : out std_logic;
    fa_down_n_o  : out std_logic;
    fa_right_n_o : out std_logic;
    fb_up_n_i    : in std_logic;
    fb_down_n_i  : in std_logic;
    fb_left_n_i  : in std_logic;
    fb_right_n_i : in std_logic;
    fb_fire_n_i  : in std_logic;
    fb_up_n_o    : out std_logic;
    fb_down_n_o  : out std_logic;
    fb_fire_n_o  : out std_logic;
    fb_right_n_o : out std_logic;
    fb_left_n_o  : out std_logic;

    -- Joystick power supply
    joystick_5v_disable_o   : out std_logic; -- 1: Disable 5V power supply to joysticks
    joystick_5v_powergood_i : in std_logic;

    paddle_i       : in std_logic_vector(3 downto 0);
    paddle_drain_o : out std_logic;

    -- HyperRAM. U29 = IS66WVH8M8DBLL-100B1LI
    hr_d_io    : inout unsigned(7 downto 0); -- Data/Address
    hr_rwds_io : inout std_logic; -- RW Data strobe
    hr_reset_o : out std_logic; -- Active low RESET line to HyperRAM
    hr_clk_p_o : out std_logic;
    hr_cs0_o   : out std_logic;

    -- I2C bus
    -- U32 = PCA9655EMTTXG. Address 0x40. I/O expander.
    -- U12 = MP8869SGL-Z.   Address 0x61. DC/DC Converter.
    -- U14 = MP8869SGL-Z.   Address 0x67. DC/DC Converter.
    i2c_scl_io : inout std_logic;
    i2c_sda_io : inout std_logic;

    -- CBM-488/IEC serial port
    iec_reset_n_o   : out std_logic;
    iec_atn_n_o     : out std_logic;
    iec_clk_en_n_o  : out std_logic;
    iec_clk_n_i     : in std_logic;
    iec_clk_n_o     : out std_logic;
    iec_data_en_n_o : out std_logic;
    iec_data_n_i    : in std_logic;
    iec_data_n_o    : out std_logic;
    iec_srq_en_n_o  : out std_logic;
    iec_srq_n_i     : in std_logic;
    iec_srq_n_o     : out std_logic;

    -- C64 Expansion Port (aka Cartridge Port)
    cart_phi2_o       : out std_logic;
    cart_dotclock_o   : out std_logic;
    cart_dma_i        : in std_logic;
    cart_reset_oe_n_o : out std_logic;
    cart_reset_io     : inout std_logic;
    cart_game_oe_n_o  : out std_logic;
    cart_game_io      : inout std_logic;
    cart_exrom_oe_n_o : out std_logic;
    cart_exrom_io     : inout std_logic;
    cart_nmi_oe_n_o   : out std_logic;
    cart_nmi_io       : inout std_logic;
    cart_irq_oe_n_o   : out std_logic;
    cart_irq_io       : inout std_logic;
    cart_ctrl_en_o    : out std_logic;
    cart_ctrl_dir_o   : out std_logic; -- =1 means FPGA->Port, =0 means Port->FPGA
    cart_ba_io        : inout std_logic;
    cart_rw_io        : inout std_logic;
    cart_io1_io       : inout std_logic;
    cart_io2_io       : inout std_logic;
    cart_romh_oe_n_o  : out std_logic;
    cart_romh_io      : inout std_logic;
    cart_roml_oe_n_o  : out std_logic;
    cart_roml_io      : inout std_logic;
    cart_en_o         : out std_logic;
    cart_addr_en_o    : out std_logic;
    cart_haddr_dir_o  : out std_logic; -- =1 means FPGA->Port, =0 means Port->FPGA
    cart_laddr_dir_o  : out std_logic; -- =1 means FPGA->Port, =0 means Port->FPGA
    cart_a_io         : inout unsigned(15 downto 0);
    cart_data_en_o    : out std_logic;
    cart_data_dir_o   : out std_logic; -- =1 means FPGA->Port, =0 means Port->FPGA
    cart_d_io         : inout unsigned(7 downto 0);

    -- I2C bus for on-board peripherals
    -- U36. 24AA025E48T. Address 0x50. 2K Serial EEPROM.
    -- U38. RV-3032-C7.  Address 0x51. Real-Time Clock Module.
    -- U39. 24LC128.     Address 0x56. 128K CMOS Serial EEPROM.
    fpga_sda_io : inout std_logic;
    fpga_scl_io : inout std_logic;

    -- Connected to J18
    grove_sda_io : inout std_logic;
    grove_scl_io : inout std_logic;

    -- On board LEDs
    led_g_n_o : out std_logic;
    led_r_n_o : out std_logic;
    led_o     : out std_logic;

    -- SDRAM - 32M x 16 bit, 3.3V VCC. U44 = IS42S16320F-6BL
    sdram_clk_o   : out std_logic;
    sdram_cke_o   : out std_logic;
    sdram_ras_n_o : out std_logic;
    sdram_cas_n_o : out std_logic;
    sdram_we_n_o  : out std_logic;
    sdram_cs_n_o  : out std_logic;
    sdram_ba_o    : out std_logic_vector(1 downto 0);
    sdram_a_o     : out std_logic_vector(12 downto 0);
    sdram_dqml_o  : out std_logic;
    sdram_dqmh_o  : out std_logic;
    sdram_dq_io   : inout std_logic_vector(15 downto 0)
  );
end entity MEGA65;

architecture beh of MEGA65 is

  -- CPU control signals
  signal cpu_addr           : std_logic_vector(15 downto 0);
  signal cpu_data_in        : std_logic_vector(15 downto 0);
  signal cpu_data_out       : std_logic_vector(15 downto 0);
  signal cpu_data_dir       : std_logic;
  signal cpu_data_valid     : std_logic;
  signal cpu_wait_for_data  : std_logic;
  signal cpu_halt           : std_logic;
  signal cpu_ins_cnt_strobe : std_logic;
  signal cpu_int_n          : std_logic;
  signal cpu_igrant_n       : std_logic;

  -- MMIO control signals
  signal rom_enable        : std_logic;
  signal rom_busy          : std_logic;
  signal rom_data_out      : std_logic_vector(15 downto 0);
  signal ram_enable        : std_logic;
  signal ram_busy          : std_logic;
  signal ram_data_out      : std_logic_vector(15 downto 0);
  signal pore_rom_enable   : std_logic;
  signal pore_rom_busy     : std_logic;
  signal pore_rom_data_out : std_logic_vector(15 downto 0);
  signal til_reg0_enable   : std_logic;
  signal til_reg1_enable   : std_logic;
  signal switch_reg_enable : std_logic;
  signal switch_data_out   : std_logic_vector(15 downto 0);
  signal kbd_en            : std_logic;
  signal kbd_we            : std_logic;
  signal kbd_reg           : std_logic_vector(1 downto 0);
  signal kbd_data_out      : std_logic_vector(15 downto 0);
  signal tin_en            : std_logic;
  signal tin_we            : std_logic;
  signal tin_reg           : std_logic_vector(2 downto 0);
  signal timer_data_out    : std_logic_vector(15 downto 0);
  signal vga_en            : std_logic;
  signal vga_we            : std_logic;
  signal vga_reg           : std_logic_vector(3 downto 0);
  signal vga_data_out      : std_logic_vector(15 downto 0);
  signal uart_en           : std_logic;
  signal uart_we           : std_logic;
  signal uart_reg          : std_logic_vector(1 downto 0);
  signal uart_data_out     : std_logic_vector(15 downto 0);
  signal uart_cpu_ws       : std_logic;
  signal cyc_en            : std_logic;
  signal cyc_we            : std_logic;
  signal cyc_reg           : std_logic_vector(1 downto 0);
  signal cyc_data_out      : std_logic_vector(15 downto 0);
  signal ins_en            : std_logic;
  signal ins_we            : std_logic;
  signal ins_reg           : std_logic_vector(1 downto 0);
  signal ins_data_out      : std_logic_vector(15 downto 0);
  signal eae_en            : std_logic;
  signal eae_we            : std_logic;
  signal eae_reg           : std_logic_vector(2 downto 0);
  signal eae_data_out      : std_logic_vector(15 downto 0);
  signal sd_en             : std_logic;
  signal sd_we             : std_logic;
  signal sd_reg            : std_logic_vector(2 downto 0);
  signal sd_data_out       : std_logic_vector(15 downto 0);
  signal hram_en           : std_logic;
  signal hram_we           : std_logic;
  signal hram_reg          : std_logic_vector(3 downto 0);
  signal hram_data_out     : std_logic_vector(15 downto 0);
  signal hram_cpu_ws       : std_logic;

  signal reset_pre_pore  : std_logic;
  signal reset_post_pore : std_logic;

  -- VGA control signals
  signal vga_r     : std_logic;
  signal vga_g     : std_logic;
  signal vga_b     : std_logic;
  signal vga_hsync : std_logic;
  signal vga_vsync : std_logic;

  -- 50 MHz as long as we did not solve the timing issues of the register file
  signal SLOW_CLOCK : std_logic := '0';

  -- Pixelclock and fast clock for HRAM
  signal CLK1x           : std_logic; -- 100 MHz clock created by mmcme2 for congruent phase
  signal CLK2x           : std_logic; -- 4x SLOW_CLOCK = 200 MHz
  signal clk25MHz        : std_logic; -- 25.175 MHz pixelclock for 640x480 @ 60 Hz
  signal pll_locked_main : std_logic;
  signal clk_fb_main     : std_logic;

  -- combined pre- and post pore reset
  signal reset_ctl : std_logic;

  -- enable displaying of address bus on system halt, if switch 2 is on
  signal i_til_reg0_enable : std_logic;
  signal i_til_data_in     : std_logic_vector(15 downto 0);

  -- emulate the switches on the Nexys4 dev board to toggle VGA and PS/2
  signal SWITCHES : std_logic_vector(15 downto 0);

begin

  -- Merge data outputs from all devices into a single data input to the CPU.
  -- This requires that all devices output 0's when not selected.
  cpu_data_in <= pore_rom_data_out or
    rom_data_out or
    ram_data_out or
    switch_data_out or
    kbd_data_out or
    vga_data_out or
    uart_data_out or
    timer_data_out or
    cyc_data_out or
    ins_data_out or
    eae_data_out or
    sd_data_out or
    hram_data_out;

  -- Due to a bug in the R5/R6 boards, the cartridge port needs to be enabled for joystick port 2 to work 
  cart_en_o <= '1';
 
  -- dummy HDMI differential output 

  hdmi_hiz_en_o  <= 'L';
  hdmi_ls_oe_n_o <= 'H';
  hdmi_scl_io    <= 'Z';
  hdmi_sda_io    <= 'Z';
  
  tmds_data_obufds : for i in 0 to 2 generate
  begin
    tmds_data_obufds_bit : obufds
      port map (
        i   => 'L',
        o   => tmds_data_p_o(i),
        ob  => tmds_data_n_o(i)
      );
  end generate tmds_data_obufds;

  tmds_clk_obufds : obufds
    port map (
      i   => 'L',
      o   => tmds_clk_p_o,
      ob  => tmds_clk_n_o
    );

  clk_main : mmcme2_base
  generic map
  (
    clkin1_period    => 10.0, --   100 MHz (10 ns)
    clkfbout_mult_f  => 8.0, --   800 MHz common multiply
    divclk_divide    => 1, --   800 MHz /1 common divide to stay within 600MHz-1600MHz range
    clkout0_divide_f => 31.75, --   Should be 25.175 MHz, but actual value is 25.197 MHz
    clkout1_divide   => 8, --   100 MHz /8
    clkout2_divide   => 16, --   50  MHz /16
    clkout3_divide   => 4 --    200 MHz /4
  )
  port map
  (
    pwrdwn   => '0',
    rst      => '0',
    clkin1   => clk_i,
    clkfbin  => clk_fb_main,
    clkfbout => clk_fb_main,
    clkout0  => clk25MHz, --  pixelclock
    clkout1  => CLK1x, --  100 MHz
    clkout2  => SLOW_CLOCK, --  50 MHz
    clkout3  => CLK2x, --  200 MHz
    locked   => pll_locked_main
  );

  -- QNICE CPU
  cpu : entity work.QNICE_CPU
    port map
    (
      CLK            => SLOW_CLOCK,
      RESET          => reset_ctl,
      WAIT_FOR_DATA  => cpu_wait_for_data,
      ADDR           => cpu_addr,
      DATA_IN        => cpu_data_in,
      DATA_OUT       => cpu_data_out,
      DATA_DIR       => cpu_data_dir,
      DATA_VALID     => cpu_data_valid,
      HALT           => cpu_halt,
      INS_CNT_STROBE => cpu_ins_cnt_strobe,
      INT_N          => cpu_int_n,
      IGRANT_N       => cpu_igrant_n
    );

  -- ROM: up to 64kB consisting of up to 32.000 16 bit words
  rom : entity work.BROM
    generic map(
      FILE_NAME => ROM_FILE
    )
    port map
    (
      clk     => SLOW_CLOCK,
      ce      => rom_enable,
      address => cpu_addr(14 downto 0),
      data    => rom_data_out,
      busy    => rom_busy
    );

  -- RAM: up to 64kB consisting of up to 32.000 16 bit words
  ram : entity work.BRAM
    port map
    (
      clk     => SLOW_CLOCK,
      ce      => ram_enable,
      address => cpu_addr(14 downto 0),
      we      => cpu_data_dir,
      data_i  => cpu_data_out,
      data_o  => ram_data_out,
      busy    => ram_busy
    );

  -- PORE ROM: Power On & Reset Execution ROM
  -- contains code that is executed during power on and/or during reset
  -- MMIO is managing the PORE process
  pore_rom : entity work.BROM
    generic map(
      FILE_NAME => PORE_ROM_FILE
    )
    port map
    (
      clk     => SLOW_CLOCK,
      ce      => pore_rom_enable,
      address => cpu_addr(14 downto 0),
      data    => pore_rom_data_out,
      busy    => pore_rom_busy
    );

  -- VGA: 80x40 textmode VGA adaptor
  vga_screen : entity work.vga_textmode
    port map
    (
      reset    => reset_ctl,
      clk25MHz => clk25MHz,
      clk50MHz => SLOW_CLOCK,
      R        => vga_r,
      G        => vga_g,
      B        => vga_b,
      hsync    => vga_hsync,
      vsync    => vga_vsync,
      hdmi_de  => open,
      en       => vga_en,
      we       => vga_we,
      reg      => vga_reg,
      data_in  => cpu_data_out,
      data_out => vga_data_out
    );

  -- special UART with FIFO that can be directly connected to the CPU bus
  uart : entity work.bus_uart
    generic map(
      DIVISOR => UART_DIVISOR
    )
    port map
    (
      clk          => SLOW_CLOCK,
      reset        => reset_ctl,
      rx           => uart_rxd_i,
      tx           => uart_txd_o,
      rts          => '0',
      cts          => open,
      uart_en      => uart_en,
      uart_we      => uart_we,
      uart_reg     => uart_reg,
      uart_cpu_ws  => uart_cpu_ws,
      cpu_data_in  => cpu_data_out,
      cpu_data_out => uart_data_out
    );

  -- MEGA65 keyboard
  kbd : entity work.keyboard
    generic map(
      clk_freq => 50000000
    )
    port map
    (
      clk          => SLOW_CLOCK,
      reset        => reset_ctl,
      kb_io0       => kb_io0_o,
      kb_io1       => kb_io1_o,
      kb_io2       => kb_io2_i,
      kbd_en       => kbd_en,
      kbd_we       => kbd_we,
      kbd_reg      => kbd_reg,
      cpu_data_in  => cpu_data_out,
      cpu_data_out => kbd_data_out,
      stdinout     => SWITCHES(1 downto 0)
    );

  timer_interrupt : entity work.timer_module
    generic map(
      CLK_FREQ => 50000000
    )
    port map
    (
      clk         => SLOW_CLOCK,
      reset       => reset_ctl,
      int_n_out   => cpu_int_n,
      grant_n_in  => cpu_igrant_n,
      int_n_in    => '1', -- no more devices to in Daisy Chain: 1=no interrupt
      grant_n_out => open, -- ditto: open=grant goes nowhere
      en          => tin_en,
      we          => tin_we,
      reg         => tin_reg,
      data_in     => cpu_data_out,
      data_out    => timer_data_out
    );

  -- cycle counter
  cyc : entity work.cycle_counter
    port map
    (
      clk      => SLOW_CLOCK,
      impulse  => '1',
      reset    => reset_ctl,
      en       => cyc_en,
      we       => cyc_we,
      reg      => cyc_reg,
      data_in  => cpu_data_out,
      data_out => cyc_data_out
    );

  -- instruction counter
  ins : entity work.cycle_counter
    port map
    (
      clk      => SLOW_CLOCK,
      impulse  => cpu_ins_cnt_strobe,
      reset    => reset_ctl,
      en       => ins_en,
      we       => ins_we,
      reg      => ins_reg,
      data_in  => cpu_data_out,
      data_out => ins_data_out
    );

  -- EAE - Extended Arithmetic Element (32-bit multiplication, division, modulo)
  eae_inst : entity work.eae
    port map
    (
      clk      => SLOW_CLOCK,
      reset    => reset_ctl,
      en       => eae_en,
      we       => eae_we,
      reg      => eae_reg,
      data_in  => cpu_data_out,
      data_out => eae_data_out
    );

  -- SD Card
  sd_card : entity work.sdcard
    port map
    (
      clk      => SLOW_CLOCK,
      reset    => reset_ctl,
      en       => sd_en,
      we       => sd_we,
      reg      => sd_reg,
      data_in  => cpu_data_out,
      data_out => sd_data_out,
      sd_reset => SD_RESET,
      sd_clk   => SD_CLK,
      sd_mosi  => SD_MOSI,
      sd_miso  => SD_MISO
    );

  -- HyperRAM
  HRAM : entity work.hyperram_ctl
    port map
    (
      clk         => SLOW_CLOCK,
      clk2x       => CLK1x,
      clk4x       => CLK2x,
      reset       => reset_ctl,
      hram_en     => hram_en,
      hram_we     => hram_we,
      hram_reg    => hram_reg,
      hram_cpu_ws => hram_cpu_ws,
      data_in     => cpu_data_out,
      data_out    => hram_data_out,
      hr_d        => hr_d_io,
      hr_rwds     => hr_rwds_io,
      hr_reset    => hr_reset_o,
      hr_clk_p    => hr_clk_p_o,
      hr_cs0      => hr_cs0_o
    );

  -- memory mapped i/o controller
  mmio_controller : entity work.mmio_mux
    generic map(
      GD_TIL      => false, -- no support for TIL leds on MEGA65
      GD_SWITCHES => true, -- we emulate the switch register as described in doc/README.md
      GD_HRAM     => true -- support HyperRAM
    )
    port map
    (
      HW_RESET          => reset_button_i,
      CLK               => SLOW_CLOCK, -- @TODO change debouncer bitsize when going to 100 MHz
      addr              => cpu_addr,
      data_dir          => cpu_data_dir,
      data_valid        => cpu_data_valid,
      cpu_wait_for_data => cpu_wait_for_data,
      cpu_halt          => cpu_halt,
      cpu_igrant_n      => cpu_igrant_n,
      rom_enable        => rom_enable,
      rom_busy          => rom_busy,
      ram_enable        => ram_enable,
      ram_busy          => ram_busy,
      pore_rom_enable   => pore_rom_enable,
      pore_rom_busy     => pore_rom_busy,
      switch_reg_enable => switch_reg_enable,
      kbd_en            => kbd_en,
      kbd_we            => kbd_we,
      kbd_reg           => kbd_reg,
      tin_en            => tin_en,
      tin_we            => tin_we,
      tin_reg           => tin_reg,
      vga_en            => vga_en,
      vga_we            => vga_we,
      vga_reg           => vga_reg,
      uart_en           => uart_en,
      uart_we           => uart_we,
      uart_reg          => uart_reg,
      uart_cpu_ws       => uart_cpu_ws,
      cyc_en            => cyc_en,
      cyc_we            => cyc_we,
      cyc_reg           => cyc_reg,
      ins_en            => ins_en,
      ins_we            => ins_we,
      ins_reg           => ins_reg,
      eae_en            => eae_en,
      eae_we            => eae_we,
      eae_reg           => eae_reg,
      sd_en             => sd_en,
      sd_we             => sd_we,
      sd_reg            => sd_reg,
      hram_en           => hram_en,
      hram_we           => hram_we,
      hram_reg          => hram_reg,
      hram_cpu_ws       => hram_cpu_ws,

      -- no TIL leds on the MEGA65         ,
      til_reg0_enable => open,
      til_reg1_enable => open,

      reset_pre_pore  => reset_pre_pore,
      reset_post_pore => reset_post_pore
    );

  -- emulate the toggle switches as described in doc/README.md
  switch_driver : process (switch_reg_enable, SWITCHES)
  begin
    if switch_reg_enable = '1' then
      switch_data_out <= SWITCHES;
    else
      switch_data_out <= (others => '0');
    end if;
  end process;

  video_signal_latches : process (clk25MHz)
  begin
    if rising_edge(clk25MHz) then
      -- VGA: wire the simplified color system of the VGA component to the VGA outputs
      vga_red_o   <= vga_r & vga_r & vga_r & vga_r & vga_r & vga_r & vga_r & vga_r;
      vga_green_o <= vga_g & vga_g & vga_g & vga_g & vga_g & vga_g & vga_g & vga_g;
      vga_blue_o  <= vga_b & vga_b & vga_b & vga_b & vga_b & vga_b & vga_b & vga_b;

      -- VGA horizontal and vertical sync
      vga_hs_o <= vga_hsync;
      vga_vs_o <= vga_vsync;
    end if;
  end process;

  -- make the VDAC output the image
  vdac_sync_n_o  <= '0';
  vdac_blank_n_o <= '1';

  -- Fix of the Vivado induced "blurry VGA screen":
  -- As of the  time writing this (June 2020): it is absolutely unclear for me, why I need to
  -- invert the phase of the vdac_clk when use Vivado 2019.2. When using ISE 14.7, it works
  -- fine without the phase shift.
  vdac_clk_o <= not clk25MHz;

  -- emulate the switches on the Nexys4 to toggle VGA and PS/2 keyboard
  -- bit #0: use UART as STDIN (0)  / use MEGA65 keyboard as STDIN (1)
  -- bit #1: use UART AS STDOUT (0) / use VGA as STDOUT (1)
  SWITCHES(15 downto 2) <= "00000000000000";

  -- generate the general reset signal
  reset_ctl <= '1' when (reset_pre_pore = '1' or reset_post_pore = '1' or pll_locked_main = '0') else
    '0';

end architecture beh;