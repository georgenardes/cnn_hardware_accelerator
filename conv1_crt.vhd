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
library work;
use work.conv1_pkg.all;
use work.types_pkg.all;

entity conv1_crt is
  generic (
    H : integer := 34; -- iFMAP Height 
    W : integer := 26; -- iFMAP Width 
    C : integer := 3; -- iFMAP Chanels (filter Chanels also)
    R : integer := 3; -- filter Height 
    S : integer := 3; -- filter Width     
    M : integer := 6; -- Number of filters (oFMAP Chanels also)    
    DATA_WIDTH : integer := 8;
    ADDR_WIDTH : integer := 10;    
    OFFSET_ADDR : std_logic_vector := "0000011001"; -- 25dec
    NUM_PES_FILTER_CHA : std_logic_vector := "1000"; -- quantidade de peso por filtro por canal(R*S) (de 0 a 8)
    LAST_PES : std_logic_vector := "10100010"; -- quantidade de pesos (162)
    LAST_BIAS : std_logic_vector := "1100"; -- quantidade de bias e scale (12)    
    LAST_ROW : std_logic_vector := "100001"; -- 34 (0 a 33 = 34 pixels) (pixels de pad)
    LAST_COL : std_logic_vector := "11001"   -- 26 (0 a 25 = 26 pixels) (2 pixels de pad)
  );

  port (
    i_CLK           : in  std_logic;
    i_CLR           : in  std_logic;
    i_GO            : in  std_logic; -- inicia maq
    i_LOAD          : in  std_logic; -- carrega pesos
    o_READY         : out std_logic; -- fim maq
    
    ---------------------------------
    -- sinais para buffers de entrada
    ---------------------------------
    -- habilita leitura
    o_IN_READ_ENA   : out  std_logic;
    -- enderecos a serem lidos
    o_IN_READ_ADDR0 : out std_logic_vector (ADDR_WIDTH - 1 downto 0);
    o_IN_READ_ADDR1 : out std_logic_vector (ADDR_WIDTH - 1 downto 0);
    o_IN_READ_ADDR2 : out std_logic_vector (ADDR_WIDTH - 1 downto 0); 
    ---------------------------------
    ---------------------------------
    
    -- sinal para rom de pesos
    o_PES_READ_ENA  : out std_logic; 
    o_PES_READ_ADDR : out std_logic_vector(7 downto 0);  -- bits para enderecamento ROM de pesos
    
    -- SINAL PARA ROM DE BIAS E SCALES
    o_BIAS_READ_ADDR : out STD_LOGIC_VECTOR (4 DOWNTO 0);
    o_BIAS_READ_ENA  : out std_logic; 
    
    -- habilita escrita nos registradores de bias e scale
    o_BIAS_WRITE_ENA :  out std_logic;
    o_SCALE_WRITE_ENA : out std_logic;
    
    
    ---------------------------------
    -- sinais para núcleos convolucionais
    ---------------------------------
    -- habilita deslocamento dos registradores de pixels e pesos
    o_PIX_SHIFT_ENA : out  std_logic;
    o_PES_SHIFT_ENA : out  std_logic;
    
    -- endereco do NC para carregar pesos     
    o_NC_ADDR : out std_logic_vector(c_NC-1 downto 0);    
    
    -- seleciona linha dos registradores de deslocamento
    o_PES_ROW_SEL : out std_logic_vector(1 downto 0);

    -- seleciona saida de NCs
    o_NC_O_SEL      : out  std_logic_vector(c_NC_SEL_WIDHT - 1 downto 0);
    -- habilita acumulador de pixels de saida dos NCs
    o_ACC_ENA       : out  std_logic;
    -- reseta acumulador de pixels de saida dos NCs
    o_ACC_RST       : out std_logic;
    
    -- seleciona configuração de conexao entre buffer e registradores de deslocamento
    o_ROW_SEL       : out std_logic_vector(1 downto 0); 
    ---------------------------------
    ---------------------------------
    
    ---------------------------------
    -- sinais para buffers de saida
    ---------------------------------
    -- habilita escrita buffer de saida
    o_OUT_WRITE_ENA : out  std_logic;
    -- incrementa endereco de saida
    o_OUT_INC_ADDR  : out  std_logic; 
    -- reset endreco de saida
    o_OUT_CLR_ADDR : out std_logic
    ---------------------------------
    ---------------------------------

  );
end conv1_crt;

architecture arch of conv1_crt is
  type t_STATE is (
    s_IDLE, -- IDLE
    
    s_PES_VERIFY_ADDR, -- verifica endereco ROM pesos
    s_PES_READ_ENA, -- habilita leitura pesos
    s_PES_WRITE_ENA, -- habilita escrita pesos
    s_PES_INC_ADDR, -- incrementa endereco de pesos
    s_BIAS_VERIFY_ADDR, -- verifica endereco ROM BIAS E SCALE
    s_BIAS_READ_ENA, -- habilita leitura BIAS
    s_BIAS_WRITE_ENA, -- habilita escrita BIAS
    s_BIAS_INC_ADDR, -- incrementa endereco de BIAS
    
    s_LOAD_PIX, -- LOAD pixels    
    s_REG_OUT_NC, -- registra saida dos blocos NCs
    s_ACC_FIL_CH, -- Acumula sequencialmente os canais de um filtro
    s_WRITE_OUT, -- escreve nos blocos de saída o resultado da acumulação
    s_RIGHT_SHIFT, -- realiza deslocamento à direita
    s_LAST_COL, -- verifica fim de linha (ultima coluna)
    s_DOWN_SHIFT, -- realiza deslocamento a baixo
    s_LAST_ROW, -- verifica fim de coluna (ultima linha)    
    s_END -- fim
  );
  signal r_STATE : t_STATE; -- state register
  signal w_NEXT : t_STATE; -- next state    
  
  -----------------------------------------------------------------------
  -- enderecos para cada linha de buffer de entrada
  -- a cada deslocamento a baixo o offset é incrementado
  -- o endereco é a soma entre o contador e o offset para aquele bloco
  -----------------------------------------------------------------------
  -- sinais contador para endereco de buffer de entrada  
  signal w_IN_READ_ADDR : std_logic_vector (ADDR_WIDTH - 1 downto 0);
  signal w_INC_IN_ADDR : std_logic; 
  signal w_RST_IN_ADDR : std_logic;
  
  -- offset para endereco de buffer de entrada
  signal r_ADDR0_OFF : std_logic_vector (ADDR_WIDTH - 1 downto 0);
  signal w_INC_IN_ADDR0 : std_logic;
  
  signal r_ADDR1_OFF : std_logic_vector (ADDR_WIDTH - 1 downto 0);
  signal w_INC_IN_ADDR1 : std_logic;
  
  signal r_ADDR2_OFF : std_logic_vector (ADDR_WIDTH - 1 downto 0); 
  signal w_INC_IN_ADDR2 : std_logic;
  -----------------------------------------------------------------------
  
  -- conta clocks para registrar pixels de entrada
  signal r_CNT_REG_PIX : std_logic_vector (1 downto 0) := (others => '0');
  signal w_INC_CNT_REG_PIX : std_logic;
  signal W_CNT_REG_PIX_RST : std_logic;
  
  -- seleciona saida de NCs
  signal r_NC_O_SEL : std_logic_vector(c_NC_SEL_WIDHT - 1 downto 0) := (others => '0');
  signal w_NC_O_SEL_INC : std_logic; 
  signal w_NC_O_SEL_RST : std_logic;
  
  -- habilita acumulador de pixels de saida dos NCs
  signal w_ACC_ENA  : std_logic;
  
  -- seleciona configuração de conexao entre buffer e registradores de deslocamento
  signal r_ROW_SEL : std_logic_vector(1 downto 0); 
  signal W_ROW_SEL_RST : std_logic;
  signal W_ROW_SEL_INC : std_logic; 
  
  
  -- contador de colunas
  -- default 3 colunas pois inicia a contagem a partir das 3 primeiras colunas
  signal r_CNT_COL : std_logic_vector(4 downto 0) := "00011"; -- max 2^5-1 = 31 colunas 
  signal w_INC_COL_CNT : std_logic;
  signal w_RST_COL_CNT : std_logic;
  signal w_END_COL : std_logic;
  
  -- contador de linhas
  -- default 3 linhas pois inicia a contagem a partir das 3 primeiras linhas
  signal r_CNT_ROW : std_logic_vector(5 downto 0) := "000011"; -- max 2^6-1 = 63 linhas 
  signal w_INC_ROW_CNT : std_logic;
  signal w_RST_ROW_CNT : std_logic;
  signal w_END_ROW : std_logic;
  
  
  -- enderecamento dos pesos
  signal r_PES_ADDR : std_logic_vector(7 downto 0);    
  -- conta pesos por filtro
  signal r_NUM_PES_FILTER : std_logic_vector(4 downto 0);
  signal w_RST_NUM_PES : std_logic;
  
  -- seleciona linha dos registradores de deslocamento
  signal r_PES_ROW_CNTR : std_logic_vector(1 downto 0);
  signal r_PES_COL_CNTR : std_logic_vector(1 downto 0);
  signal w_RST_PES_ROW_CNTR : std_logic;
  signal w_RST_PES_COL_CNTR : std_logic;
  
  -- enderecamento dos bias e scales (32 enderecos)
  signal r_BIAS_ADDR : std_logic_vector(4 downto 0);
        
  -- endereco do NC para carregar pesos     
  signal r_NC_ADDR : std_logic_vector(c_NC-1 downto 0);    
  
  -- componenbte contador para enderecaomento
  component counter is
    generic 
    (    
      DATA_WIDTH : integer := 8;   
      STEP : std_logic_vector := "00000001"
    );
    port 
    (
      i_CLK       : in std_logic;
      i_RESET     : in std_logic;
      i_INC       : in std_logic;
      i_RESET_VAL : in std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
      o_Q         : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
  end component;
  
  
  
begin

  p_STATE : process (i_CLK, i_CLR)
  begin
    if (i_CLR = '1') then
      r_STATE <= s_IDLE;      --initial state
    elsif (rising_edge(i_CLK)) then
      r_STATE <= w_NEXT;  --next state
    end if;
  end process;
    

  p_NEXT : process (r_STATE, i_GO, r_CNT_REG_PIX, r_NC_O_SEL,  w_END_COL, w_END_ROW)
  begin
    case (r_STATE) is
      when s_IDLE => -- aguarda sinal go
        if (i_LOAD = '1') then
          w_NEXT <= s_PES_VERIFY_ADDR;
        elsif (i_GO = '1') then
          w_NEXT <= s_LOAD_PIX;
        else
          w_NEXT <= s_IDLE;
        end if;
      
      when s_PES_VERIFY_ADDR => -- verifica endereco de pesos
        if (r_PES_ADDR < LAST_PES) then 
          w_NEXT <= s_PES_READ_ENA;
        else
          w_NEXT <= s_BIAS_VERIFY_ADDR;
        end if;        
     
      when s_PES_READ_ENA => -- havilita leitura de pesos
        w_NEXT <= s_PES_WRITE_ENA;
      
      when s_PES_WRITE_ENA => -- havilita escrita de pesos
        w_NEXT <= s_PES_INC_ADDR;
      
      
      when s_PES_INC_ADDR => -- incrementa contgador pesos
        w_NEXT <= s_PES_VERIFY_ADDR;
        
      when s_BIAS_VERIFY_ADDR => -- verifica endereco de BIAS
        if (r_BIAS_ADDR < LAST_BIAS) then 
          w_NEXT <= s_BIAS_READ_ENA;
        else
          w_NEXT <= s_IDLE;
        end if;        
     
      when s_BIAS_READ_ENA => -- havilita leitura de BIAS
        w_NEXT <= s_BIAS_WRITE_ENA;
      
      when s_BIAS_WRITE_ENA => -- havilita escrita de BIAS
        w_NEXT <= s_BIAS_INC_ADDR;
            
      when s_BIAS_INC_ADDR => -- incrementa contgador BIAS
        w_NEXT <= s_BIAS_VERIFY_ADDR;
                   
      when s_LOAD_PIX => -- carrega registradores de entrada (apenas os 3 pixels iniciais
        if (r_CNT_REG_PIX = "11") then
          w_NEXT <= s_REG_OUT_NC;
        else
          w_NEXT <= s_LOAD_PIX;
        end if;          
    
      when s_REG_OUT_NC => -- registra saida
        w_NEXT <= s_ACC_FIL_CH;

      when s_ACC_FIL_CH => -- acumula canais de um filtro
        if (r_NC_O_SEL = "11") then -- enquanto < 3
          w_NEXT <= s_WRITE_OUT;
        else 
          w_NEXT <= s_ACC_FIL_CH;          
        end if;
        
      when s_WRITE_OUT => -- salva no bloco de saida
        w_NEXT <= s_RIGHT_SHIFT;
        
      when s_RIGHT_SHIFT =>  -- deslocamento à direita
        w_NEXT <= s_LAST_COL;
      
      when s_LAST_COL =>  -- verifica fim colunas
        if (w_END_COL = '1') then 
          w_NEXT <= s_DOWN_SHIFT;
        else
          w_NEXT <= s_REG_OUT_NC;
        end if;
        
      when s_DOWN_SHIFT =>  -- deslocamento à baixo
        w_NEXT <= s_LAST_ROW;
        
      when s_LAST_ROW =>  -- verifica fim linhas
        if (w_END_ROW = '1') then 
          w_NEXT <= s_END;        
        else
          w_NEXT <= s_LOAD_PIX;
        end if;
      
      when s_END =>  -- fim
        w_NEXT <= s_IDLE;      

      when others =>
        w_NEXT <= s_IDLE;
        
    end case;
  end process;
  
  
  
  -----------------------------------------------------------------------
  -- sinais para buffers de entrada
  ---------------------------------  
  w_INC_IN_ADDR <= '1' when (r_STATE = s_LOAD_PIX or r_STATE = s_RIGHT_SHIFT) else '0';
  w_RST_IN_ADDR <= '1' when (i_CLR = '1' OR w_END_COL = '1') else '0';     
  -- contador de endereco
  u_INPUT_ADDR : counter 
              generic map (10, "0000000001")
              port map 
              (
                i_CLK       => i_CLK,
                i_RESET     => w_RST_IN_ADDR,
                i_INC       => w_INC_IN_ADDR,
                i_RESET_VAL => (others => '0'),
                o_Q         => w_IN_READ_ADDR
              );  
  
    
  -- OBS.: como offset_addr é diferente de 1 os primeiros bits serão sempre 0
  -- log de output diz que foi inferido latch, porém o RTL não apresenta latch
  -- offset para endereco de buffer de entrada
  w_INC_IN_ADDR0 <= '1' when (r_ROW_SEL = "00" and r_STATE = s_DOWN_SHIFT) else '0';
  w_INC_IN_ADDR1 <= '1' when (r_ROW_SEL = "01" and r_STATE = s_DOWN_SHIFT) else '0';
  w_INC_IN_ADDR2 <= '1' when (r_ROW_SEL = "10" and r_STATE = s_DOWN_SHIFT) else '0';
  
  u_ADDR0_OFFSET : counter 
              generic map (10, OFFSET_ADDR)
              port map 
              (
                i_CLK       => i_CLK,
                i_RESET     => i_CLR,
                i_INC       => w_INC_IN_ADDR0,
                i_RESET_VAL => (others => '0'),
                o_Q         => r_ADDR0_OFF
              );  
  u_ADDR1_OFFSET : counter 
              generic map (10, OFFSET_ADDR)
              port map 
              (
                i_CLK       => i_CLK,
                i_RESET     => i_CLR,
                i_INC       => w_INC_IN_ADDR1,
                i_RESET_VAL => (others => '0'),
                o_Q         => r_ADDR1_OFF
              );
  u_ADDR2_OFFSET : counter 
              generic map (10, OFFSET_ADDR)
              port map 
              (
                i_CLK       => i_CLK,
                i_RESET     => i_CLR,
                i_INC       => w_INC_IN_ADDR2,
                i_RESET_VAL => (others => '0'),
                o_Q         => r_ADDR2_OFF
              );   
  
  o_IN_READ_ADDR0 <= w_IN_READ_ADDR + r_ADDR0_OFF;
  o_IN_READ_ADDR1 <= w_IN_READ_ADDR + r_ADDR1_OFF;
  o_IN_READ_ADDR2 <= w_IN_READ_ADDR + r_ADDR2_OFF;  
  -----------------------------------------------------------------------    
  ---------------------------------
  
  
  
  ---------------------------------
  -- sinais para nucleos convolucionais
  ---------------------------------    
  -- seleciona configuração de conexao entre buffer e registradores de deslocamento
  W_ROW_SEL_RST <= '1' when (i_CLR = '1' or r_STATE = s_IDLE or r_ROW_SEL = "11") else '0';
  W_ROW_SEL_INC <= '1' when (r_STATE = s_DOWN_SHIFT) else '0';
  u_ROW_SEL : counter 
              generic map (2, "01")
              port map 
              (
                i_CLK       => i_CLK,
                i_RESET     => W_ROW_SEL_RST,
                i_INC       => W_ROW_SEL_INC,
                i_RESET_VAL => (others => '0'),
                o_Q         => r_ROW_SEL
              );         
  o_ROW_SEL <= r_ROW_SEL;
  
  
  -- habilita sinal para incrementar contador de deslocamento dos 3 pixels iniciais
  w_INC_CNT_REG_PIX <= '1' when (r_STATE = s_LOAD_PIX) else '0';
  W_CNT_REG_PIX_RST <= '1' when (i_CLR = '1' or r_STATE = s_IDLE or r_STATE = s_REG_OUT_NC) else '0';
  u_CNT_REG_PIX : counter 
              generic map (2, "01")
              port map 
              (
                i_CLK       => i_CLK,
                i_RESET     => W_CNT_REG_PIX_RST,
                i_INC       => w_INC_CNT_REG_PIX,
                i_RESET_VAL => (others => '0'),
                o_Q         => r_CNT_REG_PIX
              );   
    
  o_PIX_SHIFT_ENA <= '1' when (r_STATE = s_LOAD_PIX or r_STATE = s_RIGHT_SHIFT) else '0';
  ---------------------------------
  
  ---------------------------------
  -- sinais para multiplexadores
  ---------------------------------
  
  -- seleciona saida de NCs  
  w_NC_O_SEL_INC <= '1' when (r_STATE = s_ACC_FIL_CH) else '0';
  w_NC_O_SEL_RST <= '1' when (i_CLR = '1' or r_STATE = s_IDLE or r_STATE = s_RIGHT_SHIFT) else '0';   
  u_NC_O_SEL : counter 
              generic map (2, "01")
              port map 
              (
                i_CLK       => i_CLK,
                i_RESET     => w_NC_O_SEL_RST,
                i_INC       => w_NC_O_SEL_INC,
                i_RESET_VAL => (others => '0'),
                o_Q         => r_NC_O_SEL
              );  
  o_NC_O_SEL <= r_NC_O_SEL;
  
  -- habilita acumulador de pixels de saida dos NCs
  o_ACC_ENA  <= w_NC_O_SEL_INC;
  -- reseta acumulador de pixels de saida dos NCs
  o_ACC_RST <= w_NC_O_SEL_RST;
   ---------------------------------
  
  ---------------------------------
  -- sinais para buffers de saida
  ---------------------------------    
  -- habilita escrita buffer de saida
  o_OUT_WRITE_ENA <= '1' when (r_STATE = s_WRITE_OUT) else '0';
  -- incrementa endereco de saida
  o_OUT_INC_ADDR  <= '1' when (r_STATE = s_WRITE_OUT) else '0';
  -- reset endreco de saida
  o_OUT_CLR_ADDR <= '1' when (r_STATE = s_IDLE) else '0';
  ---------------------------------
  
  
  ---------------------------------
  -- Sinais para deslocamento a direita
  ---------------------------------
  -- contador de colunas
  -- default 3 colunas pois inicia a contagem a partir das 3 primeiras colunas
  w_INC_COL_CNT <= '1' when (r_STATE = s_RIGHT_SHIFT) else '0';    
  w_RST_COL_CNT <= '1' when (i_CLR = '1' or r_STATE = s_IDLE or r_STATE = s_DOWN_SHIFT) else '0';  
  u_CNT_COL : counter 
              generic map (5, "00001")
              port map 
              (
                i_CLK       => i_CLK,
                i_RESET     => w_RST_COL_CNT,
                i_INC       => w_INC_COL_CNT,
                i_RESET_VAL => "00011",
                o_Q         => r_CNT_COL
              );     
  
  -- fim coluna quando contador = numero de coluna 
  w_END_COL <= '1' when (r_CNT_COL = LAST_COL) else '0';  
  ---------------------------------
  
  ---------------------------------
  -- Sinais para deslocamento a baixo
  ---------------------------------
  -- contador de linhas
  -- default 3 linhas pois inicia a contagem a partir das 3 primeiras linhas 
  w_INC_ROW_CNT <= '1' when (r_STATE = s_DOWN_SHIFT) else '0';
  w_RST_ROW_CNT <= '1' when (i_CLR = '1' or r_STATE = s_IDLE) else '0';
  u_CNT_ROW : counter 
              generic map (6, "000001")
              port map 
              (
                i_CLK       => i_CLK,
                i_RESET     => w_RST_ROW_CNT,
                i_INC       => w_INC_ROW_CNT,
                i_RESET_VAL => "000011",
                o_Q         => r_CNT_ROW
              );         
  
  -- fim linha quando contador = numero de linha 
  w_END_ROW <= '1' when (r_CNT_ROW = LAST_ROW) else '0';  
  ---------------------------------
  ---------------------------------
  
  
  -- enderecamento dos pesos
  r_PES_ADDR <= (others => '0') when (i_CLR = '1' or r_STATE = s_IDLE) else
                r_PES_ADDR + "00000001" when (rising_edge(i_CLK) and r_STATE = s_PES_INC_ADDR) else
                r_PES_ADDR;
  
  -- enderecametno do bias
  r_BIAS_ADDR <= (others => '0') when (i_CLR = '1' or r_STATE = s_IDLE) else
                r_BIAS_ADDR + "00001" when (rising_edge(i_CLK) and r_STATE = s_BIAS_INC_ADDR) else
                r_BIAS_ADDR;

    
  -- reset contador pesos
  w_RST_NUM_PES <= '1' when (r_STATE = s_PES_VERIFY_ADDR and r_NUM_PES_FILTER > NUM_PES_FILTER_CHA) else '0';
  
  -- conta pesos por filtro
  r_NUM_PES_FILTER <= (others => '0') when (i_CLR = '1' or r_STATE = s_IDLE or w_RST_NUM_PES = '1') else
                r_NUM_PES_FILTER + "00001" when (rising_edge(i_CLK) and r_STATE = s_PES_INC_ADDR) else
                r_NUM_PES_FILTER;
  
  -- endereco do NC para carregar pesos     
  r_NC_ADDR <= (others => '0') when (i_CLR = '1' or r_STATE = s_IDLE) else
                r_NC_ADDR + "00001" when (rising_edge(i_CLK) and  r_NUM_PES_FILTER = NUM_PES_FILTER_CHA and r_STATE = s_PES_INC_ADDR) else
                r_NC_ADDR;
  
  -- reseta contador de colunas
  w_RST_PES_COL_CNTR <= '1' when (r_STATE = s_PES_VERIFY_ADDR and r_PES_COL_CNTR = "11") else '0';
  
  -- conta colunas
  r_PES_COL_CNTR <= (others => '0') when (i_CLR = '1' or w_RST_PES_COL_CNTR = '1') else
                r_PES_COL_CNTR + "01" when (rising_edge(i_CLK) and  r_STATE = s_PES_INC_ADDR) else
                r_PES_COL_CNTR;

  -- reset contador de linha
  w_RST_PES_ROW_CNTR <= '1' when (r_STATE = s_PES_VERIFY_ADDR and r_PES_ROW_CNTR = "11") else '0';
  
  -- conta linhas
  r_PES_ROW_CNTR <= (others => '0') when (i_CLR = '1' or r_STATE = s_IDLE or w_RST_PES_ROW_CNTR = '1') else
                r_PES_ROW_CNTR + "01" when (rising_edge(i_CLK) and r_PES_COL_CNTR = "10" and r_STATE = s_PES_INC_ADDR) else
                r_PES_ROW_CNTR;
  
  
  -- sinal para rom de pesos
  o_PES_READ_ENA  <= '1' when (r_STATE = s_PES_READ_ENA) else '0';
  o_PES_READ_ADDR <= r_PES_ADDR;
    
  -- SINAL PARA ROM DE BIAS E SCALES
  o_BIAS_READ_ENA  <= '1' when (r_STATE = s_BIAS_READ_ENA) else '0';
  o_BIAS_READ_ADDR <= r_BIAS_ADDR;  
  
  -- habilita escrita nos registradores de bias e scale
  o_BIAS_WRITE_ENA <= '1' when (r_STATE = s_BIAS_WRITE_ENA) else '0';
  o_SCALE_WRITE_ENA <= '1' when (r_STATE = s_BIAS_WRITE_ENA) else '0';
  
  -- endereco do NC para carregar pesos     
  o_NC_ADDR <= r_NC_ADDR;

  -- seleciona linha dos registradores de deslocamento
  o_PES_ROW_SEL <= r_PES_ROW_CNTR;  
  
  -- habilita shift dos pesos 
  o_PES_SHIFT_ENA <= '1' when (r_STATE = s_PES_WRITE_ENA) else '0';
  
  -- sinaliza fim maq estado
  o_READY <= '1' when (r_STATE = s_END) else '0';
  
end arch;
