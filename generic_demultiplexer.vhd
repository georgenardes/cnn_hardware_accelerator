-- generic demuxer


LIBRARY ieee;
USE ieee.std_logic_1164.ALL; 
USE ieee.numeric_std.ALL;
library work;
use work.types_pkg.all;


ENTITY generic_demultiplexer is 
  generic 
  (
    SEL_WIDTH : integer := 2;
    DATA_WIDTH : integer := 8
  );
  PORT (  
    i_A    : IN  std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
    i_SEL  : IN  std_logic_vector(SEL_WIDTH-1 DOWNTO 0);
    o_Q    : OUT t_ARRAY_OF_LOGIC_VECTOR(0 to (2**SEL_WIDTH)-1)(DATA_WIDTH-1 downto 0) := (others => (others => '0'))
  );
END generic_demultiplexer;

ARCHITECTURE arch OF generic_demultiplexer IS

  
BEGIN    
  
  process (i_A, i_SEL)
  begin
    for i in 0 to ((2**SEL_WIDTH)-1) loop
      if (i = to_integer(unsigned(i_SEL))) then 
        o_Q(i) <= i_A;              -- caso valor selecionado
      else
        o_Q(i) <= (others => '0'); -- caso valor não selecionado
      end if;
    end loop;
  end process;
  
    
END arch;