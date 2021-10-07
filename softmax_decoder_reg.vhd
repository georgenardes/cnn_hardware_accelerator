-- decode reg softmax
-- 16/09/2021
-- George
-- R1



LIBRARY ieee;
USE ieee.std_logic_1164.ALL; 
USE ieee.numeric_std.ALL;
library work;
use work.types_pkg.all;


ENTITY softmax_decoder_reg is 
  PORT (      
    i_SEL       : IN  std_logic_vector(6 DOWNTO 0); -- 6 bits para enderecamento
    o_Q         : OUT  STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0)  
  );
END softmax_decoder_reg;

ARCHITECTURE arch OF softmax_decoder_reg IS
  
  
BEGIN    
  
  p_ENA : process (i_SEL)
  begin    
    -- para todos os 35 registradors
    for i in 0 to 34 loop 
      -- se for o registrador selecionado pelo r_MUX_CNT
      if (i = to_integer(signed(i_SEL))) then
        o_Q(i) <= '1'; 
      else
        o_Q(i) <= '0';         
      end if;
    end loop;  
  end process;
  

END arch;