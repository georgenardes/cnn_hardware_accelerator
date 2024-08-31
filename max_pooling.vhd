-------------------
-- Bloco Max Pooling
-- 10/09/2021
-- George
-- R1

-- Descrição
-- Este bloco realiza a operação de max pooling entre
-- quatro valores de 8 bits

-------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.STD_LOGIC_UNSIGNED.all;

-- Entity
entity max_pooling is
  generic (DATA_WIDTH : integer := 8);
  port (
    i_CLK : in std_logic;
    i_CLR : in std_logic;

    -- habilita deslocamento dos registradores
    i_PIX_SHIFT_ENA : in std_logic;

    -- linhas de pixels
    i_PIX_ROW_1 : in std_logic_vector (DATA_WIDTH - 1 downto 0);
    i_PIX_ROW_2 : in std_logic_vector (DATA_WIDTH - 1 downto 0);

    -- pixel de saida
    o_PIX : out std_logic_vector (DATA_WIDTH - 1 downto 0)

  );
end max_pooling;

--- Arch
architecture arch of max_pooling is

  type t_MAT is array (1 downto 0) of std_logic_vector(DATA_WIDTH - 1 downto 0);

  -- registradores de deslocamento para os pixels
  signal w_PIX_ROW_1 : t_MAT := (others => (others => '0'));
  signal w_PIX_ROW_2 : t_MAT := (others => (others => '0'));
  -- Componentes  
  component arvore_comparadores is
    generic (DATA_WIDTH : integer := 8);
    port (
      -- VALORES A SEREM COMPARADOS
      i_PIX_1 : in std_logic_vector (DATA_WIDTH - 1 downto 0);
      i_PIX_2 : in std_logic_vector (DATA_WIDTH - 1 downto 0);
      i_PIX_3 : in std_logic_vector (DATA_WIDTH - 1 downto 0);
      i_PIX_4 : in std_logic_vector (DATA_WIDTH - 1 downto 0);

      -- pixel de saida
      o_PIX : out std_logic_vector (DATA_WIDTH - 1 downto 0)
    );
  end component;

begin
  p_DESLOCAMENTO : process (i_CLR, i_CLK)
  begin
    -- reset
    if (i_CLR = '1') then
      w_PIX_ROW_1 <= (others => (others => '0'));
      w_PIX_ROW_2 <= (others => (others => '0'));

    elsif (rising_edge(i_CLK)) then

      -- desloca registradores de pixels
      if (i_PIX_SHIFT_ENA = '1') then

        w_PIX_ROW_1(1) <= w_PIX_ROW_1(0);
        w_PIX_ROW_2(1) <= w_PIX_ROW_2(0);

        w_PIX_ROW_1(0) <= i_PIX_ROW_1;
        w_PIX_ROW_2(0) <= i_PIX_ROW_2;

      end if;
    end if;
  end process;
  -- multiplicadores
  u_ARVORE_COMP : arvore_comparadores
  generic map(DATA_WIDTH)
  port map(
    w_PIX_ROW_1(0),
    w_PIX_ROW_1(1),
    w_PIX_ROW_2(0),
    w_PIX_ROW_2(1),
    o_PIX);
end arch;
