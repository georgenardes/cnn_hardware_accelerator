-- somador 1 b completo
-- George
-- ref.: https://www.embarcados.com.br/tutorial-de-verilog-somador-completo/
library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity add1 is
  port (
    a, b, cin : in std_logic;
    sum, cout : out std_logic);
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

library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity BIT_ADDER1 is
  port (
    a, b, cin : in std_logic;
    sum, cout : out std_logic);
end BIT_ADDER1;

architecture BHV of BIT_ADDER1 is
begin

  sum <= (not a and not b and cin) or
    (not a and b and not cin) or
    (a and not b and not cin) or
    (a and b and cin);

  cout <= (not a and b and cin) or
    (a and not b and cin) or
    (a and b and not cin) or
    (a and b and cin);
end BHV;
