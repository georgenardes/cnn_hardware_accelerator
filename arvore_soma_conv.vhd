-------------------
-- Arvore de soma para convolucao
-- 09/09/2021
-- George
-- R1

-- Descrição
-- Este componente realizará a soma
-- entre 9 valores de 16 bits com sinal,
-- que resultará em um valor de 32 bits com sinal.
-------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity arvore_soma_conv is
  generic (
    i_DATA_WIDTH : integer := 16;
    o_DATA_WIDTH : integer := 32);

  port (
    i_DATA1 : in std_logic_vector (i_DATA_WIDTH - 1 downto 0);
    i_DATA2 : in std_logic_vector (i_DATA_WIDTH - 1 downto 0);
    i_DATA3 : in std_logic_vector (i_DATA_WIDTH - 1 downto 0);
    i_DATA4 : in std_logic_vector (i_DATA_WIDTH - 1 downto 0);
    i_DATA5 : in std_logic_vector (i_DATA_WIDTH - 1 downto 0);
    i_DATA6 : in std_logic_vector (i_DATA_WIDTH - 1 downto 0);
    i_DATA7 : in std_logic_vector (i_DATA_WIDTH - 1 downto 0);
    i_DATA8 : in std_logic_vector (i_DATA_WIDTH - 1 downto 0);
    i_DATA9 : in std_logic_vector (i_DATA_WIDTH - 1 downto 0);
    o_DATA  : out std_logic_vector (o_DATA_WIDTH - 1 downto 0)
  );

end arvore_soma_conv;

architecture arch of arvore_soma_conv is
  -- saida de somadores
  signal w_SUM1_OUT, w_SUM2_OUT, w_SUM3_OUT, w_SUM4_OUT,
  w_SUM5_OUT, w_SUM6_OUT,
  w_SUM7_OUT : std_logic_vector(o_DATA_WIDTH - 1 downto 0);

  -- Sinais para adaptação das entradas de 16 bits
  -- para 32 bits.
  -- Motivo: para teste como o modelsim, é necesário criar 
  -- sinais de 32 bits e conecta-los às entradas dos
  -- somadores em vez de selecionar uma faixa de valores,
  -- na instanciação dos componentes.  
  type t_MAT is array (8 downto 0) of std_logic_vector(o_DATA_WIDTH - 1 downto 0);
  signal w_ENTRADAS : t_MAT := (others => (others => '0'));
begin

  -- conversão entrada 16 bits para 32 bits
  w_ENTRADAS(0)(15 downto 0) <= i_DATA1;
  w_ENTRADAS(1)(15 downto 0) <= i_DATA2;
  w_ENTRADAS(2)(15 downto 0) <= i_DATA3;
  w_ENTRADAS(3)(15 downto 0) <= i_DATA4;
  w_ENTRADAS(4)(15 downto 0) <= i_DATA5;
  w_ENTRADAS(5)(15 downto 0) <= i_DATA6;
  w_ENTRADAS(6)(15 downto 0) <= i_DATA7;
  w_ENTRADAS(7)(15 downto 0) <= i_DATA8;
  w_ENTRADAS(8)(15 downto 0) <= i_DATA9;

  -- conversão para 32b com extensão de sinal
  w_ENTRADAS(0)(31 downto 16) <= (others => '1') when (i_DATA1 (15) = '1') else
  (others                                => '0');
  w_ENTRADAS(1)(31 downto 16) <= (others => '1') when (i_DATA2 (15) = '1') else
  (others                                => '0');
  w_ENTRADAS(2)(31 downto 16) <= (others => '1') when (i_DATA3 (15) = '1') else
  (others                                => '0');
  w_ENTRADAS(3)(31 downto 16) <= (others => '1') when (i_DATA4 (15) = '1') else
  (others                                => '0');
  w_ENTRADAS(4)(31 downto 16) <= (others => '1') when (i_DATA5 (15) = '1') else
  (others                                => '0');
  w_ENTRADAS(5)(31 downto 16) <= (others => '1') when (i_DATA6 (15) = '1') else
  (others                                => '0');
  w_ENTRADAS(6)(31 downto 16) <= (others => '1') when (i_DATA7 (15) = '1') else
  (others                                => '0');
  w_ENTRADAS(7)(31 downto 16) <= (others => '1') when (i_DATA8 (15) = '1') else
  (others                                => '0');
  w_ENTRADAS(8)(31 downto 16) <= (others => '1') when (i_DATA9 (15) = '1') else
  (others                                => '0');
  w_SUM1_OUT <= std_logic_vector(signed(w_ENTRADAS(0)) + signed(w_ENTRADAS(1)));
  w_SUM2_OUT <= std_logic_vector(signed(w_ENTRADAS(2)) + signed(w_ENTRADAS(3)));
  w_SUM3_OUT <= std_logic_vector(signed(w_ENTRADAS(4)) + signed(w_ENTRADAS(5)));
  w_SUM4_OUT <= std_logic_vector(signed(w_ENTRADAS(6)) + signed(w_ENTRADAS(7)));

  w_SUM5_OUT <= std_logic_vector(signed(w_SUM1_OUT) + signed(w_SUM2_OUT));
  w_SUM6_OUT <= std_logic_vector(signed(w_SUM3_OUT) + signed(w_SUM4_OUT));

  w_SUM7_OUT <= std_logic_vector(signed(w_SUM5_OUT) + signed(w_SUM6_OUT));

  o_DATA <= std_logic_vector(signed(w_SUM7_OUT) + signed(w_ENTRADAS(8)));
end arch;
