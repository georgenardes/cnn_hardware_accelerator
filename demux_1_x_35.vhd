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


ENTITY demux_1_x_35 is 
  PORT (  
    i_A         : IN  std_logic_vector(c_SOFTMAX_DATA_WIDTH - 1 DOWNTO 0);
    i_SEL       : IN  std_logic_vector(6 DOWNTO 0); -- 6 bits para enderecamento
    o_Q         : OUT t_SOFTMAX_VET 
  );
END demux_1_x_35;

ARCHITECTURE arch OF demux_1_x_35 IS
  signal w_OUT : t_SOFTMAX_VET := (others => (others => '0'));    
  
BEGIN    

  
  process (i_A, i_SEL)
  begin
    for i in 0 to 34 loop
      if (i = to_integer(unsigned(i_SEL))) then 
        w_OUT(i) <= i_A; -- caso valor selecionado
      else
        w_OUT(i) <= "00000000"; -- caso valor não selecionado
      end if;
    end loop;
  end process;
  
  -- atribui saida selecionada
  o_Q <= w_OUT;
END arch;