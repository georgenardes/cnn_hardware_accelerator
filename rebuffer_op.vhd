-- operacional rebuffer
-------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.STD_LOGIC_UNSIGNED.all;

-- Entity
entity rebuffer_op is
  generic (
    DATA_WIDTH : integer := 8
  );
  port (
    i_CLK : in std_logic;
    i_CLR : in std_logic;

    -- dado de entrada
    i_DATA : in std_logic_vector (DATA_WIDTH - 1 downto 0);
    -- sinalia borda
    i_PAD : in std_logic := '0';
    -- habilita registrador de dados
    i_REG_ENA : in std_logic;
    -- reseta registrador de dados
    i_REG_RST : in std_logic;
    -- dado de saida (mesmo q o de entrada)
    o_DATA : out std_logic_vector (DATA_WIDTH - 1 downto 0)
  );
end rebuffer_op;

--- Arch
architecture arch of rebuffer_op is
  -- dado de entrada
  signal r_DATA : std_logic_vector (DATA_WIDTH - 1 downto 0);
  signal w_DATA : std_logic_vector (DATA_WIDTH - 1 downto 0);
begin
  -- borda 0 
  w_DATA <= (others => '0') when (i_PAD = '1') else
    i_DATA;

  -- registra dado de entrada
  r_DATA <= (others => '0')
    when (i_REG_RST = '1' or i_CLR = '1') else
    w_DATA
    when (rising_edge(i_CLK) and i_REG_ENA = '1') else
    r_DATA;
  -- dado de saida
  o_DATA <= r_DATA;
end arch;
