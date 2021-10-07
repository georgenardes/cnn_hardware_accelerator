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

-- Entity
entity io_buffer is
  generic 
  (
    NUM_BLOCKS : integer := 3;    
    DATA_WIDTH : integer := 8;    
    ADDR_WIDTH : integer := 10
  );
  
  port 
  (
    i_CLK       : in  std_logic;
    i_CLR       : in  std_logic;
    
    -- dado de entrada
    i_DATA      : in  std_logic_vector (DATA_WIDTH - 1 downto 0);
    
    -- habilita leitura
    i_READ_ENA  : in std_logic;
    
    -- habilita escrita    
    i_WRITE_ENA : in std_logic;
    
    -- linha de buffer selecionada
    i_SEL_LINE  : in std_logic_vector (1 downto 0);
    
    -- endereco a ser lido
    i_READ_ADDR0   : in std_logic_vector (ADDR_WIDTH - 1 downto 0);
    i_READ_ADDR1   : in std_logic_vector (ADDR_WIDTH - 1 downto 0);
    i_READ_ADDR2   : in std_logic_vector (ADDR_WIDTH - 1 downto 0);
    
    -- endereco a ser escrito
    i_WRITE_ADDR  : in std_logic_vector (ADDR_WIDTH - 1 downto 0);
    
    -- dados de saida     
    o_DATA_ROW_0  : out std_logic_vector (DATA_WIDTH - 1 downto 0);
    o_DATA_ROW_1  : out std_logic_vector (DATA_WIDTH - 1 downto 0);
    o_DATA_ROW_2  : out std_logic_vector (DATA_WIDTH - 1 downto 0)
        
  );
end io_buffer;

--- Arch
architecture arch of io_buffer is
  type t_BLOCKS_DATA is array (2 downto 0) of STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
  type t_BLOCKS_ADDR is array (2 downto 0) of STD_LOGIC_VECTOR(ADDR_WIDTH - 1 downto 0);
  
  -- memoria
  component generic_ram IS
    GENERIC (DATA_WIDTH : INTEGER := 8;
             DATA_DEPTH : INTEGER := 10);     
    PORT
    (
      address	: IN STD_LOGIC_VECTOR (DATA_DEPTH - 1 DOWNTO 0);
      clock		: IN STD_LOGIC  := '1';
      data		: IN STD_LOGIC_VECTOR (DATA_WIDTH - 1 DOWNTO 0);
      wren		: IN STD_LOGIC ;
      q		    : OUT STD_LOGIC_VECTOR (DATA_WIDTH - 1 DOWNTO 0)
    );
  END component;

  -- endereco  
  signal w_ADDRs : t_BLOCKS_ADDR := (others => (others => '0'));
  
  -- saidas blocos  
  signal w_BLOCK_OUT : t_BLOCKS_DATA := (others => (others => '0'));
  
  -- write enable signals
  signal w_WRITE_ENA : STD_LOGIC_VECTOR(2 downto 0) := (others => '0');
  
  
begin

  -- endereco  
  w_ADDRs(0) <= i_WRITE_ADDR when (i_WRITE_ENA = '1') else i_READ_ADDR0;
  w_ADDRs(1) <= i_WRITE_ADDR when (i_WRITE_ENA = '1') else i_READ_ADDR1;
  w_ADDRs(2) <= i_WRITE_ADDR when (i_WRITE_ENA = '1') else i_READ_ADDR2;
                
                
  -- enable buffers
  w_WRITE_ENA(0) <= not i_SEL_LINE(0) and not i_SEL_LINE(1) and i_WRITE_ENA;
  w_WRITE_ENA(1) <= not i_SEL_LINE(0) and     i_SEL_LINE(1) and i_WRITE_ENA;
  w_WRITE_ENA(2) <=     i_SEL_LINE(0) and not i_SEL_LINE(1) and i_WRITE_ENA;
  
  
  -- blocos de memoria
  GEN_BLOCK: 
    for i in 0 to NUM_BLOCKS-1 generate
      ramx : generic_ram
                generic map (DATA_WIDTH, ADDR_WIDTH)
                port map 
                (
                  w_ADDRs(i),
                  i_CLK,
                  i_DATA,
                  w_WRITE_ENA(i),
                  w_BLOCK_OUT(i)
                );
  end generate GEN_BLOCK;
  
  
  -- dados de saida
  o_DATA_ROW_0 <= w_BLOCK_OUT(0);
  o_DATA_ROW_1 <= w_BLOCK_OUT(1);
  o_DATA_ROW_2 <= w_BLOCK_OUT(2);
  
end arch;




