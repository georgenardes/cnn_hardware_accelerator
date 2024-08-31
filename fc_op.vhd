-- operacional fc
-------------------

-------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.STD_LOGIC_UNSIGNED.all;
use ieee.numeric_std.all;
library work;
use work.types_pkg.all;
-- Entity
entity fc_op is
  generic (
    DATA_WIDTH         : integer          := 8;
    ADDR_WIDTH         : integer          := 10;
    NUM_CHANNELS       : integer          := 64;
    NUM_UNITS          : integer          := 1;
    BIAS_ADDRESS_WIDTH : integer          := 6;
    SCALE_FACTOR       : std_logic_vector := "01000000000000000000000000000000"; -- 32 b, primeiro bit sinal sempre 0
    SCALE_SHIFT        : integer          := 7
  );

  port (
    i_CLK : in std_logic;
    i_CLR : in std_logic;

    -- pixels de entrada
    i_PIX : in std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');

    -- PESO DE ENTRADA
    i_WEIGHT : in t_ARRAY_OF_LOGIC_VECTOR(0 to NUM_UNITS - 1)(DATA_WIDTH - 1 downto 0) := (others => (others => '0'));

    -- habilita registradores de pixel e peso
    i_REG_PIX_ENA    : in std_logic;
    i_REG_WEIGHT_ENA : in std_logic;

    -- valor de bias ou scale
    i_BIAS_SCALE : in std_logic_vector(31 downto 0);

    -- ENDERECO BIAS
    i_REG_BIAS_ADDR : in std_logic_vector(BIAS_ADDRESS_WIDTH - 1 downto 0);
    i_REG_BIAS_ENA  : in std_logic;

    -- habilita acumulador
    i_ACC_ENA : in std_logic;
    i_ACC_CLR : in std_logic;

    -- habilita/clear registrador de saida
    i_REG_OUT_CLR  : in std_logic := '0';
    i_REG_OUT_ENA  : in std_logic;
    i_REG_OUT_ADDR : in std_logic_vector(5 downto 0) := (others => '0');
    -- valores de saida
    o_PIX : out t_ARRAY_OF_LOGIC_VECTOR(0 to 34)(DATA_WIDTH - 1 downto 0) := (others => (others => '0'))

  );
end fc_op;

--- Arch
architecture arch of fc_op is
  -- Entity
  component neuronio is
    generic (
      IN_DATA_WIDTH  : integer := 8;
      OUT_DATA_WIDTH : integer := 32);

    port (
      i_CLK            : in std_logic;
      i_CLR            : in std_logic;
      i_ACC_ENA        : in std_logic;
      i_REG_PIX_ENA    : in std_logic;
      i_REG_WEIGHT_ENA : in std_logic;
      i_ACC_CLR        : in std_logic;
      i_PIX            : in std_logic_vector (IN_DATA_WIDTH - 1 downto 0);
      i_WEIGHT         : in std_logic_vector (IN_DATA_WIDTH - 1 downto 0);
      o_PIX            : out std_logic_vector (OUT_DATA_WIDTH - 1 downto 0)
    );
  end component;

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
  -- one-hot encoder
  component one_hot_encoder is
    generic (
      DATA_WIDTH : integer := 5;
      OUT_WIDTH  : integer := 18 -- quantidade de elementos enderecados
    );
    port (
      i_DATA : in std_logic_vector(DATA_WIDTH - 1 downto 0);
      o_DATA : out std_logic_vector(OUT_WIDTH - 1 downto 0)
    );
  end component;
  -- SAIDA DOS NUCLEOS FC
  signal w_NFC_OUT : t_ARRAY_OF_LOGIC_VECTOR(0 to NUM_UNITS - 1)(31 downto 0) := (others => (others => '0'));

  -- resultado add bias
  signal w_ADD_BIAS_OUT : t_ARRAY_OF_LOGIC_VECTOR(0 to NUM_UNITS - 1)(31 downto 0) := (others => (others => '0'));

  -- para multiplicacao com scale, pixel negativo
  signal w_A : t_ARRAY_OF_LOGIC_VECTOR(0 to NUM_UNITS - 1)(31 downto 0) := (others => (others => '0'));
  signal w_B : std_logic_vector(31 downto 0)                            := (others => '0');

  -- resultado scale
  signal w_SCALE_OUT : t_ARRAY_OF_LOGIC_VECTOR(0 to NUM_UNITS - 1)(63 downto 0) := (others => (others => '0'));

  -- resultado cast 32
  signal w_CAST_OUT : t_ARRAY_OF_LOGIC_VECTOR(0 to NUM_UNITS - 1)(31 downto 0) := (others => (others => '0'));

  -- resultado shift reg
  signal w_SHIFT_OUT : t_ARRAY_OF_LOGIC_VECTOR(0 to NUM_UNITS - 1)(31 downto 0) := (others => (others => '0'));

  -- RESULTADO SOMA OFFSET 
  signal w_OFFSET_OUT : t_ARRAY_OF_LOGIC_VECTOR(0 to NUM_UNITS - 1)(31 downto 0) := (others => (others => '0'));

  -- resultado CLIP
  signal w_CLIP_OUT : t_ARRAY_OF_LOGIC_VECTOR(0 to NUM_UNITS - 1)(7 downto 0) := (others => (others => '0'));

  -- saida registrador de saida
  signal r_REG_OUT : t_ARRAY_OF_LOGIC_VECTOR(0 to 34)(7 downto 0) := (others => (others => '0'));

  -- endereco bias habilitado
  signal w_BIAS_ADDR : std_logic_vector(NUM_UNITS - 1 downto 0) := (others => '0');

  -- scale
  signal w_SCALE : std_logic_vector(31 downto 0) := (others => '0');

  -- habilita um determinado registrador de saida
  signal w_REG_OUT_ADDR : std_logic_vector(34 downto 0) := (others => '0');

begin

  GEN_UNITS :
  for i in 0 to (NUM_UNITS - 1) generate
    -- saida registrador bias
    signal w_REG_BIAS_OUT : std_logic_vector(31 downto 0) := (others => '0');

  begin

    -- NFC
    u_UNIT : neuronio
    generic map(8, 32)
    port map(
      i_CLK            => i_CLK,
      i_CLR            => i_CLR,
      i_ACC_ENA        => i_ACC_ENA,
      i_REG_PIX_ENA    => i_REG_PIX_ENA,
      i_REG_WEIGHT_ENA => i_REG_WEIGHT_ENA,
      i_ACC_CLR        => i_ACC_CLR,
      i_PIX            => i_PIX,
      i_WEIGHT         => i_WEIGHT(i),
      o_PIX            => w_NFC_OUT(i)
    );

    u_REG_BIAS : registrador
    generic map(DATA_WIDTH => 32)
    port map(
      i_CLK => i_CLK,
      i_CLR => i_CLR,
      i_ENA => i_REG_BIAS_ENA and w_BIAS_ADDR(i),
      i_A   => i_BIAS_SCALE,
      o_Q   => w_REG_BIAS_OUT
    );
    -- add bias
    w_ADD_BIAS_OUT(i)   <= std_logic_vector(signed(w_NFC_OUT(i)) + signed(w_REG_BIAS_OUT));
    w_A(i)(31 downto 0) <= w_ADD_BIAS_OUT(i);
    -- w_B(30 downto 0) <= w_SCALE(31 downto 1);

    -- SCALE DOWN HERE 
    w_SCALE_OUT(i) <= std_logic_vector(signed(w_A(i)) * signed(SCALE_FACTOR));

    -- cast 32 b
    w_CAST_OUT(i) <= w_SCALE_OUT(i)(62 downto 31);

    -- shift 
    w_SHIFT_OUT(i)(31 - SCALE_SHIFT downto 0)  <= w_CAST_OUT(i)(31 downto SCALE_SHIFT);
    w_SHIFT_OUT(i)(31 downto 31 - SCALE_SHIFT) <= (others => '1') when (w_CAST_OUT(i)(31) = '1') else
    (others                                               => '0');
    -- offset (+82) OFFSET DADO PELO TENSORFLOW
    w_OFFSET_OUT(i) <= w_SHIFT_OUT(i) + std_logic_vector(to_unsigned(82, 32));

    -- shift + clip 8
    w_CLIP_OUT(i) <= w_OFFSET_OUT(i)(7 downto 0);

  end generate GEN_UNITS;

  GEN_OUT_BUFFER :
  for i in 0 to 34 generate
  begin
    u_REG_OUT : registrador
    generic map(DATA_WIDTH => 8)
    port map(
      i_CLK => i_CLK,
      i_CLR => i_REG_OUT_CLR,
      i_ENA => i_REG_OUT_ENA and W_REG_OUT_ADDR(i),
      i_A   => w_CLIP_OUT(0), -- TODO: tornar indice clip_out variável
      o_Q   => r_REG_OUT(i)
    );
  end generate GEN_OUT_BUFFER;
  -- -- registrador de scale
  -- u_REG_SCALE : registrador 
  --       generic map ( DATA_WIDTH => 32)
  --       PORT map
  --       (  
  --         i_CLK       => i_CLK ,
  --         i_CLR       => i_CLR ,
  --         i_ENA       => i_REG_SCALE_ENA,
  --         i_A         => i_BIAS_SCALE,   
  --         o_Q         => w_SCALE
  --       );  

  u_OHE_BIAS : one_hot_encoder
  generic map(
    DATA_WIDTH => BIAS_ADDRESS_WIDTH,
    OUT_WIDTH  => NUM_UNITS
  )
  port map(
    i_DATA => i_REG_BIAS_ADDR,
    o_DATA => w_BIAS_ADDR
  );
  u_OHE_OUT : one_hot_encoder
  generic map(
    DATA_WIDTH => 6,
    OUT_WIDTH  => 35
  )
  port map(
    i_DATA => i_REG_OUT_ADDR,
    o_DATA => W_REG_OUT_ADDR
  );

  o_PIX <= r_REG_OUT;

end arch;
