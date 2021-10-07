-- PACOTE DE TIPOS CUSTOMIZADOS e CONSTANTES GLOBAIS

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

PACKAGE types_pkg IS
  
  -- tipo saida conv1
  type t_CONV1_OUT is array (0 to 5) of STD_LOGIC_VECTOR(7 downto 0);
  
  
  
  
  
  
  
  constant c_SOFTMAX_DATA_WIDTH : integer := 8;
  constant c_SOFTMAX_IN_WIDHT : integer := 35;   
  
  -- definicao de um array 2D para uso como entrada
  -- 35 entradas de 8 bits
  type t_SOFTMAX_VET is array (0 to c_SOFTMAX_IN_WIDHT - 1) of STD_LOGIC_VECTOR(c_SOFTMAX_DATA_WIDTH-1 downto 0); 
 
  
  constant c_RAM_BLOCKS : integer := 487;     
  constant c_RAM_WIDTH : integer := 8;
  type t_RAM_INPUT is array (0 to c_RAM_BLOCKS - 1) of STD_LOGIC_VECTOR(c_RAM_WIDTH-1 downto 0);
   
END PACKAGE types_pkg;