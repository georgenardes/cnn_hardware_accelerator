-- contador n bits generico

library ieee;
use ieee.std_logic_1164.all;
use ieee.STD_LOGIC_UNSIGNED.all;
use ieee.numeric_std.all;

entity counter is
  generic 
  (    
    DATA_WIDTH : integer := 8;   
    STEP : integer := 4
  );
  port 
  (
    i_CLK       : in std_logic;
    i_RESET     : in std_logic := '0';
    i_INC       : in std_logic := '0';
    i_RESET_VAL : in std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    o_Q         : out std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0')
  );
end counter;

architecture arch of counter is 
  constant c_STEP : std_logic_vector (DATA_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(STEP, DATA_WIDTH));
  signal r_CNT : std_logic_vector (DATA_WIDTH-1 downto 0) := (others => '0');    
  
begin
  
  
  process (i_CLK, i_RESET, i_INC, i_RESET_VAL)
  begin    
    if (rising_edge(i_CLK)) then
      if (i_RESET = '1') then
        r_CNT <= i_RESET_VAL;
      elsif (i_INC = '1') then      
        r_CNT <= r_CNT + c_STEP;     
      end if;    
    end if;
  end process;   
  
  o_Q <= r_CNT;
  
end arch;