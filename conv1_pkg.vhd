------------------------------------------------------
-- PACOTE DE TIPOS CUSTOMIZADOS internos do bloco CONV1
------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

package conv1_pkg IS
  constant c_CONV1_O_DATA_WIDTH : integer := 32;
  constant c_CONV1_C : integer := 3;   -- numero de canais
  constant c_CONV1_M : integer := 6;   -- numero de filtros
  constant c_CONV1_NC : integer := c_CONV1_M*c_CONV1_C;   -- numero de NC
  constant c_NC_SEL_WIDHT : integer := 2; -- largura de bits para selecionar saidas dos NCs
  constant c_NC       : integer := 5; -- number of bits to address NCs 
  
  type t_ARRAY_SCALE_SHIFT is array (0 to c_CONV1_M-1) of integer;
  constant c_SCALE_SHIFT : t_ARRAY_SCALE_SHIFT := (10, 9, 8, 9, 9, 10); --num bits to shift
  
  -- tipo para saida dos NC
  type t_NC_O_VET is array (0 to c_CONV1_NC - 1) of STD_LOGIC_VECTOR(c_CONV1_O_DATA_WIDTH-1 downto 0);    
  
  -- tipo para saida dos MUXs
  type t_MUX_O_VET is array (0 to c_CONV1_M - 1) of STD_LOGIC_VECTOR(c_CONV1_O_DATA_WIDTH-1 downto 0);
  -- +1 pq o mux precisa de 2**2 entradas, mesmo que apenas 3 delas sejam usadas
  type t_MUX_I_VET is array (0 to c_CONV1_C - 1 + 1 ) of STD_LOGIC_VECTOR(c_CONV1_O_DATA_WIDTH-1 downto 0);
  
end package conv1_pkg;
------------------------------------------------------