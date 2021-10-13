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
    H : integer := 32; -- iFMAP Height 
    W : integer := 24; -- iFMAP Width 
    C : integer := 3; -- iFMAP Chanels (filter Chanels also)
    R : integer := 3; -- filter Height 
    S : integer := 3; -- filter Width     
    M : integer := 6; -- Number of filters (oFMAP Chanels also)    
    DATA_WIDTH : integer := 8;
    ADDR_WIDTH : integer := 10;    
    OFFSET_ADDR : std_logic_vector := "0000011000"; -- 24dec
    LAST_ROW : std_logic_vector := "10000"; -- 32 por conta do padd
    LAST_COL : std_logic_vector := "1100"   -- 24 por conta do padd
  );

  port (
    i_CLK           : in  std_logic;
    i_CLR           : in  std_logic;
    i_GO            : in  std_logic; -- inicia maq
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

    ---------------------------------
    -- sinais para núcleos convolucionais
    ---------------------------------
    -- habilita deslocamento dos registradores de pixels e pesos
    o_PIX_SHIFT_ENA : out  std_logic;
    o_PES_SHIFT_ENA : out  std_logic;

    -- seleciona saida de NCs
    o_NC_O_SEL      : out  std_logic_vector(c_SEL_WIDHT downto 0);
    -- habilita acumulador de pixels de saida dos NCs
    o_ACC_ENA       : out  std_logic;
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
    s_LOAD_PIX, -- LOAD pixels
    s_ADD_PADD, -- adiciona borda (caso seja a configuracao da camada)
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
  -- contador para endereco de buffer de entrada
  signal r_IN_READ_ADDR : std_logic_vector (ADDR_WIDTH-1 downto 0);
  signal w_INC_IN_ADDR : std_logic; 
  
  -- offset para endereco de buffer de entrada
  signal r_ADDR0_OFF : std_logic_vector (ADDR_WIDTH - 1 downto 0);
  signal r_ADDR1_OFF : std_logic_vector (ADDR_WIDTH - 1 downto 0);
  signal r_ADDR2_OFF : std_logic_vector (ADDR_WIDTH - 1 downto 0); 
  -----------------------------------------------------------------------
  
  -- conta clocks para registrar pixels de entrada
  signal r_CNT_REG_PIX : std_logic_vector (1 downto 0) := (others => '0');
  signal w_INC_CNT_REG_PIX : std_logic;
  
  -- seleciona saida de NCs
  signal r_NC_O_SEL : std_logic_vector(c_SEL_WIDHT downto 0) := (others => '0');
  
  -- habilita acumulador de pixels de saida dos NCs
  signal w_ACC_ENA  : std_logic;
  
  -- seleciona configuração de conexao entre buffer e registradores de deslocamento
  signal r_ROW_SEL : std_logic_vector(1 downto 0); 
    
  
  -- contador de colunas
  -- default 3 colunas pois inicia a contagem a partir das 3 primeiras colunas
  signal r_CNT_COL : std_logic_vector(4 downto 0) := "00011"; -- max 2^5-1 = 31 colunas 
  signal w_INC_COL_CNT : std_logic;
  signal w_END_COL : std_logic;
  
  -- contador de linhas
  -- default 3 linhas pois inicia a contagem a partir das 3 primeiras linhas
  signal r_CNT_ROW : std_logic_vector(5 downto 0) := "000011"; -- max 2^6-1 = 63 linhas 
  signal w_INC_ROW_CNT : std_logic;
  signal w_END_ROW : std_logic;
  
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
        if (i_GO = '1') then
          w_NEXT <= s_LOAD_PIX;
        else
          w_NEXT <= s_IDLE;
        end if;

      when s_LOAD_PIX => -- carrega registradores de entrada (apenas os 3 pixels iniciais
        if (r_CNT_REG_PIX < "11") then
          w_NEXT <= s_LOAD_PIX;
        else
          w_NEXT <= s_REG_OUT_NC;
        end if;
      
      when s_ADD_PADD =>
        w_NEXT <= s_LOAD_PIX;
    
      when s_REG_OUT_NC => -- registra saida
        w_NEXT <= s_ACC_FIL_CH;

      when s_ACC_FIL_CH => -- acumula canais de um filtro
        if (r_NC_O_SEL = "111") then -- 7 == fim acumulador
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
  w_INC_IN_ADDR <= '1' when (r_STATE = s_LOAD_PIX) else '0';
  
  -- contador de endereco
  r_IN_READ_ADDR <= (others => '0') when (i_CLR = '1' or r_IN_READ_ADDR = OFFSET_ADDR) else -- talvez provoque instabilidade
                    r_IN_READ_ADDR + "0000000001" when (rising_edge(i_CLK) and w_INC_IN_ADDR = '1') else 
                    r_IN_READ_ADDR;  
  
    
  -- OBS.: como offset_addr é diferente de 1 os primeiros bits serão sempre 0
  -- log de output diz que foi inferido latch, porém o RTL não apresenta latch
  -- offset para endereco de buffer de entrada
  r_ADDR0_OFF <= (others => '0') when (i_CLR = '1') else
                  r_ADDR0_OFF + OFFSET_ADDR when (rising_edge(i_CLK) and r_ROW_SEL = "00") else 
                  r_ADDR0_OFF; 
  r_ADDR1_OFF <= (others => '0') when (i_CLR = '1') else
                  r_ADDR1_OFF + OFFSET_ADDR when (rising_edge(i_CLK) and r_ROW_SEL = "01") else 
                  r_ADDR1_OFF; 
  r_ADDR2_OFF <= (others => '0') when (i_CLR = '1') else
                  r_ADDR2_OFF + OFFSET_ADDR when (rising_edge(i_CLK) and r_ROW_SEL = "10") else 
                  r_ADDR2_OFF; 
  
  o_IN_READ_ADDR0 <= r_IN_READ_ADDR + r_ADDR0_OFF;
  o_IN_READ_ADDR1 <= r_IN_READ_ADDR + r_ADDR1_OFF;
  o_IN_READ_ADDR2 <= r_IN_READ_ADDR + r_ADDR2_OFF;
  
  -----------------------------------------------------------------------    
  ---------------------------------
  
  ---------------------------------
  -- sinais para nucleos convolucionais
  ---------------------------------    
  -- seleciona configuração de conexao entre buffer e registradores de deslocamento
  r_ROW_SEL <= (others => '0') when (i_CLR = '1' or r_STATE = s_IDLE or r_ROW_SEL = "11") else 
                r_ROW_SEL + "01" when (rising_edge(i_CLK) and r_STATE = s_LAST_ROW) else
                r_ROW_SEL;
  o_ROW_SEL <= r_ROW_SEL;
  
  -- habilita sinal para incrementar contador de deslocamento dos 3 pixels iniciais
  w_INC_CNT_REG_PIX <= '1' when (r_STATE = s_LOAD_PIX) else '0';
  r_CNT_REG_PIX <= (others => '0') when (i_CLR = '1' or r_STATE = s_IDLE) else
                   r_CNT_REG_PIX + "01" when (rising_edge(i_CLK) and w_INC_CNT_REG_PIX = '1') else 
                   r_CNT_REG_PIX;  
  o_PIX_SHIFT_ENA <= '1' when (r_STATE = s_LOAD_PIX) else '0';
  ---------------------------------
  
  ---------------------------------
  -- sinais para multiplexadores
  ---------------------------------
  -- seleciona saida de NCs  
  r_NC_O_SEL <= (others => '0') when (i_CLR = '1' or r_STATE = s_IDLE) else 
                 r_NC_O_SEL + "001" when (rising_edge(i_CLK) and r_STATE = s_ACC_FIL_CH) else 
                 r_NC_O_SEL;  
  o_NC_O_SEL <= r_NC_O_SEL;
  -- habilita acumulador de pixels de saida dos NCs
  o_ACC_ENA  <= '1' when (r_STATE = s_ACC_FIL_CH) else '0';
  ---------------------------------
  
  ---------------------------------
  -- sinais para buffers de saida
  ---------------------------------    
  -- habilita escrita buffer de saida
  o_OUT_WRITE_ENA <= '1' when (r_STATE = s_RIGHT_SHIFT) else '0';
  -- incrementa endereco de saida
  o_OUT_INC_ADDR  <= '1' when (r_STATE = s_RIGHT_SHIFT) else '0';
  -- reset endreco de saida
  o_OUT_CLR_ADDR <= '1' when (r_STATE = s_IDLE) else '0';
  ---------------------------------
  
  
  ---------------------------------
  -- Sinais para deslocamento a direita
  ---------------------------------
  -- contador de colunas
  -- default 3 colunas pois inicia a contagem a partir das 3 primeiras colunas
  w_INC_COL_CNT <= '1' when (r_STATE = s_RIGHT_SHIFT) else '0';
  r_CNT_COL <=  "00011" when (i_CLR = '1' or r_STATE = s_IDLE or r_STATE = s_DOWN_SHIFT) else 
                 r_CNT_COL + "00001" when (rising_edge(i_CLK) and w_INC_COL_CNT = '1') else 
                 r_CNT_COL;    
  
  -- fim coluna quando contador = numero de coluna (24)
  w_END_COL <= '1' when (r_CNT_COL = LAST_COL) else '0';  
  ---------------------------------
  
  ---------------------------------
  -- Sinais para deslocamento a baixo
  ---------------------------------
  -- contador de linhas
  -- default 3 linhas pois inicia a contagem a partir das 3 primeiras linhas 
  w_INC_ROW_CNT <= '1' when (r_STATE = s_DOWN_SHIFT) else '0';
  r_CNT_ROW <= "000011" when (i_CLR = '1' or r_STATE = s_IDLE) else 
                 r_CNT_ROW + "000001" when (rising_edge(i_CLK) and w_INC_ROW_CNT = '1') else 
                 r_CNT_ROW;
  
  -- fim linha quando contador = numero de linha (32)
  w_END_ROW <= '1' when (r_CNT_ROW = LAST_ROW) else '0';  
  ---------------------------------
  
  
  -- sinaliza fim maq estado
  o_READY <= '1' when (r_STATE = s_END) else '0';
  
end arch;
