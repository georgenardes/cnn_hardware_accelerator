-- demux 1 x 3
-- 19/10/2021
-- George
-- R1



LIBRARY ieee;
USE ieee.std_logic_1164.ALL; 
USE ieee.numeric_std.ALL;
library work;
use work.types_pkg.all;


ENTITY demux_1x4 is 
  PORT (  
    i_A           : IN  std_logic_vector(7 DOWNTO 0);
    i_SEL         : IN  std_logic_vector(1 DOWNTO 0); -- 2 bits para enderecamento
    o_Q, o_R, o_S : OUT std_logic_vector(7 DOWNTO 0)
  );
END demux_1x4;

ARCHITECTURE arch OF demux_1x4 IS

  
BEGIN    
  
  o_Q <= i_A when (i_SEL = "00") else (others => '0');
  o_R <= i_A when (i_SEL = "01") else (others => '0');
  o_S <= i_A when (i_SEL = "10") else (others => '0');
    
END arch;