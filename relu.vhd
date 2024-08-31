---------------------
-- Núcleo Convolucional
-- 10/09/2021
-- George
-- R1

-- Descrição
-- Este bloco realiza a operação da função de ativação ReLU.

-------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.STD_LOGIC_UNSIGNED.all;

-- Entity
entity relu is
  generic (DATA_WIDTH : integer := 8);

  port (
    -- pixel de entrada
    i_PIX : in std_logic_vector (DATA_WIDTH - 1 downto 0);

    -- pixel de saida
    o_PIX : out std_logic_vector (DATA_WIDTH - 1 downto 0)

  );
end relu;

--- Arch
architecture arch of relu is
begin

  -- atribui 0 aos numeros negativos, identificados pelo oitavo bit em 1
  o_PIX <= i_PIX; -- "00000000" when (i_PIX(DATA_WIDTH - 1) = '1') else i_PIX;

end arch;
