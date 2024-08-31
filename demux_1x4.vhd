-- demux 1 x 3
-- 19/10/2021
-- George
-- R1

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.types_pkg.all;

entity demux_1x4 is
  port (
    i_A           : in std_logic_vector(7 downto 0);
    i_SEL         : in std_logic_vector(1 downto 0); -- 2 bits para enderecamento
    o_Q, o_R, o_S : out std_logic_vector(7 downto 0)
  );
end demux_1x4;

architecture arch of demux_1x4 is
begin

  o_Q <= i_A when (i_SEL = "00") else
    (others => '0');
  o_R <= i_A when (i_SEL = "01") else
    (others => '0');
  o_S <= i_A when (i_SEL = "10") else
    (others => '0');

end arch;
