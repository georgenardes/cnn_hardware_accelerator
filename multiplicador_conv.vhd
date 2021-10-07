-------------------
-- Multiplicador genérico para convolucao
-- 08/09/2021
-- George
-- R1

-- Descrição
-- Este componente realizará a multiplicação
-- entre dois valores de 8 bits com sinal,
-- que resultará em um valor de 16 bits com sinal.
-------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.STD_LOGIC_UNSIGNED.all;

-- Entity
entity multiplicador_conv is
  generic (i_DATA_WIDTH : INTEGER := 8;           
           o_DATA_WIDTH : INTEGER := 16);
    
  port (              
    -- dados de entrada
    i_DATA_1 : in STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);
    i_DATA_2 : in STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);
    
    -- dado de saida
    o_DATA   : out STD_LOGIC_VECTOR (o_DATA_WIDTH - 1 downto 0)

  );
end multiplicador_conv;

--- Arch
architecture arch of multiplicador_conv is
    
  signal w_DATA : STD_LOGIC_VECTOR (o_DATA_WIDTH - 1 downto 0);
  
begin
    
  -- multiplicação
  w_DATA(o_DATA_WIDTH - 1 downto 0) <= i_DATA_1 * i_DATA_2;
  
  o_DATA <= w_DATA;
  
end arch;
