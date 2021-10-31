-- generic mux


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL; 
library work;
use work.types_pkg.all;

ENTITY generic_multiplexer is      
  generic 
  (
    NC_SEL_WIDTH : integer := 2;
    DATA_WIDTH : integer := 32
  );
  PORT 
  (    
    i_A   : IN  t_ARRAY_OF_LOGIC_VECTOR(0 to (2**NC_SEL_WIDTH)-1)(DATA_WIDTH-1 downto 0) := (others => (others => '0'));
    i_SEL : IN  std_logic_vector(NC_SEL_WIDTH - 1 DOWNTO 0);
    o_Q   : OUT std_logic_vector(31 DOWNTO 0)
  );
END generic_multiplexer;

ARCHITECTURE arch OF generic_multiplexer IS
  signal w_INDEX : integer := 0;

BEGIN  
  w_INDEX <= to_integer(unsigned(i_SEL));
  o_Q <= i_A(w_INDEX);
END arch;
------------------------------------------------------