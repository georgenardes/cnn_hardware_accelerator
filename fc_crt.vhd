-- controle FC

library ieee;
use ieee.std_logic_1164.all;
use ieee.STD_LOGIC_UNSIGNED.all;
use ieee.numeric_std.all;
library work;
use work.types_pkg.all;

entity fc_crt is
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
    i_CLK   : in std_logic;
    i_CLR   : in std_logic;
    i_GO    : in std_logic;  -- inicia maq    
    o_READY : out std_logic; -- fim maq

    -- habilita registradores de pixel e peso
    o_REG_PIX_ENA    : out std_logic;
    o_REG_WEIGHT_ENA : out std_logic;

    -- valor de bias ou scale    
    o_REG_BIAS_ENA : out std_logic;

    -- habilita acumulador
    o_ACC_ENA : out std_logic;
    o_ACC_CLR : out std_logic;

    -- habilita/clear registrador de saida
    o_REG_OUT_ENA  : out std_logic;
    o_REG_OUT_ADDR : out std_logic_vector(5 downto 0) := (others => '0');
    -- ENDERECO PARA ROM PESOS
    o_WEIGHT_READ_ADDR : out std_logic_vector(WEIGHT_ADDRESS_WIDTH - 1 downto 0);
    -- ENDERECO PARA ROM BIAS
    o_BIAS_READ_ADDR : out std_logic_vector(BIAS_ADDRESS_WIDTH - 1 downto 0);

    -- endereco pixel/peso de entrada
    o_IN_READ_ADDR : out std_logic_vector (7 downto 0)

  );
end fc_crt;

architecture arch of fc_crt is
  type t_STATE is (
    s_IDLE, -- IDLE

    s_BIAS_READ_ENA,  -- habilita leitura BIAS
    s_BIAS_WRITE_ENA, -- habilita escrita BIAS
    s_BIAS_INC_ADDR,  -- incrementa endereco de BIAS

    s_LOAD_PIX_WEIGHT, -- carrega um pixel e um peso
    s_REG_PIX,         -- registra pixels e pesos    
    s_REG_OUT_NFC,     -- registra resultado (acumulador)

    s_WRITE_OUT, -- escreve nos blocos de saída o resultado da acumulação
    s_LAST_UNIT, -- sinaliza fim do processamento de todas unidades
    -- s_RST_ADDRS, -- reseta enderecamento de pixels (acho q n precisa)

    s_LAST_FEATURE, -- verifica fim de FEATURES

    s_END -- fim
  );
  signal r_STATE : t_STATE; -- state register
  signal w_NEXT  : t_STATE; -- next state    

  -- componenbte contador para enderecaomento
  component counter is
    generic (
      DATA_WIDTH : integer := 8;
      STEP       : integer := 1
    );
    port (
      i_CLK       : in std_logic;
      i_RESET     : in std_logic;
      i_INC       : in std_logic;
      i_RESET_VAL : in std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
      o_Q         : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
  end component;
  -----------------------------------------------------------------------
  -- enderecos para cada linha de buffer de entrada
  -- a cada deslocamento a baixo o offset é incrementado
  -- o endereco é a soma entre o contador e o offset para aquele bloco
  -----------------------------------------------------------------------
  -- sinais contador para endereco de buffer de entrada    
  signal w_IN_READ_ADDR : std_logic_vector (ADDR_WIDTH - 1 downto 0);
  signal w_INC_IN_ADDR  : std_logic;
  signal w_RST_IN_ADDR  : std_logic;
  -----------------------------------------------------------------------
  -- enderecamento dos pesos
  signal r_WEIGHT_ADDR     : std_logic_vector(WEIGHT_ADDRESS_WIDTH - 1 downto 0); -- ENDEREÇA OS PESOS NA ROM
  signal w_RST_WEIGHT_ADDR : std_logic;
  signal w_INC_WEIGHT_ADDR : std_logic;
  -- enderecamento dos bias e scales 
  signal r_BIAS_ADDR                      : std_logic_vector(BIAS_ADDRESS_WIDTH - 1 downto 0);
  signal w_RST_BIAS_ADDR, w_INC_BIAS_ADDR : std_logic;
  -- ultima feature de entrada
  signal w_LAST_FEATURE : std_logic;

  signal w_LAST_UNIT : std_logic := '0';

  -- enderco de buffers de saida
  signal r_REG_OUT_ADDR                 : std_logic_vector(5 downto 0) := (others => '0');
  signal w_INC_BUFF_OUT, w_RST_BUFF_OUT : std_logic                    := '0';

begin

  p_STATE : process (i_CLK, i_CLR)
  begin
    if (i_CLR = '1') then
      r_STATE <= s_IDLE; --initial state
    elsif (rising_edge(i_CLK)) then
      r_STATE <= w_NEXT; --next state
    end if;
  end process;
  p_NEXT : process (r_STATE, i_GO, r_BIAS_ADDR, w_LAST_FEATURE, w_LAST_UNIT)
  begin
    case (r_STATE) is
      when s_IDLE => -- aguarda sinal go                 
        if (i_GO = '1') then
          w_NEXT <= s_BIAS_READ_ENA;
        else
          w_NEXT <= s_IDLE;
        end if;

      when s_BIAS_READ_ENA => -- havilita leitura de BIAS
        w_NEXT <= s_BIAS_WRITE_ENA;

      when s_BIAS_WRITE_ENA => -- havilita escrita de BIAS
        w_NEXT <= s_BIAS_INC_ADDR;

      when s_BIAS_INC_ADDR => -- incrementa contgador BIAS
        w_NEXT <= s_LOAD_PIX_WEIGHT;

      when s_LOAD_PIX_WEIGHT => -- habilita leitura pixel de entrada
        w_NEXT <= s_REG_PIX;

      when s_REG_PIX => -- registra pixel de entrada        
        w_NEXT <= s_REG_OUT_NFC;

      when s_REG_OUT_NFC => -- registra saida
        w_NEXT <= s_LAST_FEATURE;

      when s_LAST_FEATURE => -- verifica fim linhas
        if (w_LAST_FEATURE = '1') then
          w_NEXT <= s_WRITE_OUT;
        else
          w_NEXT <= s_LOAD_PIX_WEIGHT;
        end if;

      when s_WRITE_OUT =>
        w_NEXT <= s_LAST_UNIT;

      when s_LAST_UNIT =>
        if (w_LAST_UNIT = '1') then
          w_NEXT <= s_END;
        else
          w_NEXT <= s_BIAS_READ_ENA;
        end if;

      when s_END => -- fim
        w_NEXT <= s_IDLE;

      when others =>
        w_NEXT <= s_IDLE;

    end case;
  end process;

  --- sinais para ROM de pesos, bias e scale/ cache de pesos, registradores de bias e scale
  -- enderecametno do bias
  w_RST_BIAS_ADDR <= '1' when (i_CLR = '1' or r_STATE = s_IDLE) else
    '0';
  w_INC_BIAS_ADDR <= '1' when (r_STATE = s_BIAS_INC_ADDR) else
    '0';
  u_BIAS_ADDR : counter
  generic map(BIAS_ADDRESS_WIDTH, 1)
  port map(
    i_CLK   => i_CLK,
    i_RESET => w_RST_BIAS_ADDR,
    i_INC   => w_INC_BIAS_ADDR,
    i_RESET_VAL => (others => '0'),
    o_Q     => r_BIAS_ADDR
  );
  -- ENDERECO PARA ROM BIAS
  o_BIAS_READ_ADDR <= r_BIAS_ADDR;

  -- sinaliza quando contador chegar a 34
  w_LAST_UNIT <= '1' when (r_BIAS_ADDR = "100010") else
    '0'; -- 0 to 34 

  -- habilita registradores de scale e bias
  o_REG_BIAS_ENA <= '1' when (r_STATE = s_BIAS_WRITE_ENA) else
    '0';

  -- sinais durante processamento       
  -- enderecamento dos pesos
  w_RST_WEIGHT_ADDR <= '1' when (i_CLR = '1' or r_STATE = s_IDLE) else
    '0';
  w_INC_WEIGHT_ADDR <= '1' when (r_STATE = s_REG_PIX) else
    '0';
  u_WEIGHT_ADDR : counter
  generic map(WEIGHT_ADDRESS_WIDTH, 1)
  port map(
    i_CLK   => i_CLK,
    i_RESET => w_RST_WEIGHT_ADDR,
    i_INC   => w_INC_WEIGHT_ADDR,
    i_RESET_VAL => (others => '0'),
    o_Q     => r_WEIGHT_ADDR
  );
  -- ENDERECO PARA ROM PESOS
  o_WEIGHT_READ_ADDR <= r_WEIGHT_ADDR;
  ---------------------------------
  -- sinais para buffers de entrada
  ---------------------------------  
  w_INC_IN_ADDR <= '1' when (r_STATE = s_REG_PIX) else
    '0';
  w_RST_IN_ADDR <= '1' when (i_CLR = '1' or r_STATE = s_IDLE) else
    '0';
  -- contador de endereco
  u_INPUT_ADDR : counter
  generic map(ADDR_WIDTH, 1)
  port map(
    i_CLK   => i_CLK,
    i_RESET => w_RST_IN_ADDR,
    i_INC   => w_INC_IN_ADDR,
    i_RESET_VAL => (others => '0'),
    o_Q     => w_IN_READ_ADDR
  );
  -- endereco pixel e o peso de entrada       
  o_IN_READ_ADDR <= w_IN_READ_ADDR;

  w_LAST_FEATURE <= '1' when (w_IN_READ_ADDR = LAST_FEATURE) else
    '0';

  -- sinais de inc/rst
  w_INC_BUFF_OUT <= '1' when (r_STATE = s_LAST_UNIT) else
    '0';
  w_RST_BUFF_OUT <= '1' when (r_STATE = s_IDLE) else
    '0';

  -- endereco buffer saida
  u_REG_OUT_ADDR : counter
  generic map(6, 1)
  port map(
    i_CLK   => i_CLK,
    i_RESET => w_INC_BUFF_OUT,
    i_INC   => w_RST_BUFF_OUT,
    i_RESET_VAL => (others => '0'),
    o_Q     => r_REG_OUT_ADDR
  );
  o_REG_OUT_ADDR <= r_REG_OUT_ADDR;
  ---------------------------------
  ---------------------------------
  -- habilita registradores de pixel e peso
  o_REG_PIX_ENA <= '1' when (r_STATE = s_REG_PIX) else
    '0';
  o_REG_WEIGHT_ENA <= '1' when (r_STATE = s_REG_PIX) else
    '0';
  -- habilita acumulador
  o_ACC_ENA <= '1' when (r_STATE = s_REG_OUT_NFC) else
    '0';
  o_ACC_CLR <= '1' when (r_STATE = s_IDLE) else
    '0';

  -- habilita/clear registrador de saida
  o_REG_OUT_ENA <= '1' when (r_STATE = s_WRITE_OUT) else
    '0';
  -- sinaliza fim do processamento
  o_READY <= '1' when (r_STATE = s_END) else
    '0';
end arch;
