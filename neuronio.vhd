-------------------
-- Neurônio
-- 12/09/2021
-- George
-- R1

-- Descrição
-- Este bloco é composto por 1 multiplicador de 8 bits e um
-- acumulador de 32 bits.

-------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.STD_LOGIC_UNSIGNED.all;
use ieee.numeric_std.all;
-- Entity
entity neuronio is
  generic (
    IN_DATA_WIDTH  : integer := 8;
    OUT_DATA_WIDTH : integer := 32);

  port (
    i_CLK : in std_logic;
    i_CLR : in std_logic;

    -- habilita registrador acumulador, registrador pixel e peso
    i_ACC_ENA        : in std_logic;
    i_REG_PIX_ENA    : in std_logic;
    i_REG_WEIGHT_ENA : in std_logic;

    -- reseta acumulador
    i_ACC_CLR : in std_logic;

    -- pixel de entrada
    i_PIX : in std_logic_vector (IN_DATA_WIDTH - 1 downto 0);

    -- peso de entrada
    i_WEIGHT : in std_logic_vector (IN_DATA_WIDTH - 1 downto 0);

    -- pixel de saida
    o_PIX : out std_logic_vector (OUT_DATA_WIDTH - 1 downto 0)

  );
end neuronio;

--- Arch
architecture arch of neuronio is

  -- saida multiplicador, mas com 32 bits (pois será entrada do somador)
  signal w_MULT_OUT : std_logic_vector(OUT_DATA_WIDTH - 1 downto 0) := (others => '0');

  -- saida somador
  signal w_ADD_OUT : std_logic_vector(OUT_DATA_WIDTH - 1 downto 0) := (others => '0');

  -- registradores pixel, peso e acumulador
  signal r_PIX, r_WEIGHT : std_logic_vector(7 downto 0);
  signal r_ACC           : std_logic_vector(OUT_DATA_WIDTH - 1 downto 0);
  -- Registrador
  -------------------------------
  component registrador is
    generic (DATA_WIDTH : integer := 8);
    port (
      i_CLK : in std_logic;
      i_CLR : in std_logic;
      i_ENA : in std_logic;
      i_A   : in std_logic_vector(DATA_WIDTH - 1 downto 0);
      o_Q   : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
  end component;
  -------------------------------

  -- multiplicador que considera faixa de balores para pixel e pesos
  component multiplicador_conv is
    generic (
      i_DATA_WIDTH : integer := 8;
      o_DATA_WIDTH : integer := 16);
    port (
      i_DATA_1 : in std_logic_vector (i_DATA_WIDTH - 1 downto 0); -- pixel (9 bits)
      i_DATA_2 : in std_logic_vector (i_DATA_WIDTH - 1 downto 0); -- peso (9 bits)
      o_DATA   : out std_logic_vector (o_DATA_WIDTH - 1 downto 0)
    );
  end component;

begin

  u_REG_WEIGHT : registrador
  generic map(8)
  port map(
    i_CLK => i_CLK,
    i_CLR => i_CLR,
    i_ENA => i_REG_WEIGHT_ENA,
    i_A   => i_WEIGHT,
    o_Q   => r_WEIGHT
  );
  u_REG_PIX : registrador
  generic map(8)
  port map(
    i_CLK => i_CLK,
    i_CLR => i_CLR,
    i_ENA => i_REG_PIX_ENA,
    i_A   => i_PIX,
    o_Q   => r_PIX
  );

  u_REG_ACC : registrador
  generic map(32)
  port map(
    i_CLK => i_CLK,
    i_CLR => (i_CLR or i_ACC_CLR),
    i_ENA => i_ACC_ENA,
    i_A   => w_ADD_OUT,
    o_Q   => r_ACC
  );

  u_MULT : multiplicador_conv
  port map(
    i_DATA_1 => r_PIX,    -- pix 
    i_DATA_2 => r_WEIGHT, -- peso
    o_DATA   => w_MULT_OUT(15 downto 0)
  );

  -- extende sinal
  w_MULT_OUT(31 downto 16) <= (others => '1') when (w_MULT_OUT(15) = '1') else
  (others                             => '0');

  -- somador
  w_ADD_OUT <= std_logic_vector(signed(r_ACC) + signed(w_MULT_OUT));

  -- saida
  o_PIX <= w_ADD_OUT;

end arch;
