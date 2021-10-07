-- 32 signed overflow/underflow checker
-- 10/09/2021
-- George
-- R1

-- Descrição
-- Este bloco verifica se haverá overflow
-- ou underflow entre dois números de 32 bits com sinal

-- https://www.doc.ic.ac.uk/~eedwards/compsys/arithmetic/index.html
-- 1) Overflow never occurs when adding operands with different signs. 

-- Adding two positive numbers must give a positive result
-- Adding two negative numbers must give a negative result 

-------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.STD_LOGIC_UNSIGNED.all;

-- Entity
entity over_under_flow_checker is
  
  port (
    -- valores de entrada
    i_A : in STD_LOGIC_VECTOR (31 downto 0);
    i_B : in STD_LOGIC_VECTOR (31 downto 0);

    -- sinais de saida
    o_UNDER : out STD_LOGIC;
    o_OVER : out STD_LOGIC
  );
end over_under_flow_checker;

--- Arch
architecture arch of over_under_flow_checker is
  signal w_UNDER, w_OVER : STD_LOGIC := '1';
  
begin
  o_UNDER <= w_UNDER when (i_A(31) = i_B(31)) else '0';
  o_OVER <= w_OVER when (i_A(31) = i_B(31)) else '0';
  
  
end arch;
