-- Bloco divisao para o bloco softmax
-- 15/09/2021
-- George
-- R1
-------------------

library ieee;
use ieee.std_logic_1164.all;
USE ieee.numeric_std.ALL;
library work;
use work.types_pkg.all;

-- Entity
entity divisor is
    
  port (    
    i_DIVIDENDO : in STD_LOGIC_VECTOR (c_SOFTMAX_DATA_WIDTH - 1 downto 0);       
    i_DIVISOR : in STD_LOGIC_VECTOR (c_SOFTMAX_DATA_WIDTH - 1 downto 0);
          
    -- RESULTADO
    o_RES : OUT STD_LOGIC_VECTOR (c_SOFTMAX_DATA_WIDTH - 1 downto 0)

  );
end divisor;

--- Arch
architecture arch of divisor is
       
begin
  
  -- divisao
  o_RES <= std_logic_vector(to_signed(to_integer(signed(i_DIVIDENDO) / signed(i_DIVISOR)), c_SOFTMAX_DATA_WIDTH));  
  
end arch;
