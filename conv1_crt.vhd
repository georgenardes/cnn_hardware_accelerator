-- Bloco de controle da CONV1

------------------------
-- Cx3 buffers de entrada 
-- MxC Nucleos convolucionais
-- Arvore de somadores
-- Reg
-- Relu
-- Mx1 buffers de saída
library ieee;
use ieee.std_logic_1164.all;
use ieee.STD_LOGIC_UNSIGNED.all;
use ieee.numeric_std.all;
library work;
use work.types_pkg.all;

entity conv1_crt is
  generic (
    H                     : integer          := 34; -- iFMAP Height 
    W                     : integer          := 26; -- iFMAP Width 
    C                     : integer          := 3;  -- iFMAP Chanels (filter Chanels also)
    R                     : integer          := 3;  -- filter Height 
    S                     : integer          := 3;  -- filter Width     
    M                     : integer          := 6;  -- Number of filters (oFMAP Chanels also)    
    DATA_WIDTH            : integer          := 8;
    ADDR_WIDTH            : integer          := 10;
    NC_SEL_WIDTH          : integer          := 2;        -- largura de bits para selecionar saidas dos NCs de cada filtro
    NC_ADDRESS_WIDTH      : integer          := 2;        -- numero de bits para enderecar NCs 
    WEIGHT_ADDRESS_WIDTH  : integer          := 8;        -- numero de bits para enderecar pesos
    BIAS_ADDRESS_WIDTH    : integer          := 5;        -- numero de bits para enderecar registradores de bias e scales    
    NUM_WEIGHT_FILTER_CHA : std_logic_vector := "1000";   -- quantidade de peso por filtro por canal(R*S) (de 0 a 8)
    LAST_WEIGHT           : std_logic_vector := "11011";  -- quantidade de pesos (27) !! QUANTIDADE PESOS POR FILTRO (R*S*C) !!
    LAST_BIAS             : std_logic_vector := "10";     -- 1 bias e um scale
    LAST_ROW              : std_logic_vector := "100010"; -- 34 (0 a 33 = 34 pixels) (pixels de pad)
    LAST_COL              : std_logic_vector := "11010";  -- 26 (0 a 25 = 26 pixels) (2 pixels de pad)
    OUT_SEL_WIDTH         : integer          := 3         -- largura de bits para selecionar buffers de saida     
  );

  port (
    i_CLK   : in std_logic;
    i_CLR   : in std_logic;
    i_GO    : in std_logic;  -- inicia maq
    o_READY : out std_logic; -- fim maq

    ---------------------------------
    -- sinais para buffers de entrada
    ---------------------------------
    -- habilita leitura
    o_IN_READ_ENA : out std_logic := '0';
    -- enderecos a serem lidos
    o_IN_READ_ADDR0 : out std_logic_vector (ADDR_WIDTH - 1 downto 0);
    o_IN_READ_ADDR1 : out std_logic_vector (ADDR_WIDTH - 1 downto 0);
    o_IN_READ_ADDR2 : out std_logic_vector (ADDR_WIDTH - 1 downto 0);
    ---------------------------------
    ---------------------------------

    -- sinal para rom de pesos
    o_WEIGHT_READ_ENA  : out std_logic;
    o_WEIGHT_READ_ADDR : out std_logic_vector(WEIGHT_ADDRESS_WIDTH - 1 downto 0); -- bits para enderecamento ROM de pesos

    -- SINAL PARA ROM DE BIAS E SCALES
    o_BIAS_READ_ADDR : out std_logic_vector (BIAS_ADDRESS_WIDTH - 1 downto 0);
    o_BIAS_READ_ENA  : out std_logic;

    -- habilita escrita nos registradores de bias e scale
    o_BIAS_WRITE_ENA  : out std_logic;
    o_SCALE_WRITE_ENA : out std_logic;
    ---------------------------------
    -- sinais para núcleos convolucionais
    ---------------------------------
    -- habilita deslocamento dos registradores de pixels e pesos
    o_PIX_SHIFT_ENA    : out std_logic;
    o_WEIGHT_SHIFT_ENA : out std_logic;

    -- endereco do NC para carregar pesos     
    o_NC_ADDR : out std_logic_vector(NC_ADDRESS_WIDTH - 1 downto 0);

    -- seleciona linha dos registradores de deslocamento
    o_WEIGHT_ROW_SEL : out std_logic_vector(1 downto 0);

    -- seleciona saida de NCs
    o_NC_O_SEL : out std_logic_vector(NC_SEL_WIDTH - 1 downto 0);
    -- habilita acumulador de pixels de saida dos NCs
    o_ACC_ENA : out std_logic;
    -- reseta acumulador de pixels de saida dos NCs
    o_ACC_RST : out std_logic;

    -- seleciona configuração de conexao entre buffer e registradores de deslocamento
    o_ROW_SEL : out std_logic_vector(1 downto 0);
    ---------------------------------
    ---------------------------------

    ---------------------------------
    -- sinais para buffers de saida
    ---------------------------------
    -- seleciona buffers de saida
    o_OUT_SEL : out std_logic_vector(OUT_SEL_WIDTH - 1 downto 0) := (others => '0');
    -- habilita escrita buffer de saida
    o_OUT_WRITE_ENA : out std_logic;
    -- incrementa endereco de saida
    o_OUT_INC_ADDR : out std_logic;
    -- reset endreco de saida
    o_OUT_CLR_ADDR : out std_logic
    ---------------------------------
    ---------------------------------

  );
end conv1_crt;

architecture arch of conv1_crt is
  type t_STATE is (
    s_IDLE, -- IDLE

    s_WEIGHT_VERIFY_ADDR, -- verifica endereco ROM pesos
    s_WEIGHT_READ_ENA,    -- habilita leitura pesos
    s_WEIGHT_WRITE_ENA,   -- habilita escrita pesos
    s_WEIGHT_INC_ADDR,    -- incrementa endereco de pesos
    s_BIAS_VERIFY_ADDR,   -- verifica endereco ROM BIAS E SCALE
    s_BIAS_READ_ENA,      -- habilita leitura BIAS
    s_BIAS_WRITE_ENA,     -- habilita escrita BIAS
    s_BIAS_INC_ADDR,      -- incrementa endereco de BIAS

    s_LOAD_PIX, -- carrega pixels    
    s_REG_PIX,  -- registra pixels

    s_REG_OUT_NC,  -- registra saida dos blocos NCs
    s_ACC_FIL_CH,  -- Acumula sequencialmente os canais de um filtro
    s_WRITE_OUT,   -- escreve nos blocos de saída o resultado da acumulação
    s_RIGHT_SHIFT, -- realiza deslocamento à direita
    s_LAST_COL,    -- verifica fim de linha (ultima coluna)
    s_DOWN_SHIFT,  -- realiza deslocamento a baixo
    s_LAST_ROW,    -- verifica fim de coluna (ultima linha)  

    s_INC_SEL_OUT, -- incrementa selecionador de buffer se siada
    s_LAST_OBUFF,  -- verifica se chegou num out buffer+1

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

  -- offset para endereco de buffer de entrada
  signal r_ADDR0_OFF                    : std_logic_vector (ADDR_WIDTH - 1 downto 0);
  signal w_INC_IN_ADDR0, w_RST_IN_ADDR0 : std_logic;

  signal r_ADDR1_OFF                    : std_logic_vector (ADDR_WIDTH - 1 downto 0);
  signal w_INC_IN_ADDR1, w_RST_IN_ADDR1 : std_logic;

  signal r_ADDR2_OFF                    : std_logic_vector (ADDR_WIDTH - 1 downto 0);
  signal w_INC_IN_ADDR2, w_RST_IN_ADDR2 : std_logic;
  -----------------------------------------------------------------------

  -- conta clocks para registrar pixels de entrada
  signal r_CNT_REG_PIX     : std_logic_vector (1 downto 0) := (others => '0');
  signal w_INC_CNT_REG_PIX : std_logic;
  signal W_CNT_REG_PIX_RST : std_logic;

  -- seleciona saida de NCs
  signal r_NC_O_SEL     : std_logic_vector(NC_SEL_WIDTH - 1 downto 0) := (others => '0');
  signal w_NC_O_SEL_INC : std_logic;
  signal w_NC_O_SEL_RST : std_logic;

  -- seleciona configuração de conexao entre buffer e registradores de deslocamento
  signal r_ROW_SEL     : std_logic_vector(1 downto 0);
  signal W_ROW_SEL_RST : std_logic;
  signal W_ROW_SEL_INC : std_logic;
  -- contador de colunas
  -- default 3 colunas pois inicia a contagem a partir das 3 primeiras colunas
  signal r_CNT_COL     : std_logic_vector(4 downto 0) := "00010"; -- max 2^5-1 = 31 colunas 
  signal w_INC_COL_CNT : std_logic;
  signal w_RST_COL_CNT : std_logic;
  signal w_END_COL     : std_logic;

  -- contador de linhas
  -- default 3 linhas pois inicia a contagem a partir das 3 primeiras linhas
  signal r_CNT_ROW     : std_logic_vector(5 downto 0) := "000010"; -- max 2^6-1 = 63 linhas 
  signal w_INC_ROW_CNT : std_logic;
  signal w_RST_ROW_CNT : std_logic;
  signal w_END_ROW     : std_logic;
  -- enderecamento dos pesos
  signal r_WEIGHT_ADDR     : std_logic_vector(WEIGHT_ADDRESS_WIDTH - 1 downto 0); -- ENDEREÇA OS PESOS NA ROM
  signal r_WEIGHT_CNTR     : std_logic_vector(WEIGHT_ADDRESS_WIDTH - 1 downto 0); -- CONTA OS PESOS CARREGADOS
  signal w_RST_WEIGHT_ADDR : std_logic;
  signal w_INC_WEIGHT_ADDR : std_logic;
  signal w_RST_WEIGHT_CNTR : std_logic;

  -- conta pesos por filtro
  signal r_NUM_WEIGHT_FILTER : std_logic_vector(4 downto 0); -- maximo 32 pesos por filtro por canal
  signal w_RST_NUM_WEIGHT    : std_logic;
  signal w_INC_NUM_WEIGHT    : std_logic;

  -- seleciona linha dos registradores de deslocamento
  signal r_WEIGHT_ROW_CNTR     : std_logic_vector(1 downto 0);
  signal r_WEIGHT_COL_CNTR     : std_logic_vector(1 downto 0);
  signal w_RST_WEIGHT_COL_CNTR : std_logic;
  signal w_INC_WEIGHT_COL_CNTR : std_logic;
  signal w_RST_WEIGHT_ROW_CNTR : std_logic;
  signal w_INC_WEIGHT_ROW_CNTR : std_logic;

  -- enderecamento dos bias e scales 
  signal r_BIAS_ADDR, r_BIAS_CNTR         : std_logic_vector(BIAS_ADDRESS_WIDTH - 1 downto 0);
  signal w_RST_BIAS_ADDR, w_INC_BIAS_ADDR : std_logic;
  signal w_RST_BIAS_CNTR, w_INC_BIAS_CNTR : std_logic;

  -- endereco do NC para carregar pesos     
  signal r_NC_ADDR                          : std_logic_vector(NC_ADDRESS_WIDTH - 1 downto 0) := (others => '0');
  signal w_RST_NC_ADDRESS, w_INC_NC_ADDRESS : std_logic;

  -- sinais para contador de buffer de saida 
  signal r_OUT_SEL                    : std_logic_vector(OUT_SEL_WIDTH - 1 downto 0) := (others => '0');
  signal w_RST_OUT_SEL, w_INC_OUT_SEL : std_logic;

  -- valor maximo para NC
  constant c_NC_MAX : std_logic_vector(NC_SEL_WIDTH - 1 downto 0) := std_logic_vector(to_unsigned(C, NC_SEL_WIDTH));

begin

  p_STATE : process (i_CLK, i_CLR)
  begin
    if (i_CLR = '1') then
      r_STATE <= s_IDLE; --initial state
    elsif (rising_edge(i_CLK)) then
      r_STATE <= w_NEXT; --next state
    end if;
  end process;
  p_NEXT : process (r_STATE, i_GO, r_WEIGHT_CNTR, r_BIAS_CNTR, r_OUT_SEL, r_CNT_REG_PIX, r_NC_O_SEL, w_END_COL, w_END_ROW)
  begin
    case (r_STATE) is
      when s_IDLE => -- aguarda sinal go                 
        if (i_GO = '1') then
          w_NEXT <= s_WEIGHT_READ_ENA;
        else
          w_NEXT <= s_IDLE;
        end if;

      when s_WEIGHT_READ_ENA => -- habilita leitura de pesos
        w_NEXT <= s_WEIGHT_WRITE_ENA;

      when s_WEIGHT_WRITE_ENA => -- habilita escrita de pesos
        w_NEXT <= s_WEIGHT_INC_ADDR;

      when s_WEIGHT_INC_ADDR => -- incrementa contador pesos
        w_NEXT <= s_WEIGHT_VERIFY_ADDR;

      when s_WEIGHT_VERIFY_ADDR => -- verifica endereco de pesos
        if (r_WEIGHT_CNTR < LAST_WEIGHT) then
          w_NEXT <= s_WEIGHT_READ_ENA;
        else
          w_NEXT <= s_BIAS_READ_ENA;
        end if;

      when s_BIAS_READ_ENA => -- havilita leitura de BIAS
        w_NEXT <= s_BIAS_WRITE_ENA;

      when s_BIAS_WRITE_ENA => -- havilita escrita de BIAS
        w_NEXT <= s_BIAS_INC_ADDR;

      when s_BIAS_INC_ADDR => -- incrementa contgador BIAS
        w_NEXT <= s_BIAS_VERIFY_ADDR;

      when s_BIAS_VERIFY_ADDR => -- verifica endereco de BIAS
        if (r_BIAS_CNTR < LAST_BIAS) then
          w_NEXT <= s_BIAS_READ_ENA;
        else
          w_NEXT <= s_LOAD_PIX;
        end if;
      when s_LOAD_PIX => -- habilita leitura pixel de entrada
        w_NEXT <= s_REG_PIX;

      when s_REG_PIX => -- registra pixel de entrada
        if (r_CNT_REG_PIX = "11") then
          w_NEXT <= s_REG_OUT_NC;
        else
          w_NEXT <= s_LOAD_PIX;
        end if;

      when s_REG_OUT_NC => -- registra saida
        w_NEXT <= s_ACC_FIL_CH;

      when s_ACC_FIL_CH =>            -- acumula canais de um filtro
        if (r_NC_O_SEL = c_NC_MAX) then -- enquanto < C
          w_NEXT <= s_WRITE_OUT;
        else
          w_NEXT <= s_ACC_FIL_CH;
        end if;

      when s_WRITE_OUT => -- salva no bloco de saida
        w_NEXT <= s_RIGHT_SHIFT;

      when s_RIGHT_SHIFT => -- deslocamento à direita
        w_NEXT <= s_LAST_COL;

      when s_LAST_COL => -- verifica fim colunas
        if (w_END_COL = '1') then
          w_NEXT <= s_DOWN_SHIFT;
        else
          w_NEXT <= s_REG_OUT_NC;
        end if;

      when s_DOWN_SHIFT => -- deslocamento à baixo
        w_NEXT <= s_LAST_ROW;

      when s_LAST_ROW => -- verifica fim linhas
        if (w_END_ROW = '1') then
          w_NEXT <= s_INC_SEL_OUT;
        else
          w_NEXT <= s_LOAD_PIX;
        end if;

      when s_INC_SEL_OUT => -- incrementa selecionador de buffer
        w_NEXT <= s_LAST_OBUFF;

      when s_LAST_OBUFF => -- verificar se selecionador atingiu valor max
        if (r_OUT_SEL = std_logic_vector(to_unsigned(M, OUT_SEL_WIDTH))) then
          w_NEXT <= s_END;
        else
          w_NEXT <= s_WEIGHT_VERIFY_ADDR;
        end if;

      when s_END => -- fim
        w_NEXT <= s_IDLE;

      when others =>
        w_NEXT <= s_IDLE;

    end case;
  end process;

  -----------------------------------------------------------------------
  -- sinais para buffers de entrada
  ---------------------------------  
  w_INC_IN_ADDR <= '1' when (r_STATE = s_LOAD_PIX or r_STATE = s_RIGHT_SHIFT) else
    '0';
  w_RST_IN_ADDR <= '1' when (i_CLR = '1' or w_END_COL = '1') else
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
  -- OBS.: como offset_addr é diferente de 1 os primeiros bits serão sempre 0
  -- log de output diz que foi inferido latch, porém o RTL não apresenta latch
  -- offset para endereco de buffer de entrada
  w_INC_IN_ADDR0 <= '1' when (r_ROW_SEL = "00" and r_STATE = s_DOWN_SHIFT) else
    '0';
  w_INC_IN_ADDR1 <= '1' when (r_ROW_SEL = "01" and r_STATE = s_DOWN_SHIFT) else
    '0';
  w_INC_IN_ADDR2 <= '1' when (r_ROW_SEL = "10" and r_STATE = s_DOWN_SHIFT) else
    '0';

  w_RST_IN_ADDR0 <= '1' when (r_STATE = s_INC_SEL_OUT or i_CLR = '1') else
    '0';
  w_RST_IN_ADDR1 <= w_RST_IN_ADDR0;
  w_RST_IN_ADDR2 <= w_RST_IN_ADDR0;

  u_ADDR0_OFFSET : counter
  generic map(ADDR_WIDTH, W)
  port map(
    i_CLK   => i_CLK,
    i_RESET => w_RST_IN_ADDR0,
    i_INC   => w_INC_IN_ADDR0,
    i_RESET_VAL => (others => '0'),
    o_Q     => r_ADDR0_OFF
  );
  u_ADDR1_OFFSET : counter
  generic map(ADDR_WIDTH, W)
  port map(
    i_CLK   => i_CLK,
    i_RESET => w_RST_IN_ADDR1,
    i_INC   => w_INC_IN_ADDR1,
    i_RESET_VAL => (others => '0'),
    o_Q     => r_ADDR1_OFF
  );
  u_ADDR2_OFFSET : counter
  generic map(ADDR_WIDTH, W)
  port map(
    i_CLK   => i_CLK,
    i_RESET => w_RST_IN_ADDR2,
    i_INC   => w_INC_IN_ADDR2,
    i_RESET_VAL => (others => '0'),
    o_Q     => r_ADDR2_OFF
  );
  o_IN_READ_ENA <= '1' when (r_STATE = s_LOAD_PIX or r_STATE = s_RIGHT_SHIFT) else
    '0';
  o_IN_READ_ADDR0 <= w_IN_READ_ADDR + r_ADDR0_OFF;
  o_IN_READ_ADDR1 <= w_IN_READ_ADDR + r_ADDR1_OFF;
  o_IN_READ_ADDR2 <= w_IN_READ_ADDR + r_ADDR2_OFF;
  -----------------------------------------------------------------------    
  ---------------------------------

  ---------------------------------
  -- sinais para nucleos convolucionais
  ---------------------------------    
  -- seleciona configuração de conexao entre buffer e registradores de deslocamento
  W_ROW_SEL_RST <= '1' when (i_CLR = '1' or r_STATE = s_IDLE or r_ROW_SEL = "11" or r_STATE = s_INC_SEL_OUT) else
    '0';
  W_ROW_SEL_INC <= '1' when (r_STATE = s_DOWN_SHIFT) else
    '0';
  u_ROW_SEL : counter
  generic map(2, 1)
  port map(
    i_CLK   => i_CLK,
    i_RESET => W_ROW_SEL_RST,
    i_INC   => W_ROW_SEL_INC,
    i_RESET_VAL => (others => '0'),
    o_Q     => r_ROW_SEL
  );
  o_ROW_SEL <= r_ROW_SEL;
  -- habilita sinal para incrementar contador de deslocamento dos 3 pixels iniciais
  w_INC_CNT_REG_PIX <= '1' when (r_STATE = s_LOAD_PIX) else
    '0';
  W_CNT_REG_PIX_RST <= '1' when (i_CLR = '1' or r_STATE = s_IDLE or r_STATE = s_REG_OUT_NC) else
    '0';
  u_CNT_REG_PIX : counter
  generic map(2, 1)
  port map(
    i_CLK   => i_CLK,
    i_RESET => W_CNT_REG_PIX_RST,
    i_INC   => w_INC_CNT_REG_PIX,
    i_RESET_VAL => (others => '0'),
    o_Q     => r_CNT_REG_PIX
  );

  o_PIX_SHIFT_ENA <= '1' when (r_STATE = s_REG_PIX or r_STATE = s_RIGHT_SHIFT) else
    '0';
  ---------------------------------

  ---------------------------------
  -- sinais para multiplexadores
  ---------------------------------

  -- seleciona saida de NCs  
  w_NC_O_SEL_INC <= '1' when (r_STATE = s_ACC_FIL_CH) else
    '0';
  w_NC_O_SEL_RST <= '1' when (i_CLR = '1' or r_STATE = s_IDLE or r_STATE = s_RIGHT_SHIFT) else
    '0';
  u_NC_O_SEL : counter
  generic map(NC_SEL_WIDTH, 1)
  port map(
    i_CLK   => i_CLK,
    i_RESET => w_NC_O_SEL_RST,
    i_INC   => w_NC_O_SEL_INC,
    i_RESET_VAL => (others => '0'),
    o_Q     => r_NC_O_SEL
  );
  o_NC_O_SEL <= r_NC_O_SEL;

  -- habilita acumulador de pixels de saida dos NCs
  o_ACC_ENA <= w_NC_O_SEL_INC;
  -- reseta acumulador de pixels de saida dos NCs
  o_ACC_RST <= w_NC_O_SEL_RST;
  ---------------------------------

  ---------------------------------
  -- sinais para buffers de saida
  ---------------------------------    
  -- habilita escrita buffer de saida
  o_OUT_WRITE_ENA <= '1' when (r_STATE = s_WRITE_OUT) else
    '0';
  -- incrementa endereco de saida
  o_OUT_INC_ADDR <= '1' when (r_STATE = s_WRITE_OUT) else
    '0';
  -- reset endreco de saida
  o_OUT_CLR_ADDR <= '1' when (r_STATE = s_IDLE or r_STATE = s_INC_SEL_OUT) else
    '0';
  ---------------------------------
  ---------------------------------
  -- Sinais para deslocamento a direita
  ---------------------------------
  -- contador de colunas
  -- default 3 colunas pois inicia a contagem a partir das 3 primeiras colunas
  w_INC_COL_CNT <= '1' when (r_STATE = s_RIGHT_SHIFT) else
    '0';
  w_RST_COL_CNT <= '1' when (i_CLR = '1' or r_STATE = s_IDLE or r_STATE = s_DOWN_SHIFT or r_STATE = s_INC_SEL_OUT) else
    '0';
  u_CNT_COL : counter
  generic map(5, 1)
  port map(
    i_CLK       => i_CLK,
    i_RESET     => w_RST_COL_CNT,
    i_INC       => w_INC_COL_CNT,
    i_RESET_VAL => "00010",
    o_Q         => r_CNT_COL
  );

  -- fim coluna quando contador = numero de coluna 
  w_END_COL <= '1' when (r_CNT_COL = LAST_COL) else
    '0';
  ---------------------------------

  ---------------------------------
  -- Sinais para deslocamento a baixo
  ---------------------------------
  -- contador de linhas
  -- default 3 linhas pois inicia a contagem a partir das 3 primeiras linhas 
  w_INC_ROW_CNT <= '1' when (r_STATE = s_DOWN_SHIFT) else
    '0';
  w_RST_ROW_CNT <= '1' when (i_CLR = '1' or r_STATE = s_IDLE or r_STATE = s_INC_SEL_OUT) else
    '0';
  u_CNT_ROW : counter
  generic map(6, 1)
  port map(
    i_CLK       => i_CLK,
    i_RESET     => w_RST_ROW_CNT,
    i_INC       => w_INC_ROW_CNT,
    i_RESET_VAL => "000010",
    o_Q         => r_CNT_ROW
  );

  -- fim linha quando contador = numero de linha 
  w_END_ROW <= '1' when (r_CNT_ROW = LAST_ROW) else
    '0';
  ---------------------------------
  ---------------------------------

  -- enderecamento dos pesos
  w_RST_WEIGHT_ADDR <= '1' when (i_CLR = '1' or r_STATE = s_IDLE) else
    '0';
  w_INC_WEIGHT_ADDR <= '1' when (r_STATE = s_WEIGHT_INC_ADDR) else
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

  -- reseta contador de pesos
  w_RST_WEIGHT_CNTR <= '1' when (r_STATE = s_BIAS_VERIFY_ADDR) else
    '0';
  u_WEIGHT_CNTR : counter
  generic map(WEIGHT_ADDRESS_WIDTH, 1)
  port map(
    i_CLK   => i_CLK,
    i_RESET => w_RST_WEIGHT_CNTR,
    i_INC   => w_INC_WEIGHT_ADDR,
    i_RESET_VAL => (others => '0'),
    o_Q     => r_WEIGHT_CNTR
  );

  -- enderecametno do bias
  w_RST_BIAS_ADDR <= '1' when (i_CLR = '1' or r_STATE = s_IDLE) else
    '0';
  w_INC_BIAS_ADDR <= '1' when (r_BIAS_CNTR = "10" and r_STATE = s_LOAD_PIX) else
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

  w_RST_BIAS_CNTR <= '1' when (r_STATE = s_LOAD_PIX) else
    '0';
  w_INC_BIAS_CNTR <= '1' when (r_STATE = s_BIAS_INC_ADDR) else
    '0';
  u_BIAS_CNTR : counter
  generic map(BIAS_ADDRESS_WIDTH, 1)
  port map(
    i_CLK   => i_CLK,
    i_RESET => w_RST_BIAS_CNTR,
    i_INC   => w_INC_BIAS_CNTR,
    i_RESET_VAL => (others => '0'),
    o_Q     => r_BIAS_CNTR
  );
  -- reset contador pesos
  w_RST_NUM_WEIGHT <= '1' when ((r_STATE = s_WEIGHT_VERIFY_ADDR and r_NUM_WEIGHT_FILTER > NUM_WEIGHT_FILTER_CHA) or
    i_CLR = '1' or r_STATE = s_IDLE) else
    '0';
  w_INC_NUM_WEIGHT <= '1' when (r_STATE = s_WEIGHT_INC_ADDR) else
    '0';
  -- conta pesos por filtro
  u_WEIGHT_FILTER_CNTR : counter
  generic map(5, 1)
  port map(
    i_CLK   => i_CLK,
    i_RESET => w_RST_NUM_WEIGHT,
    i_INC   => w_INC_NUM_WEIGHT,
    i_RESET_VAL => (others => '0'),
    o_Q     => r_NUM_WEIGHT_FILTER
  );
  -- endereco do NC para carregar pesos  
  w_RST_NC_ADDRESS <= '1' when (i_CLR = '1' or r_STATE = s_IDLE or r_STATE = s_INC_SEL_OUT) else
    '0';
  w_INC_NC_ADDRESS <= '1' when (r_NUM_WEIGHT_FILTER = NUM_WEIGHT_FILTER_CHA and r_STATE = s_WEIGHT_INC_ADDR) else
    '0';
  u_NC_ADDRESS : counter
  generic map(NC_ADDRESS_WIDTH, 1)
  port map(
    i_CLK   => i_CLK,
    i_RESET => w_RST_NC_ADDRESS,
    i_INC   => w_INC_NC_ADDRESS,
    i_RESET_VAL => (others => '0'),
    o_Q     => r_NC_ADDR
  );
  -- reseta contador de colunas
  w_RST_WEIGHT_COL_CNTR <= '1' when (i_CLR = '1' or (r_STATE = s_WEIGHT_VERIFY_ADDR and r_WEIGHT_COL_CNTR = "11")) else
    '0';
  w_INC_WEIGHT_COL_CNTR <= '1' when (r_STATE = s_WEIGHT_INC_ADDR) else
    '0';
  -- conta colunas de pesos
  u_WEIGHT_COL_CNTR : counter
  generic map(2, 1)
  port map(
    i_CLK   => i_CLK,
    i_RESET => w_RST_WEIGHT_COL_CNTR,
    i_INC   => w_INC_WEIGHT_COL_CNTR,
    i_RESET_VAL => (others => '0'),
    o_Q     => r_WEIGHT_COL_CNTR
  );
  -- reset contador de linha
  w_RST_WEIGHT_ROW_CNTR <= '1' when ((i_CLR = '1' or r_STATE = s_IDLE) or
    (r_STATE = s_WEIGHT_VERIFY_ADDR and r_WEIGHT_ROW_CNTR = "11")) else
    '0';
  w_INC_WEIGHT_ROW_CNTR <= '1' when (r_WEIGHT_COL_CNTR = "10" and r_STATE = s_WEIGHT_INC_ADDR) else
    '0';
  -- conta linhas
  u_WEIGHT_ROW_CNTR : counter
  generic map(2, 1)
  port map(
    i_CLK   => i_CLK,
    i_RESET => w_RST_WEIGHT_ROW_CNTR,
    i_INC   => w_INC_WEIGHT_ROW_CNTR,
    i_RESET_VAL => (others => '0'),
    o_Q     => r_WEIGHT_ROW_CNTR
  );

  ---------------------------------------------------------------
  w_RST_OUT_SEL <= '1' when (r_STATE = s_IDLE) else
    '0';
  w_INC_OUT_SEL <= '1' when (r_STATE = s_INC_SEL_OUT) else
    '0';

  -- seleciona buffers de saida
  u_OUT_SEL : counter
  generic map(OUT_SEL_WIDTH, 1)
  port map(
    i_CLK   => i_CLK,
    i_RESET => w_RST_OUT_SEL,
    i_INC   => w_INC_OUT_SEL,
    i_RESET_VAL => (others => '0'),
    o_Q     => r_OUT_SEL
  );
  o_OUT_SEL <= r_OUT_SEL;

  -- sinal para rom de pesos
  o_WEIGHT_READ_ENA <= '1' when (r_STATE = s_WEIGHT_READ_ENA) else
    '0';
  o_WEIGHT_READ_ADDR <= r_WEIGHT_ADDR;
  -- SINAL PARA ROM DE BIAS E SCALES
  o_BIAS_READ_ENA <= '1' when (r_STATE = s_BIAS_READ_ENA) else
    '0';
  -- offset para scale
  o_BIAS_READ_ADDR <= r_BIAS_ADDR when (r_BIAS_CNTR = "00") else
    (r_BIAS_ADDR + std_logic_vector(to_unsigned(M, BIAS_ADDRESS_WIDTH)));

  -- habilita escrita nos registradores de bias e scale
  o_BIAS_WRITE_ENA <= '1' when (r_STATE = s_BIAS_WRITE_ENA and r_BIAS_CNTR = "00") else
    '0';
  o_SCALE_WRITE_ENA <= '1' when (r_STATE = s_BIAS_WRITE_ENA and r_BIAS_CNTR = "01") else
    '0';

  -- endereco do NC para carregar pesos     
  o_NC_ADDR <= r_NC_ADDR;

  -- seleciona linha dos registradores de deslocamento
  o_WEIGHT_ROW_SEL <= r_WEIGHT_ROW_CNTR;

  -- habilita shift dos pesos 
  o_WEIGHT_SHIFT_ENA <= '1' when (r_STATE = s_WEIGHT_WRITE_ENA) else
    '0';

  -- sinaliza fim maq estado
  o_READY <= '1' when (r_STATE = s_END) else
    '0';

end arch;
