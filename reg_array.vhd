-------------------
-- Vetor de registrador para o bloco softmax
-- 15/09/2021
-- George
-- R1

-- Descrição
-- Este bloco contem os 35 registradores para o
-- bloco softmax

-------------------

library ieee;
use ieee.std_logic_1164.all;
library work;
use work.types_pkg.all;

-- Entity
entity reg_array is
    
  port (
    i_CLK       : in STD_LOGIC;    
    
    -- VETOR DE CLEAR
    i_CLR_VET : in STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0);
    
    -- VETOR DE ENABLE
    i_ENA_VET : in STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0);
    
    -- VETOR DE ENTRADA
    i_VET     : in t_SOFTMAX_VET;
    
    -- VETOR DE SAIDA
    o_VET : OUT t_SOFTMAX_VET    

  );
end reg_array;

--- Arch
architecture arch of reg_array is
    
  -- registradores de deslocamento para os pixels
  -- signal r_VET : t_SOFTMAX_VET := (others =>  ( others => '0'));
  
  COMPONENT registrador is 
  generic ( DATA_WIDTH : INTEGER := 8);         
  PORT (  i_CLK       : IN  std_logic;
          i_CLR       : IN  std_logic;
          i_ENA       : IN  std_logic;
          i_A         : IN  std_logic_vector(DATA_WIDTH - 1 DOWNTO 0);          
          o_Q         : OUT std_logic_vector(DATA_WIDTH - 1 DOWNTO 0)
          );
  END COMPONENT;
  
begin

  GEN_REG: 
  for i in 0 to c_SOFTMAX_IN_WIDHT-1 generate
  
    REGX : registrador 
            generic map (c_SOFTMAX_DATA_WIDTH)
            port map (i_CLK, i_CLR_VET(i), i_ENA_VET(i), i_VET(i), o_VET(i));
      
  end generate GEN_REG;
  
  
end arch;
