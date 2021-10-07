-- Primeira camada convolucional
-------------------------------
-- Cx3 buffers de entrada 
-- MxC Nucleos convolucionais
-- Arvore de somadores
-- Reg
-- Relu
-- Mx1 buffers de saída


library ieee;
use ieee.std_logic_1164.all;

entity conv1 is
  generic 
  (
    H : integer := 32; -- iFMAP Height 
    W : integer := 24; -- iFMAP Width 
    C : integer := 3;  -- iFMAP Chanels (filter Chanels also)
    R : integer := 3; -- filter Height 
    S : integer := 3; -- filter Width     
    M : integer := 6; -- Number of filters (oFMAP Chanels also)
    P : integer := 1 -- padding (1 - same; 0 - valid)
  );
  port 
  (
    i_CLK       : in STD_LOGIC;
    i_CLR       : in STD_LOGIC
    
  );
end conv1;

architecture arch of conv1 is


begin

end arch;
