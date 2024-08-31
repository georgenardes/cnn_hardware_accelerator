-------------------
-- Buffer de entrada/saida
-- 05/10/2021
-- George
-- R1

-- Descrição
-- Este componente empacota blocos de memória ram/rom
-- com adicão de sinais de controle.
-- A escrita é feita pelos blocos rebuffer, e deve
-- ser realizada sequencialmente, em um bloco por vez.
-- A leitura é feita pelos blocos operacionais (conv e pool)
-- e deve ser realizada paralelamente.
-------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.STD_LOGIC_UNSIGNED.all;
use ieee.numeric_std.all;

library work;
use work.types_pkg.all;

-- Entity
entity io_buffer is
  generic (
    NUM_BLOCKS   : integer := 3;
    DATA_WIDTH   : integer := 8;
    ADDR_WIDTH   : integer := 10; -- 2**10  enderecos
    USE_REGISTER : integer := 0
  );

  port (
    i_CLK : in std_logic;

    -- dado de entrada
    i_DATA : in std_logic_vector (DATA_WIDTH - 1 downto 0);

    -- habilita escrita    
    i_WRITE_ENA : in std_logic;

    -- linha de buffer selecionada
    i_SEL_LINE : in std_logic_vector (1 downto 0);

    -- endereco a ser lido
    i_READ_ADDR0 : in std_logic_vector (ADDR_WIDTH - 1 downto 0) := (others => '0');
    i_READ_ADDR1 : in std_logic_vector (ADDR_WIDTH - 1 downto 0) := (others => '0');
    i_READ_ADDR2 : in std_logic_vector (ADDR_WIDTH - 1 downto 0) := (others => '0');

    -- endereco a ser escrito
    i_WRITE_ADDR : in std_logic_vector (ADDR_WIDTH - 1 downto 0) := (others => '0');

    -- dados de saida     
    o_DATA_ROW_0 : out std_logic_vector (DATA_WIDTH - 1 downto 0);
    o_DATA_ROW_1 : out std_logic_vector (DATA_WIDTH - 1 downto 0);
    o_DATA_ROW_2 : out std_logic_vector (DATA_WIDTH - 1 downto 0)

  );
end io_buffer;

--- Arch
architecture arch of io_buffer is
  type t_BLOCKS_DATA is array (2 downto 0) of std_logic_vector(DATA_WIDTH - 1 downto 0);
  type t_BLOCKS_ADDR is array (2 downto 0) of std_logic_vector(ADDR_WIDTH - 1 downto 0);

  -- memoria
  component generic_ram is
    generic (
      DATA_WIDTH : integer := 8;
      DATA_DEPTH : integer := 10);
    port (
      address : in std_logic_vector (DATA_DEPTH - 1 downto 0);
      clock   : in std_logic := '1';
      data    : in std_logic_vector (DATA_WIDTH - 1 downto 0);
      wren    : in std_logic;
      q       : out std_logic_vector (DATA_WIDTH - 1 downto 0)
    );
  end component;

  -- endereco  
  signal w_ADDRs : t_BLOCKS_ADDR := (others => (others => '0'));

  -- saidas blocos  
  signal w_BLOCK_OUT : t_BLOCKS_DATA := (others => (others => '0'));

  -- write enable signals
  signal w_WRITE_ENA : std_logic_vector(2 downto 0) := (others => '0');

  -- registradore do banco de registradores da quarta camada
  signal r_REGISTERS : t_REGISTER_BANK (0 to 1)(0 to 3)(7 downto 0) := (others => (others => (others => '0')));

begin

  -- endereco  
  w_ADDRs(0) <= i_WRITE_ADDR when (i_WRITE_ENA = '1') else
  i_READ_ADDR0;
  w_ADDRs(1) <= i_WRITE_ADDR when (i_WRITE_ENA = '1') else
  i_READ_ADDR1;
  w_ADDRs(2) <= i_WRITE_ADDR when (i_WRITE_ENA = '1') else
  i_READ_ADDR2;

  -- enable buffers
  w_WRITE_ENA(0) <= not i_SEL_LINE(1) and not i_SEL_LINE(0) and i_WRITE_ENA;
  w_WRITE_ENA(1) <= not i_SEL_LINE(1) and i_SEL_LINE(0) and i_WRITE_ENA;
  w_WRITE_ENA(2) <= i_SEL_LINE(1) and not i_SEL_LINE(0) and i_WRITE_ENA;

  GEN_REG : if USE_REGISTER = 1 generate
  begin

    -- blocos de memoria
    GEN_BLOCK :
    for i in 0 to NUM_BLOCKS - 1 generate
    begin

      -- processo registrador
      process (i_CLK, w_ADDRs, i_DATA, w_WRITE_ENA) is
      begin

        if (rising_edge(i_CLK) and w_WRITE_ENA(i) = '1') then
          r_REGISTERS(i)(to_integer(unsigned(w_ADDRs(i)))) <= i_DATA;
        end if;
      end process;

      w_BLOCK_OUT(i) <= r_REGISTERS(i)(to_integer(unsigned(w_ADDRs(i))));
    end generate GEN_BLOCK;
  end generate GEN_REG;
  GEN_MK10 : if USE_REGISTER = 0 generate

    -- blocos de memoria
    GEN_BLOCK :
    for i in 0 to NUM_BLOCKS - 1 generate
      ramx : generic_ram
      generic map(DATA_WIDTH, ADDR_WIDTH)
      port map(
        w_ADDRs(i),
        i_CLK,
        i_DATA,
        w_WRITE_ENA(i),
        w_BLOCK_OUT(i)
      );
    end generate GEN_BLOCK;
  end generate GEN_MK10;
  -- dados de saida
  o_DATA_ROW_0 <= w_BLOCK_OUT(0);
  o_DATA_ROW_1 <= w_BLOCK_OUT(1);
  o_DATA_ROW_2 <= w_BLOCK_OUT(2);

end arch;
