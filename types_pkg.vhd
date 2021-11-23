-- PACOTE DE TIPOS CUSTOMIZADOS e CONSTANTES GLOBAIS

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

PACKAGE types_pkg IS
  
  type t_ARRAY_OF_INTEGER is array (integer range<>) of integer;       
  type t_ARRAY_OF_LOGIC_VECTOR is array(integer range<>) of std_logic_vector;
  type t_REGISTER_BANK is array (integer range<>) of  t_ARRAY_OF_LOGIC_VECTOR; 
   

  -- tipo de entrada rebuff1
  type t_REBBUF1_IN is array (0 to 2) of STD_LOGIC_VECTOR(7 downto 0);
  
  -- tipo entrada conv1/ saida rebuff1
  type t_CONV1_IN is array (0 to 2) of STD_LOGIC_VECTOR(7 downto 0);
  -- tipo saida conv1
  type t_CONV1_OUT is array (0 to 5) of STD_LOGIC_VECTOR(7 downto 0);  
  -- tipo entrada pool1
  type t_POOL1_IN is array (0 to 5) of STD_LOGIC_VECTOR(7 downto 0);
  
  -- tipo saida pool1
  type t_POOL1_OUT is array (0 to 5) of STD_LOGIC_VECTOR(7 downto 0);
  
  -- tipo entrada conv2
  type t_CONV2_IN is array (0 to 5) of STD_LOGIC_VECTOR(7 downto 0);
  
  -- tipo saida conv2
  type t_CONV2_OUT is array (0 to 15) of STD_LOGIC_VECTOR(7 downto 0);
  
  
  constant c_SOFTMAX_DATA_WIDTH : integer := 8;
  constant c_SOFTMAX_IN_WIDHT : integer := 35;   
  
  -- definicao de um array 2D para uso como entrada
  -- 35 entradas de 8 bits
  type t_SOFTMAX_VET is array (0 to c_SOFTMAX_IN_WIDHT - 1) of STD_LOGIC_VECTOR(c_SOFTMAX_DATA_WIDTH-1 downto 0); 
 
    
END PACKAGE types_pkg;