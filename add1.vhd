-- somador 1 b completo
-- George
-- ref.: https://www.embarcados.com.br/tutorial-de-verilog-somador-completo/


LIBRARY IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity add1 is
        port( a, b, cin         : in  STD_LOGIC;
              sum, cout         : out STD_LOGIC );
end add1;

architecture arch of add1 is
  signal w_A_XOR_B : std_logic;

begin
  
  w_A_XOR_B <= (a xor b);
    
  -- resultado
  sum <= w_A_XOR_B xor cin;   
  -- carry out
  cout <= (a and b) or (w_A_XOR_B and cin);
  
end arch;

---------------------------------------------
---------------------------------------------

--- codigo alternativo
-- Ref.:https://stackoverflow.com/questions/28468334/using-array-of-std-logic-vector-as-a-port-type-with-both-ranges-using-a-generic

LIBRARY IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity BIT_ADDER is
        port( a, b, cin         : in  STD_LOGIC;
              sum, cout         : out STD_LOGIC );
end BIT_ADDER;

architecture BHV of BIT_ADDER is
begin

  sum <=  (not a and not b and cin) or
                  (not a and b and not cin) or
                  (a and not b and not cin) or
                  (a and b and cin);

  cout <= (not a and b and cin) or
                  (a and not b and cin) or
                  (a and b and not cin) or
                  (a and b and cin);
end BHV;
