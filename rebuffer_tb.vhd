-- rebuffer testbench

library ieee;
use ieee.std_logic_1164.all;
use ieee.STD_LOGIC_UNSIGNED.all;

-- Entity
entity rebuffer_tb is
end rebuffer_tb;

--- Arch
architecture arch of rebuffer_tb is

  -- component
  component rebuffer is
    generic (
      ADDR_WIDTH     : integer                      := 8;
      DATA_WIDTH     : integer                      := 8;
      REBUFF_TYPE    : integer                      := 0;
      NUM_BUFF       : std_logic_vector(1 downto 0) := "11";        -- 3 buffers
      FMAP_WIDTH     : std_logic_vector(5 downto 0) := "001000";    -- 8
      INPUT_MAX_ADDR : std_logic_vector(9 downto 0) := "0000100000" -- FMAP_WIDTH*#linhas
    );
    port (
      i_CLK : in std_logic;
      i_CLR : in std_logic;
      i_GO  : in std_logic;

      -- dado de entrada
      i_DATA : in std_logic_vector (DATA_WIDTH - 1 downto 0);
      -- habilita leitura
      o_READ_ENA : out std_logic;
      -- endereco a ser lido
      o_IN_ADDR : out std_logic_vector (ADDR_WIDTH - 1 downto 0);
      -- endereco a ser escrito
      o_OUT_ADDR : out std_logic_vector (ADDR_WIDTH - 1 downto 0);
      -- habilita escrita    
      o_WRITE_ENA : out std_logic;
      -- dado de saida (mesmo q o de entrada)
      o_DATA : out std_logic_vector (DATA_WIDTH - 1 downto 0);
      -- linha de buffer selecionada
      o_SEL_BUFF : out std_logic_vector (1 downto 0);
      o_READY    : out std_logic
    );
  end component;

  -- clock
  constant c_CLK_PERIOD : time := 2 ns;

  -- LARGURA DOS DADOS
  constant c_ADDR_WIDTH     : integer                      := 8;
  constant c_DATA_WIDTH     : integer                      := 8;
  constant c_REBUFF_TYPE    : integer                      := 0;
  constant c_NUM_BUFF       : std_logic_vector(1 downto 0) := "11";         -- 3 buffers
  constant c_FMAP_WIDTH     : std_logic_vector(5 downto 0) := "001000";     -- 8
  constant c_INPUT_MAX_ADDR : std_logic_vector(9 downto 0) := "0000100000"; -- 8
  -- sinais 
  signal w_i_CLK : std_logic;
  signal w_i_CLR : std_logic;

  signal w_i_GO, w_o_READY : std_logic;

  -- dados
  signal w_i_DATA, w_o_DATA : std_logic_vector (c_DATA_WIDTH - 1 downto 0);

  -- habilitacao
  signal w_o_READ_ENA, w_o_WRITE_ENA : std_logic;

  -- endereco a ser lido
  signal w_o_IN_ADDR : std_logic_vector (c_ADDR_WIDTH - 1 downto 0);

  -- endereco a ser escrito
  signal w_o_OUT_ADDR : std_logic_vector (c_ADDR_WIDTH - 1 downto 0);

  -- linha de buffer selecionada
  signal w_o_SEL_BUFF : std_logic_vector (1 downto 0);

begin

  u_DUT : rebuffer
  generic map(
    c_ADDR_WIDTH,
    c_DATA_WIDTH,
    c_REBUFF_TYPE,
    c_NUM_BUFF,
    c_FMAP_WIDTH,
    c_INPUT_MAX_ADDR
  )
  port map(
    i_CLK       => w_i_CLK,
    i_CLR       => w_i_CLR,
    i_GO        => w_i_GO,
    i_DATA      => w_i_DATA,
    o_READ_ENA  => w_o_READ_ENA,
    o_IN_ADDR   => w_o_IN_ADDR,
    o_OUT_ADDR  => w_o_OUT_ADDR,
    o_WRITE_ENA => w_o_WRITE_ENA,
    o_DATA      => w_o_DATA,
    o_SEL_BUFF  => w_o_SEL_BUFF,
    o_READY     => w_o_READY
  );
  ---------------------
  p_CLK : process
  begin
    w_i_CLK <= '1';
    wait for c_CLK_PERIOD/2;
    w_i_CLK <= '0';
    wait for c_CLK_PERIOD/2;
  end process p_CLK;
  ---------------------

  p_TEST : process
  begin
    w_i_CLR  <= '0';
    w_i_GO   <= '0';
    w_i_DATA <= "00000000";
    wait for c_CLK_PERIOD;
    --------------------------
    w_i_CLR <= '1'; -- clear 
    wait for c_CLK_PERIOD;
    w_i_CLR <= '0'; -- clear 
    wait for c_CLK_PERIOD;
    ---------------------------

    w_i_GO <= '1';
    wait for c_CLK_PERIOD;
    w_i_GO <= '0';
    wait for 100 * c_CLK_PERIOD;

    ---------------------------
    -- TEST DONE
    assert false report "Test done." severity note;
    wait;

  end process p_TEST;

end arch;
