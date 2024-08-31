-- generic demuxer
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.types_pkg.all;

entity generic_demultiplexer is
  generic (
    SEL_WIDTH  : integer := 2;
    DATA_WIDTH : integer := 8
  );
  port (
    i_A   : in std_logic_vector(DATA_WIDTH - 1 downto 0);
    i_SEL : in std_logic_vector(SEL_WIDTH - 1 downto 0);
    o_Q   : out t_ARRAY_OF_LOGIC_VECTOR(0 to (2 ** SEL_WIDTH) - 1)(DATA_WIDTH - 1 downto 0) := (others => (others => '0'))
  );
end generic_demultiplexer;

architecture arch of generic_demultiplexer is
begin

  process (i_A, i_SEL)
  begin
    for i in 0 to ((2 ** SEL_WIDTH) - 1) loop
      if (i = to_integer(unsigned(i_SEL))) then
        o_Q(i) <= i_A; -- caso valor selecionado
      else
        o_Q(i) <= (others => '0'); -- caso valor não selecionado
      end if;
    end loop;
  end process;
end arch;
