-- fc top

-------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.STD_LOGIC_UNSIGNED.all;
use ieee.numeric_std.all;
library work;
use work.types_pkg.all;
-- Entity
entity fc is
  generic (
    DATA_WIDTH            : integer          := 8;
    ADDR_WIDTH            : integer          := 8;
    WEIGHT_ADDRESS_WIDTH  : integer          := 13;              -- numero de bits para enderecar pesos
    BIAS_ADDRESS_WIDTH    : integer          := 6;               -- numero de bits para enderecar registradores de bias e scales    
    NUM_WEIGHT_FILTER_CHA : std_logic_vector := "1000";          -- quantidade de peso por filtro por canal(R*S) (de 0 a 8)
    LAST_WEIGHT           : std_logic_vector := "1000110000000"; -- quantidade de pesos (27) !! QUANTIDADE PESOS POR FILTRO (R*S*C) !!
    LAST_BIAS             : std_logic_vector := "100100";        -- 35 bias + 1 scale
    LAST_FEATURE          : std_logic_vector := "10000000";      -- 128 pixels     
    NUM_CHANNELS          : integer          := 64;
    NUM_UNITS             : integer          := 1;
    SCALE_SHIFT           : integer          := 7
  );

  port (
    i_CLK : in std_logic;
    i_CLR : in std_logic;
    i_GO  : in std_logic;

    -- pixels de entrada
    i_PIX : in std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');

    -- valores de saida
    o_PIX : out t_ARRAY_OF_LOGIC_VECTOR(0 to 34)(DATA_WIDTH - 1 downto 0) := (others => (others => '0'));

    -- endereco de leitura
    o_READ_ADDR : out std_logic_vector(7 downto 0);

    o_READY : out std_logic
  );
end fc;

--- Arch
architecture arch of fc is

  component fc_crt is
    generic (
      DATA_WIDTH            : integer          := 8;
      ADDR_WIDTH            : integer          := 8;
      WEIGHT_ADDRESS_WIDTH  : integer          := 13;              -- numero de bits para enderecar pesos
      BIAS_ADDRESS_WIDTH    : integer          := 6;               -- numero de bits para enderecar registradores de bias e scales    
      NUM_WEIGHT_FILTER_CHA : std_logic_vector := "1000";          -- quantidade de peso por filtro por canal(R*S) (de 0 a 8)
      LAST_WEIGHT           : std_logic_vector := "1000110000000"; -- quantidade de pesos (27) !! QUANTIDADE PESOS POR FILTRO (R*S*C) !!
      LAST_BIAS             : std_logic_vector := "100100";        -- 35 bias + 1 scale
      LAST_FEATURE          : std_logic_vector := "10000000"       -- 128 pixels 
    );
    port (
      i_CLK              : in std_logic;
      i_CLR              : in std_logic;
      i_GO               : in std_logic;  -- inicia maq    
      o_READY            : out std_logic; -- fim maq
      o_REG_PIX_ENA      : out std_logic;
      o_REG_WEIGHT_ENA   : out std_logic;
      o_REG_BIAS_ENA     : out std_logic;
      o_ACC_ENA          : out std_logic;
      o_ACC_CLR          : out std_logic;
      o_REG_OUT_ENA      : out std_logic;
      o_REG_OUT_ADDR     : out std_logic_vector(5 downto 0) := (others => '0');
      o_WEIGHT_READ_ADDR : out std_logic_vector(WEIGHT_ADDRESS_WIDTH - 1 downto 0);
      o_BIAS_READ_ADDR   : out std_logic_vector(BIAS_ADDRESS_WIDTH - 1 downto 0);
      o_IN_READ_ADDR     : out std_logic_vector (7 downto 0)
    );
  end component;
  component fc_op is
    generic (
      DATA_WIDTH   : integer := 8;
      ADDR_WIDTH   : integer := 10;
      NUM_CHANNELS : integer := 64;
      NUM_UNITS    : integer := 1;
      SCALE_SHIFT  : integer := 7
    );

    port (
      i_CLK            : in std_logic;
      i_CLR            : in std_logic;
      i_PIX            : in std_logic_vector(DATA_WIDTH - 1 downto 0)                            := (others => '0');
      i_WEIGHT         : in t_ARRAY_OF_LOGIC_VECTOR(0 to NUM_UNITS - 1)(DATA_WIDTH - 1 downto 0) := (others => (others => '0'));
      i_REG_PIX_ENA    : in std_logic;
      i_REG_WEIGHT_ENA : in std_logic;
      i_BIAS_SCALE     : in std_logic_vector(31 downto 0);
      i_REG_BIAS_ADDR  : in std_logic_vector(BIAS_ADDRESS_WIDTH - 1 downto 0);
      i_REG_BIAS_ENA   : in std_logic;
      i_ACC_ENA        : in std_logic;
      i_ACC_CLR        : in std_logic;
      i_REG_OUT_ENA    : in std_logic;
      i_REG_OUT_ADDR   : in std_logic_vector(5 downto 0)                               := (others => '0');
      o_PIX            : out t_ARRAY_OF_LOGIC_VECTOR(0 to 34)(DATA_WIDTH - 1 downto 0) := (others => (others => '0'))
    );
  end component;
  component banco_de_registradores is
    generic (
      BHEIGHT     : integer := 128;
      BWIDTH      : integer := 35;
      WADDR_WIDTH : integer := 13; -- NUMERO BITS ENDERECAMENTO escrita, TODOS ENDERECOS
      RADDR_WIDTH : integer := 8;  -- NUMERO BITS ENDERECAMENTO leitura
      DATA_WIDTH  : integer := 8
    );

    port (
      i_CLK        : in std_logic;
      i_DATA       : in std_logic_vector (DATA_WIDTH - 1 downto 0);
      i_WRITE_ENA  : in std_logic;
      i_WRITE_ADDR : in std_logic_vector (WADDR_WIDTH - 1 downto 0)           := (others => '0');
      i_READ_ADDR  : in std_logic_vector (RADDR_WIDTH - 1 downto 0)           := (others => '0');
      o_DATA       : out t_ARRAY_OF_LOGIC_VECTOR(0 to BWIDTH - 1)(7 downto 0) := (others => (others => '0'))
    );
  end component;

  component conv1_weights is
    generic (
      init_file_name : string  := "conv1.mif";
      DATA_WIDTH     : integer := 8;
      DATA_DEPTH     : integer := 10
    );
    port (
      address : in std_logic_vector (DATA_DEPTH - 1 downto 0);
      clock   : in std_logic := '1';
      rden    : in std_logic := '1';
      q       : out std_logic_vector (DATA_WIDTH - 1 downto 0)
    );
  end component;
  component conv1_bias is
    generic (
      init_file_name : string  := "conv2_bias.mif";
      DATA_WIDTH     : integer := 32;
      DATA_DEPTH     : integer := 5
    );
    port (
      address : in std_logic_vector (DATA_DEPTH - 1 downto 0);
      clken   : in std_logic := '1';
      clock   : in std_logic := '1';
      q       : out std_logic_vector (DATA_WIDTH - 1 downto 0)
    );
  end component;
  -------------------------------
  signal w_REG_PIX_ENA      : std_logic;
  signal w_REG_WEIGHT_ENA   : std_logic;
  signal w_REG_BIAS_ENA     : std_logic;
  signal w_ACC_ENA          : std_logic;
  signal w_ACC_CLR          : std_logic;
  signal w_REG_OUT_ENA      : std_logic;
  signal w_REG_OUT_ADDR     : std_logic_vector(5 downto 0) := (others => '0');
  signal w_WEIGHT_READ_ADDR : std_logic_vector(WEIGHT_ADDRESS_WIDTH - 1 downto 0);
  signal w_BIAS_READ_ADDR   : std_logic_vector(BIAS_ADDRESS_WIDTH - 1 downto 0);
  signal w_IN_READ_ADDR     : std_logic_vector (7 downto 0);
  signal w_WEIGHT           : t_ARRAY_OF_LOGIC_VECTOR(0 to NUM_UNITS - 1)(DATA_WIDTH - 1 downto 0) := (others => (others => '0'));
  signal w_ROM_OUT          : std_logic_vector (DATA_WIDTH - 1 downto 0)                           := (others => '0');
  signal w_BIAS_SCALE       : std_logic_vector(31 downto 0);

begin

  -- memoria rom de pesos
  u_ROM_WEIGHTS : conv1_weights
  generic map(
    init_file_name => "weights_and_biases/fc.mif",
    DATA_WIDTH     => 8,
    DATA_DEPTH     => WEIGHT_ADDRESS_WIDTH
  )
  port map(
    address => w_WEIGHT_READ_ADDR,
    clock   => i_CLK,
    rden    => '1',
    q       => w_ROM_OUT
  );

  -- memeoria rom de BIAS E SCALE
  u_ROM_BIAS : conv1_bias
  generic map(
    init_file_name => "weights_and_biases/fc_bias.mif",
    DATA_WIDTH     => 32,
    DATA_DEPTH     => BIAS_ADDRESS_WIDTH
  )
  port map(
    address => w_BIAS_READ_ADDR,
    clken   => '1',
    clock   => i_CLK,
    q       => w_BIAS_SCALE
  );

  u_CONTROLE : fc_crt
  generic map(
    DATA_WIDTH            => DATA_WIDTH,
    ADDR_WIDTH            => ADDR_WIDTH,
    WEIGHT_ADDRESS_WIDTH  => WEIGHT_ADDRESS_WIDTH,
    BIAS_ADDRESS_WIDTH    => BIAS_ADDRESS_WIDTH,
    NUM_WEIGHT_FILTER_CHA => NUM_WEIGHT_FILTER_CHA,
    LAST_WEIGHT           => LAST_WEIGHT,
    LAST_BIAS             => LAST_BIAS,
    LAST_FEATURE          => LAST_FEATURE
  )
  port map(
    i_CLK              => i_CLK,
    i_CLR              => i_CLR,
    i_GO               => i_GO,
    o_READY            => o_READY,
    o_REG_PIX_ENA      => w_REG_PIX_ENA,
    o_REG_WEIGHT_ENA   => w_REG_WEIGHT_ENA,
    o_REG_BIAS_ENA     => w_REG_BIAS_ENA,
    o_ACC_ENA          => w_ACC_ENA,
    o_ACC_CLR          => w_ACC_CLR,
    o_REG_OUT_ENA      => w_REG_OUT_ENA,
    o_REG_OUT_ADDR     => w_REG_OUT_ADDR,
    o_WEIGHT_READ_ADDR => w_WEIGHT_READ_ADDR,
    o_BIAS_READ_ADDR   => w_BIAS_READ_ADDR,
    o_IN_READ_ADDR     => w_IN_READ_ADDR
  );

  o_READ_ADDR <= w_IN_READ_ADDR;

  u_OPERACIONAL : fc_op
  generic map(
    DATA_WIDTH   => DATA_WIDTH,
    ADDR_WIDTH   => ADDR_WIDTH,
    NUM_CHANNELS => NUM_CHANNELS,
    NUM_UNITS    => 1,
    SCALE_SHIFT  => SCALE_SHIFT
  )
  port map(
    i_CLK            => i_CLK,
    i_CLR            => i_CLR,
    i_PIX            => i_PIX,
    i_WEIGHT         => w_WEIGHT,
    i_REG_PIX_ENA    => w_REG_PIX_ENA,
    i_REG_WEIGHT_ENA => w_REG_WEIGHT_ENA,
    i_BIAS_SCALE     => w_BIAS_SCALE,
    i_REG_BIAS_ADDR  => w_BIAS_READ_ADDR, -- leitura e escrita 
    i_REG_BIAS_ENA   => w_REG_BIAS_ENA,
    i_ACC_ENA        => w_ACC_ENA,
    i_ACC_CLR        => w_ACC_CLR,
    i_REG_OUT_ENA    => w_REG_OUT_ENA,
    i_REG_OUT_ADDR   => w_REG_OUT_ADDR,
    o_PIX            => o_PIX
  );

  w_WEIGHT(0) <= w_ROM_OUT;

end arch;
