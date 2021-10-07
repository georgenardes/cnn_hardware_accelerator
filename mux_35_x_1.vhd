-------------------
-- Mux 35x1 
-- 09/09/2021
-- George
-- R1



LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL; 
library work;
use work.types_pkg.all;


ENTITY mux_35_x_1 is             
  PORT (  i_A         : IN  t_SOFTMAX_VET;
          i_SEL       : IN  std_logic_vector(6 DOWNTO 0); -- 6 bits para enderecamento
          o_Q         : OUT std_logic_vector(c_SOFTMAX_DATA_WIDTH - 1 DOWNTO 0)
        );
END mux_35_x_1;

ARCHITECTURE arch OF mux_35_x_1 IS
      
  
BEGIN  
  o_Q <= i_A(to_integer(signed(i_SEL)));
END arch;