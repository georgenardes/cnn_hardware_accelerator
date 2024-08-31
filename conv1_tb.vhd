-- conv1 tb

library ieee;
use ieee.std_logic_1164.all;
library work;
use work.types_pkg.all;
entity conv1_tb is
end conv1_tb;

architecture arch of conv1_tb is
  component conv1 is
    generic (
      DATA_WIDTH : integer := 8;
      ADDR_WIDTH : integer := 10
    );
    port (
      i_CLK   : in std_logic;
      i_CLR   : in std_logic;
      i_GO    : in std_logic;
      i_LOAD  : in std_logic;
      o_READY : out std_logic;

      -- sinais para comunicação com rebuffers
      -- dado de entrada
      i_IN_DATA : t_CONV1_IN;
      -- habilita escrita    
      i_IN_WRITE_ENA : in std_logic;
      -- linha de buffer selecionada
      i_IN_SEL_LINE : in std_logic_vector (1 downto 0);
      -- endereco a ser escrito
      i_IN_WRITE_ADDR : in std_logic_vector (ADDR_WIDTH - 1 downto 0);
      --------------------------------------------------
      -- endereco de leitura buffer de saida
      i_OUT_READ_ADDR : in std_logic_vector (ADDR_WIDTH - 1 downto 0) := (others => '0');
      --------------------------------------------------

      -- saida dos buffers de saida
      o_OUT_DATA : out t_CONV1_OUT

    );
  end component;

  constant DATA_WIDTH   : integer := 8;
  constant ADDR_WIDTH   : integer := 10;
  constant c_CLK_PERIOD : time    := 2 ns;
  -- clock e clear
  signal w_CLK, w_CLR : std_logic;
  signal w_GO         : std_logic;
  signal w_LOAD       : std_logic;
  signal w_READY      : std_logic;

  -- sinais para comunicação com rebuffers
  -- dado de entrada
  signal w_IN_DATA : t_CONV1_IN;
  -- habilita escrita    
  signal w_IN_WRITE_ENA : std_logic;
  -- linha de buffer selecionada
  signal w_IN_SEL_LINE : std_logic_vector (1 downto 0);
  -- endereco a ser escrito
  signal w_IN_WRITE_ADDR : std_logic_vector (ADDR_WIDTH - 1 downto 0);
  --------------------------------------------------
  -- habilita leitura buffer de saida
  signal w_OUT_READ_ENA : std_logic;
  -- endereco de leitura buffer de saida
  signal w_OUT_READ_ADDR : std_logic_vector (ADDR_WIDTH - 1 downto 0) := (others => '0');
  --------------------------------------------------

  -- saida dos buffers de saida
  signal w_OUT_DATA : t_CONV1_OUT;

begin

  u_DUT : conv1
  generic map(
    DATA_WIDTH => DATA_WIDTH,
    ADDR_WIDTH => ADDR_WIDTH
  )
  port map(
    i_CLK           => w_CLK,
    i_CLR           => w_CLR,
    i_GO            => w_GO,
    i_LOAD          => w_LOAD,
    o_READY         => w_READY,
    i_IN_DATA       => w_IN_DATA,
    i_IN_WRITE_ENA  => w_IN_WRITE_ENA,
    i_IN_SEL_LINE   => w_IN_SEL_LINE,
    i_IN_WRITE_ADDR => w_IN_WRITE_ADDR,
    i_OUT_READ_ADDR => w_OUT_READ_ADDR,
    o_OUT_DATA      => w_OUT_DATA
  );

  ---------------------
  p_CLK : process
  begin
    w_CLK <= '1';
    wait for c_CLK_PERIOD/2;
    w_CLK <= '0';
    wait for c_CLK_PERIOD/2;
  end process p_CLK;
  ---------------------

  p_TEST : process
  begin
    --------------------------
    w_CLR <= '1'; -- clear 
    wait for 2 * c_CLK_PERIOD;
    w_CLR <= '0'; -- clear 
    ---------------------------

    w_GO   <= '0';
    w_LOAD <= '1';
    wait for c_CLK_PERIOD;
    w_LOAD <= '0';

    wait for 750 * c_CLK_PERIOD;

    -- espera um ciclo de clock				
    w_GO <= '1';
    wait for c_CLK_PERIOD;
    w_GO <= '0';
    wait for 5500 * c_CLK_PERIOD;

    -- TEST DONE
    assert false report "Test done." severity note;
    wait;

  end process p_TEST;
end arch;
