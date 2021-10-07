-------------------
-- Registrador Generico
-- 09/09/2021
-- George
-- R1

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY registrador is 
  generic ( DATA_WIDTH : INTEGER := 8);         
  PORT (  i_CLK       : IN  std_logic;
          i_CLR       : IN  std_logic;
          i_ENA       : IN  std_logic;
          i_A         : IN  std_logic_vector(DATA_WIDTH - 1 DOWNTO 0);          
          o_Q         : OUT std_logic_vector(DATA_WIDTH - 1 DOWNTO 0)
          );
END registrador;

ARCHITECTURE arch OF registrador IS
  -- registrador
  signal r_A : std_logic_vector(DATA_WIDTH - 1 DOWNTO 0);           
  
BEGIN  
    
  process (i_CLK, i_CLR, i_ENA, i_A)
  begin 
    -- reset
    if (i_CLR = '1') then
      r_A <= (others => '0');    
    -- subida clock
    elsif (rising_edge(i_CLK)) then 
      -- enable ativo
      if (i_ENA = '1') then
        r_A <= i_A;      
      end if;
    end if;
  end process;
  
  o_Q <= r_A;
END arch;