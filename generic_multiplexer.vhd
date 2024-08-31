-- generic mux
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.types_pkg.all;

entity generic_multiplexer is
  generic (
    NC_SEL_WIDTH : integer := 2;
    DATA_WIDTH   : integer := 32
  );
  port (
    i_A   : in t_ARRAY_OF_LOGIC_VECTOR(0 to (2 ** NC_SEL_WIDTH) - 1)(DATA_WIDTH - 1 downto 0) := (others => (others => '0'));
    i_SEL : in std_logic_vector(NC_SEL_WIDTH - 1 downto 0);
    o_Q   : out std_logic_vector(31 downto 0)
  );
end generic_multiplexer;

architecture arch of generic_multiplexer is
  signal w_INDEX : integer := 0;

begin
  w_INDEX <= to_integer(unsigned(i_SEL));
  o_Q     <= i_A(w_INDEX);
end arch;
------------------------------------------------------
