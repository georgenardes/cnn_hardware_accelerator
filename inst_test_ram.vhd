-- INSTATIATION TEST FOR GENERIC RAM
-- Registrador Generico
-- 09/09/2021
-- George
-- R1

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
library work;
use work.types_pkg.all;

ENTITY inst_test_ram is 
  GENERIC (DATA_WIDTH : INTEGER := 8;
           DATA_DEPTH : INTEGER := 8;
           NUM_BLOCOS : INTEGER := 487);
  PORT 
  (  
    -- i_CLK       : IN  std_logic;
    address	: IN STD_LOGIC_VECTOR (DATA_DEPTH - 1 DOWNTO 0);    
    data		: IN STD_LOGIC_VECTOR (DATA_WIDTH - 1 DOWNTO 0);
    -- wren		: IN STD_LOGIC ;
    -- q		    : OUT STD_LOGIC_VECTOR (DATA_WIDTH - 1 DOWNTO 0);      
    i_CLK   : IN  std_logic;    
    wren		: IN STD_LOGIC                 
  );
END inst_test_ram;

ARCHITECTURE arch OF inst_test_ram IS

  component generic_ram
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
  end component;  
  
  signal wq	: t_RAM_INPUT := (others => (others => '0'));
  
BEGIN  
  
--  u_RAM : generic_ram 
--            generic map (DATA_WIDTH, DATA_DEPTH)
--            port map (address, i_CLK, data, wren, q);
  
  GEN_BLOCK: 
  for i in 0 to (NUM_BLOCOS-1) generate
  
    BLOCKX : generic_ram 
            generic map (DATA_WIDTH, DATA_DEPTH)
            port map (address, i_CLK, data, wren, wq(i));
      
  end generate GEN_BLOCK;

END arch;