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
entity rebuffer is
  generic (
    ADDR_WIDTH : integer := 8;
    DATA_WIDTH : integer := 8;
    REBUFF_TYPE : integer := 0;
    NUM_BUFF   : std_logic_vector(1 downto 0) := "11"; -- 3 buffers
    FMAP_WIDTH : std_logic_vector(5 downto 0) := "100000"; -- 32
    INPUT_MAX_ADDR : std_logic_vector(9 downto 0) := "0000100000" -- 32*#linhas
  );
  port (
    i_CLK       : in  std_logic;
    i_CLR       : in  std_logic;
    i_GO        : in  std_logic;

    -- dado de entrada
    i_DATA      : in  std_logic_vector (DATA_WIDTH - 1 downto 0);
    -- habilita leitura
    o_READ_ENA  : out std_logic;
    -- endereco a ser lido
    o_IN_ADDR   : out std_logic_vector (ADDR_WIDTH - 1 downto 0);
    -- endereco a ser escrito
    o_OUT_ADDR  : out std_logic_vector (ADDR_WIDTH - 1 downto 0);
    -- habilita escrita    
    o_WRITE_ENA : out std_logic;
    -- dado de saida (mesmo q o de entrada)
    o_DATA      : out std_logic_vector (DATA_WIDTH - 1 downto 0);
    -- linha de buffer selecionada
    o_SEL_BUFF  : out std_logic_vector (1 downto 0);
    o_READY     : out std_logic
  );
end rebuffer;

--- Arch
architecture arch of rebuffer is
  type t_STATE is (
    s0, -- idle
    s1, -- verifica se r_READ_ADDR atingiu valor maximo
    s2, -- le e registra dado de entrada
    s3, -- verifica se contador de coluna atingiu valor maximo
    s4, -- zera contador coluna e incrementa sel_buff
    s5, -- verifica se sel_buff atingiu numero maximo de buffers
    s6, -- zera sel_buff
    s7, -- verifica sel_buff 
    s8, -- atribui dado a buff0 e incrementa addr_buff0
    s9, -- atribui dado a buff1 e incrementa addr_buff1
    s10, -- atribui dado a buff2 e incrementa addr_buff2
    s11, -- incrementa r_READ_ADDR
    s12 -- END                     
  );
  signal r_STATE : t_STATE; -- state register
  signal w_NEXT : t_STATE; -- next state 
  
  
  -- dado de entrada
  signal r_DATA    :  std_logic_vector (DATA_WIDTH - 1 DOWNTO 0); 
  
  -- contador endereco entrada
  signal r_READ_ADDR : std_logic_vector (9 downto 0) := (others => '0'); -- maximo 1024 enderecos
  
  -- conta colunas para selecao de buffers
  signal r_COLUMN_CNT : std_logic_vector (5 downto 0) := (others => '0'); -- maximo 64 colunas (largura imagens)
  
  -- seleciona buffer para incrementar
  signal r_SEL_BUFF : std_logic_vector (1 downto 0) := "00";
  
  -- contadores para cada buffer de saida
  signal r_BUFF_0 :  std_logic_vector (9 downto 0) := (others => '0'); -- maximo 1024 enderecos
  signal r_BUFF_1 :  std_logic_vector (9 downto 0) := (others => '0'); -- maximo 1024 enderecos
  signal r_BUFF_2 :  std_logic_vector (9 downto 0) := (others => '0'); -- maximo 1024 enderecos
  
  
    
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
      r_STATE <= s0; --initial state
    elsif (rising_edge(i_CLK)) then
      r_STATE <= w_NEXT; --next state
    end if;
  end process;

  p_NEXT : process (r_STATE, i_GO, r_READ_ADDR, r_COLUMN_CNT, r_SEL_BUFF)
  begin
    case (r_STATE) is
      when s0 => -- aguarda sinal go
        if (i_GO = '1') then
          w_NEXT <= s1;
        else
          w_NEXT <= s0;
        end if;
      when s1 => 
        if (r_READ_ADDR < INPUT_MAX_ADDR) then 
          w_NEXT <= s2;   -- next
        else
          w_NEXT <= s12; -- fim
        end if;
      when s2 => 
        w_NEXT <= s3;
      when s3 => 
        if (r_COLUMN_CNT = FMAP_WIDTH) then
          w_NEXT <= s4;
        else
          w_NEXT <= s7;
        end if;        
      when s4 => 
        w_NEXT <= s5;
      when s5 => 
        if (r_SEL_BUFF = NUM_BUFF) then
          w_NEXT <= s6;
        else
          w_NEXT <= s7;
        end if;        
      when s6 =>
        w_NEXT <= s7;
      when s7 =>
        if (r_SEL_BUFF = "00") then
          w_NEXT <= s8;
        elsif (r_SEL_BUFF = "01") then
          w_NEXT <= s9;
        else -- (r_SEL_BUFF = "10") then
          w_NEXT <= s10;
        end if;
      when s8  => 
        w_NEXT <= s11;
      when s9  => 
        w_NEXT <= s11;
      when s10 => 
        w_NEXT <= s11;    
      when s11 => 
        w_NEXT <= s1;
      when s12 => -- end
        w_NEXT <= s0;
      when others =>
        w_NEXT <= s0;
    end case;
  end process;

  -- registra dado de entrada
  r_DATA <= (others => '0') 
              when (i_CLR = '1') else 
            i_DATA          
              when (rising_edge(i_CLK) and r_STATE = s2) else 
            r_DATA;
  
  -- conta colunas de uma linha (para saber quando deve ir para o proximo buffer)
  r_COLUMN_CNT <= (others => '0')           
                    when (i_CLR = '1' or r_STATE = s4) else
                  (r_COLUMN_CNT + "000001") 
                    when (rising_edge(i_CLK) and r_STATE = s11) else 
                  r_COLUMN_CNT;
  
  -- incrementa endereco de buffer de entrada
  r_READ_ADDR <=  (others => '0')           
                    when (i_CLR = '1' or r_STATE = s0) else
                  (r_READ_ADDR + "0000000001") 
                    when (rising_edge(i_CLK) and r_STATE = s11) else 
                  r_READ_ADDR;
  
  -- seleciona um dos buffers de saida para escrita do dado
  r_SEL_BUFF <= (others => '0')           
                  when (i_CLR = '1' or r_STATE = s6 or r_STATE = s0) else
                (r_SEL_BUFF + "01") 
                  when (rising_edge(i_CLK) and r_STATE = s4) else 
                r_SEL_BUFF;
  
  -- incrementa endereco de primeiro buffer de saida
  r_BUFF_0 <= (others => '0')           
                when (i_CLR = '1' or r_STATE = s0) else
              (r_BUFF_0 + "0000000001") 
                when (rising_edge(i_CLK) and r_STATE = s8) else 
              r_BUFF_0;
  
  -- incrementa endereco de segundo buffer de saida
  r_BUFF_1 <= (others => '0')           
                when (i_CLR = '1' or r_STATE = s0) else
              (r_BUFF_1 + "0000000001") 
                when (rising_edge(i_CLK) and r_STATE = s9) else 
              r_BUFF_1;
  
  -- incrementa endereco de segundo buffer de saida
  r_BUFF_2 <= (others => '0')           
                when (i_CLR = '1' or r_STATE = s0) else
              (r_BUFF_2 + "0000000001") 
                when (rising_edge(i_CLK) and r_STATE = s10) else 
              r_BUFF_2;
  
  
  -- seleciona um dos endereco para saida
  u_MUX : mux_4x1 
          generic map (DATA_WIDTH)
          port map 
          (
            r_BUFF_0 (DATA_WIDTH - 1 downto 0),
            r_BUFF_1 (DATA_WIDTH - 1 downto 0),
            r_BUFF_2 (DATA_WIDTH - 1 downto 0),
            (others => '0'),
            r_SEL_BUFF,
            o_OUT_ADDR
          );
  -- linha de buffer selecionada
  o_SEL_BUFF <= r_SEL_BUFF;
  
  -- enable escrita
  o_WRITE_ENA <= '1' 
                  when (r_STATE = s8 or r_STATE = s9 or r_STATE = s10) else 
                 '0';
  
  o_READ_ENA <= '1' when (r_STATE = s2) else '0';
  o_IN_ADDR <= r_READ_ADDR(ADDR_WIDTH - 1 downto 0); 
  o_DATA <= r_DATA;
  o_READY <= '1' when (r_STATE = s12) else '0';
  
end arch;







library ieee;
use ieee.std_logic_1164.all;
entity mux_4x1 is
  generic (DATA_WIDTH : integer := 8);
  port (
    i_A, i_B, i_C, i_D : in  std_logic_vector (DATA_WIDTH - 1 downto 0);
    i_SEL              : in  std_logic_vector (1 downto 0);
    o_Q                : out std_logic_vector (DATA_WIDTH - 1 downto 0)
  );

end mux_4x1;
architecture arch of mux_4x1 is
begin
  o_Q <= i_A when (i_SEL = "00") else
         i_B when (i_SEL = "01") else
         i_C when (i_SEL = "10") else
         i_D;
end arch;
