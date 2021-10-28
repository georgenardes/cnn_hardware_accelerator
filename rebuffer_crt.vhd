-- controle rebuffer


-------------------
-- Bloco ReBuffer
-- 21/09/2021
-- George
-- R1

-- Descrição
-- Este bloco implementa o circuito para reordenação dos 
-- dados de um buffer de saída e um buffer de entrada
-- de duas camadas adjacentes.

-- Logica de reordenacao
-- Os pixels de saída de uma imagem estarão ordenados
-- por Linha x Coluna (0x0, 0x1, ..., 10x10). 
-- Para leitura desses valores, basta um contador.
-- Para escrita, esses dados serão multiplexados entre  
-- os buffers de saída (3 blocos para conv, 2 blocos para pool).
-- Dessa forma, será lido da primeira linha de pixels 
-- e escrito no primeiro bloco de saída, seguido pela leitura
-- da segunda linha de pixels e escrita no segundo bloco de saída.
-- A quarta linha de pixel é escrita no primeiro bloco de saída,
-- a quinta linha de pixel é escrita no segundo bloco e assim
-- por diante.

-------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.STD_LOGIC_UNSIGNED.all;

-- Entity
entity rebuffer_crt is
  generic (
    ADDR_WIDTH : integer := 8;
    DATA_WIDTH : integer := 8;    
    NUM_BUFF   : std_logic_vector(1 downto 0)   := "11";    -- 3 buffers
    IFMAP_WIDTH : std_logic_vector(5 downto 0)  := "011000";  -- 24
    IFMAP_HEIGHT : std_logic_vector(5 downto 0) := "100000";  -- 32
    OFMAP_WIDTH : std_logic_vector(5 downto 0)  := "011010";  -- 26
    OFMAP_HEIGHT : std_logic_vector(5 downto 0) := "100010";  -- 34
    PAD_H : std_logic_vector(5 downto 0) := "100001"; -- 33 (indice para adicionar pad linha de baixo)
    PAD_W : std_logic_vector(5 downto 0) := "011001" -- 25 (indice para adicionar pad coluna da direita)
  );
  port (
    i_CLK       : in  std_logic;
    i_CLR       : in  std_logic;
    i_GO        : in  std_logic;

    -- habilita leitura
    o_READ_ENA  : out std_logic;
    
    -- sinaliza borda
    o_PAD       : out std_logic := '0'; 
    -- habilita registrador de dados
    o_REG_ENA   : out std_logic;
    -- reseta registrador de dados
    o_REG_RST   : out std_logic;
    
    
    -- endereco a ser lido
    o_IN_ADDR   : out std_logic_vector (ADDR_WIDTH - 1 downto 0);
    -- endereco a ser escrito
    o_OUT_ADDR  : out std_logic_vector (ADDR_WIDTH - 1 downto 0);
    -- habilita escrita    
    o_WRITE_ENA : out std_logic;
    -- linha de buffer selecionada
    o_SEL_BUFF_LINE  : out std_logic_vector (1 downto 0);
    
    o_READY     : out std_logic
  );
end rebuffer_crt;

--- Arch
architecture arch of rebuffer_crt is
  type t_STATE is (
    s_IDLE        , -- idle
    s_MAX_ROW     , -- verifica se atingiu numero maximo de linhas de saida
    s_RST_COL_CNTR, -- zera contador de coluna
    s_MAX_COL     , -- verifica se atingiu numero maximo de colunas de saida
    s_PAD         , -- verifica se tem padding 
    s_DADO_ZERO   , -- dado = zero
    s_READ_ENA    , -- habilita leitura da RAM de pixels
    s_DADO_INPUT  , -- dado = input[addr++]    
    s_INC_COL_CNTR, -- incrementa contador de coluna
    s_SEL_BUFF    , -- verifica buffer selecionado
    s_BUFF_LINE0  , -- atribui dado a linha 1 do buffer e incrementa contador de endreco do buffer
    s_BUFF_LINE1  , -- atribui dado a linha 2 do buffer e incrementa contador de endreco do buffer
    s_BUFF_LINE2  , -- atribui dado a linha 3 do buffer e incrementa contador de endreco do buffer
    s_INC_ROW_CNTR, -- incrementa contador de linha e contador de linhas de buffer     
    s_SEL_MAX     , -- verifica se sel_buff atingiu numero maximo linhas de buffer
    s_RST_SEL_BUFF, -- zera sel_buff
    s_END           -- fim  
  );
  signal r_STATE : t_STATE; -- state register
  signal w_NEXT : t_STATE; -- next state 
  
  ------------------
  -- conta linhas 
  signal r_ROW_CNT : std_logic_vector (5 downto 0) := (others => '0'); -- maximo 64 linhas (altura imagens)
  
  -- conta colunas
  signal r_COL_CNT : std_logic_vector (5 downto 0) := (others => '0'); -- maximo 64 colunas (largura imagens)  
  ------------------
  
  ------------------
  -- contador endereco entrada
  signal r_READ_ADDR : std_logic_vector (9 downto 0) := (others => '0'); -- maximo 1024 enderecos
  ------------------
  
  ------------------
  -- contadores para cada buffer de saida
  signal r_BUFF_0 :  std_logic_vector (9 downto 0) := (others => '0'); -- maximo 1024 enderecos
  signal r_BUFF_1 :  std_logic_vector (9 downto 0) := (others => '0'); -- maximo 1024 enderecos
  signal r_BUFF_2 :  std_logic_vector (9 downto 0) := (others => '0'); -- maximo 1024 enderecos
  ------------------
    
  -- seleciona buffer para incrementar
  signal r_SEL_BUFF_LINE : std_logic_vector (1 downto 0) := "00";
  
  
  -- sinaliza se oi endereco de linha ou coluna é de borda
  signal w_IS_PAD : std_logic := '0';
  
  
  -- multiplexador 4 x 1
  component mux_4x1 is
    generic (DATA_WIDTH : INTEGER := 8);
    port (
      i_A, i_B, i_C, i_D : in std_logic_vector (DATA_WIDTH-1 DOWNTO 0);
      i_SEL : in std_logic_vector (1 downto 0);
      o_Q : out std_logic_vector (DATA_WIDTH-1 DOWNTO 0)
    );  
  end component;
  
begin

  -- state machine
  p_STATE : process (i_CLK, i_CLR)
  begin
    if (i_CLR = '1') then
      r_STATE <= s_IDLE; --initial state
    elsif (rising_edge(i_CLK)) then
      r_STATE <= w_NEXT; --next state
    end if;
  end process;
    
     
  p_NEXT : process (r_STATE, i_GO, r_ROW_CNT, r_COL_CNT, r_READ_ADDR, r_SEL_BUFF_LINE, w_IS_PAD)
  begin
    case (r_STATE) is
      when s_IDLE => -- aguarda sinal go
        if (i_GO = '1') then
          w_NEXT <= s_MAX_ROW;
        else
          w_NEXT <= s_IDLE;
        end if;
        
      when s_MAX_ROW => -- verifica se chegou na ultima linha
        if (r_ROW_CNT < OFMAP_HEIGHT) then 
          w_NEXT <= s_RST_COL_CNTR;  
        else
          w_NEXT <= s_END; 
        end if;
        
      when s_RST_COL_CNTR => 
        w_NEXT <= s_MAX_COL;
        
      when s_MAX_COL => -- verifica se chegou na ultima coluna
        if (r_COL_CNT < OFMAP_WIDTH) then
          w_NEXT <= s_PAD;
        else
          w_NEXT <= s_INC_ROW_CNTR;
        end if;   
        
      when s_PAD => -- verifica se é pra adicionar borda
        if (w_IS_PAD = '1') then 
          w_NEXT <= s_DADO_ZERO;
        else
          w_NEXT <= s_READ_ENA;
        end if;
                
      when s_DADO_ZERO => -- atribui zero ao registrador de dado
        w_NEXT <= s_INC_COL_CNTR;
        
      when s_READ_ENA => 
        w_NEXT <= s_DADO_INPUT;
        
      when s_DADO_INPUT => -- atribui o valor de entrada ao registrador de dado
        w_NEXT <= s_INC_COL_CNTR;
        
      when s_INC_COL_CNTR =>  -- incrementa contador de coluna      
        w_NEXT <= s_SEL_BUFF;

      when s_SEL_BUFF =>  -- verifica buffer selecionado
        if (r_SEL_BUFF_LINE = "00") then
          w_NEXT <= s_BUFF_LINE0;  
        elsif (r_SEL_BUFF_LINE = "01") then
          w_NEXT <= s_BUFF_LINE1;
        elsif (r_SEL_BUFF_LINE = "10") then
          w_NEXT <= s_BUFF_LINE2;
        else
          w_NEXT <= s_BUFF_LINE0;
        end if;
        

      when s_BUFF_LINE0  => 
        w_NEXT <= s_MAX_COL;
        
      when s_BUFF_LINE1  => 
        w_NEXT <= s_MAX_COL;
        
      when s_BUFF_LINE2 => 
        w_NEXT <= s_MAX_COL;   
        
      when s_INC_ROW_CNTR => -- incrementa row_cnt and sel_buff
        w_NEXT <= s_SEL_MAX;
        
      when s_SEL_MAX => -- verifica se sel_buff atigiu valor maximo
        if (r_SEL_BUFF_LINE = "11") then 
          w_NEXT <= s_RST_SEL_BUFF;
        else
          w_NEXT <= s_MAX_ROW;
        end if;
        
      when s_RST_SEL_BUFF => -- zera sel_buff
        w_NEXT <= s_MAX_ROW;
      
      when s_END => 
        w_NEXT <= s_IDLE;
      
      when others =>
        w_NEXT <= s_IDLE;
        
    end case;
  end process;
  
  
  
  
  -- if (row_counter == 0 || row_counter == H+1 || column_counter == 0 || column_counter == W+1)
  
  --- checar maq estados(OK) e fazer operadores
  w_IS_PAD <= '1' 
                when (r_ROW_CNT = "000000" or r_ROW_CNT = PAD_H or r_COL_CNT = "000000" or r_COL_CNT = PAD_W) 
                else  
              '0';
  -- sinaliza borda
  o_PAD       <= w_IS_PAD;    
  
  -- habilita registrador de dados
  o_REG_ENA   <= '1' when (r_STATE = s_DADO_INPUT or r_STATE = s_DADO_ZERO) else '0';
    
  -- reseta registrador de dados
  o_REG_RST   <= '1' when (i_CLR = '1' or r_STATE = s_IDLE) else '0';       
  
  
    -- conta colunas de uma linha (para saber quando deve ir para o proximo buffer)
  r_ROW_CNT <= (others => '0')           
                    when (i_CLR = '1' or r_STATE = s_IDLE) else
                  (r_ROW_CNT + "000001") 
                    when (rising_edge(i_CLK) and r_STATE = s_INC_ROW_CNTR) else 
                  r_ROW_CNT;
                  
  -- conta colunas de uma linha (para saber quando deve ir para o proximo buffer)
  r_COL_CNT <= (others => '0')           
                    when (i_CLR = '1' or r_STATE = s_RST_COL_CNTR) else
                  (r_COL_CNT + "000001") 
                    when (rising_edge(i_CLK) and r_STATE = s_INC_COL_CNTR) else 
                  r_COL_CNT;
  
  -- seleciona um dos buffers de saida para escrita do dado
  r_SEL_BUFF_LINE <= (others => '0')           
                  when (i_CLR = '1' or r_STATE = s_IDLE or r_STATE = s_RST_SEL_BUFF) else
                (r_SEL_BUFF_LINE + "01") 
                  when (rising_edge(i_CLK) and r_STATE = s_INC_ROW_CNTR) else 
                r_SEL_BUFF_LINE;
                
  -- incrementa endereco de buffer de entrada
  r_READ_ADDR <=  (others => '0')           
                    when (i_CLR = '1' or r_STATE = s_IDLE) else
                  (r_READ_ADDR + "0000000001") 
                    when (rising_edge(i_CLK) and r_STATE = s_DADO_INPUT) else 
                  r_READ_ADDR;
  
  
  -- incrementa endereco de primeiro buffer de saida
  r_BUFF_0 <= (others => '0')           
                when (i_CLR = '1' or r_STATE = s_IDLE) else
              (r_BUFF_0 + "0000000001") 
                when (rising_edge(i_CLK) and r_STATE = s_BUFF_LINE0) else 
              r_BUFF_0;
  
  -- incrementa endereco de segundo buffer de saida
  r_BUFF_1 <= (others => '0')           
                when (i_CLR = '1' or r_STATE = s_IDLE) else
              (r_BUFF_1 + "0000000001") 
                when (rising_edge(i_CLK) and r_STATE = s_BUFF_LINE1) else 
              r_BUFF_1;
  
  -- incrementa endereco de segundo buffer de saida
  r_BUFF_2 <= (others => '0')           
                when (i_CLR = '1' or r_STATE = s_IDLE) else
              (r_BUFF_2 + "0000000001") 
                when (rising_edge(i_CLK) and r_STATE = s_BUFF_LINE2) else 
              r_BUFF_2;
  
  
  -- seleciona um dos endereco para saida
  u_MUX : mux_4x1 
          generic map (ADDR_WIDTH)
          port map 
          (
            r_BUFF_0 (ADDR_WIDTH - 1 downto 0),
            r_BUFF_1 (ADDR_WIDTH - 1 downto 0),
            r_BUFF_2 (ADDR_WIDTH - 1 downto 0),
            (others => '0'),
            r_SEL_BUFF_LINE,
            o_OUT_ADDR
          );
  
  -- linha de buffer selecionada
  o_SEL_BUFF_LINE <= r_SEL_BUFF_LINE;
  
  -- enable escrita
  o_WRITE_ENA <= '1' 
                  when (r_STATE = s_BUFF_LINE0 or r_STATE = s_BUFF_LINE1 or r_STATE = s_BUFF_LINE2) else 
                 '0';
  
  -- habilita leitura
  o_READ_ENA <= '1' when (r_STATE = s_READ_ENA) else '0';
  
  -- endereco de leitura
  o_IN_ADDR <= r_READ_ADDR(ADDR_WIDTH - 1 downto 0); 
    
  -- fim processamento 
  o_READY <= '1' when (r_STATE = s_END) else '0';
  
end arch;





