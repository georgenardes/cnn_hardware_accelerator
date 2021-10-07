-------------------
-- Arvore de Comparadores
-- 10/09/2021
-- George
-- R1

-- Descrição
-- Esse bloco realiza a comparação entre 4 valores de 8 bits
-- e seleciona como saída o maior valor. 
-------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.STD_LOGIC_UNSIGNED.all;

-- Entity
entity arvore_comparadores is
  generic (DATA_WIDTH : INTEGER := 8);
  
  port (
    -- VALORES A SEREM COMPARADOS
    i_PIX_1 : in STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);   
    i_PIX_2 : in STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
    i_PIX_3 : in STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
    i_PIX_4 : in STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);

    -- pixel de saida
    o_PIX   : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0)

  );
end arvore_comparadores;

--- Arch
architecture arch of arvore_comparadores is
    
  -- sinais para resultados intermediarios
  signal w_PIX_OUT_1 : STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
  signal w_PIX_OUT_2 : STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
  signal w_PIX_OUT_3 : STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
      
begin
  w_PIX_OUT_1 <= i_PIX_1 when (i_PIX_1 > i_PIX_2) else i_PIX_2;
  w_PIX_OUT_2 <= i_PIX_3 when (i_PIX_3 > i_PIX_4) else i_PIX_4;
  w_PIX_OUT_3 <= w_PIX_OUT_1 when (w_PIX_OUT_1 > w_PIX_OUT_2) else w_PIX_OUT_2;  
  o_PIX <= w_PIX_OUT_3;
end arch;
