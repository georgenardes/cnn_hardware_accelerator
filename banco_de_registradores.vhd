-- cache FC
-------------------
-- IMPLEMENTADA COMO UMA MATRIZ DE REGISTRADORES
-- ESCRITA É SEQUENCIAL 
-- LEITURA PARALELA BWIDTH DE LARGURA
library ieee;
use ieee.std_logic_1164.all;
use ieee.STD_LOGIC_UNSIGNED.all;
use ieee.numeric_std.all;

library work;
use work.types_pkg.all;

-- Entity
entity banco_de_registradores is
  generic (
    BHEIGHT     : integer := 128; -- ALTURA
    BWIDTH      : integer := 35;  -- LARGURA
    WADDR_WIDTH : integer := 13;  -- NUMERO BITS ENDERECAMENTO escrita, TODOS ENDERECOS
    RADDR_WIDTH : integer := 7;   -- NUMERO BITS ENDERECAMENTO leitura
    DATA_WIDTH  : integer := 8
  );

  port (
    i_CLK : in std_logic;

    -- dado de entrada
    i_DATA : in std_logic_vector (DATA_WIDTH - 1 downto 0);

    -- habilita escrita    
    i_WRITE_ENA : in std_logic;

    -- linha de buffer selecionada
    i_WRITE_ADDR : in std_logic_vector (WADDR_WIDTH - 1 downto 0) := (others => '0');

    -- endereco a ser lido
    i_READ_ADDR : in std_logic_vector (RADDR_WIDTH - 1 downto 0) := (others => '0');

    -- dados de saida     
    o_DATA : out t_ARRAY_OF_LOGIC_VECTOR(0 to BWIDTH - 1)(7 downto 0) := (others => (others => '0'))

  );
end banco_de_registradores;

--- Arch
architecture arch of banco_de_registradores is
  -- saidas blocos  
  signal w_BLOCK_OUT : t_ARRAY_OF_LOGIC_VECTOR(0 to BWIDTH - 1)(7 downto 0) := (others => (others => '0'));

  -- write enable signals
  signal w_WRITE_ENA : std_logic_vector(BHEIGHT * BWIDTH downto 0) := (others => '0');

  -- registradore do banco de registradores da quarta camada
  signal r_REGISTERS : t_REGISTER_BANK (BWIDTH - 1 downto 0)(0 to BHEIGHT - 1)(DATA_WIDTH - 1 downto 0) := (others => (others => (others => '0')));
  signal w_ROW_ADDR  : std_logic_vector(6 downto 0)                                                     := (others => '0');
  signal w_COL_ADDR  : std_logic_vector(5 downto 0)                                                     := (others => '0');
  ------------- PARA HABILITAR REGISTRADORES ------------------
  -------------------------------
  component one_hot_encoder is
    generic (
      DATA_WIDTH : integer := 5;
      OUT_WIDTH  : integer := 18 -- quantidade de elementos enderecados   
    );
    port (
      i_DATA : in std_logic_vector(DATA_WIDTH - 1 downto 0);
      o_DATA : out std_logic_vector(OUT_WIDTH - 1 downto 0)
    );
  end component;
  -------------------------------
begin
  -- decodifica endereco de NC para habilitar escrita nos reg de deslocamento PESOS
  u_OHE_REG : one_hot_encoder
  generic map(
    DATA_WIDTH => WADDR_WIDTH, -- bits para enderecamento NC
    OUT_WIDTH  => (BHEIGHT * BWIDTH + 1)
  ) -- numero de NC
  port map(
    i_DATA => i_WRITE_ADDR,
    o_DATA => w_WRITE_ENA
  );
  w_ROW_ADDR <= i_WRITE_ADDR(6 downto 0);
  w_COL_ADDR <= i_WRITE_ADDR(13 - 1 downto 7);

  -- processo registrador
  p_REG : process (i_CLK, i_WRITE_ADDR, i_DATA, w_WRITE_ENA, i_WRITE_ENA) is
  begin

    if (rising_edge(i_CLK) and w_WRITE_ENA(to_integer(unsigned(i_WRITE_ADDR))) = '1' and i_WRITE_ENA = '1') then
      r_REGISTERS(to_integer(unsigned(w_COL_ADDR)))(to_integer(unsigned(w_ROW_ADDR))) <= i_DATA;
    end if;
  end process;
  -- blocos de memoria
  GEN_BLOCK :
  for i in 0 to BWIDTH - 1 generate
    w_BLOCK_OUT(i) <= r_REGISTERS(i)(to_integer(unsigned(i_READ_ADDR)));
  end generate GEN_BLOCK;
  -- dados de saida
  o_DATA <= w_BLOCK_OUT;
end arch;
