-- N to N one-hot encoder



library ieee;
use ieee.std_logic_1164.all;
use ieee.STD_LOGIC_UNSIGNED.all;
USE ieee.numeric_std.ALL;
library work;
use work.conv1_pkg.all;
use work.types_pkg.all;



entity one_hot_encoder is
  generic 
  (
    DATA_WIDTH : integer := 5;
    NUM         : integer := 18 -- quantidade de elementos enderecados
  );
  port 
  (
     i_DATA : in std_logic_vector(DATA_WIDTH-1 downto 0);
     o_DATA : out std_logic_vector((DATA_WIDTH**2)-1 downto 0)

  );
end one_hot_encoder;

architecture arch of one_hot_encoder is
  
  
begin

  process (i_DATA)
  begin
    for i in 0 to (DATA_WIDTH**2)-1 loop
      
      if (i = to_integer(unsigned(i_DATA)) and i <= NUM) then 
        o_DATA(i) <= '1'; -- caso valor selecionado
      else
        o_DATA(i) <= '0'; -- caso valor não selecionado
      end if;
    end loop;
  end process;

  
end arch;

