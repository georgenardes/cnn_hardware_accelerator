-- Bloco de controle softmax
-- 08/09/2021
-- George
-- R1

-- Descrição
-- Este bloco controla as operações do
-- bloco softmax_op

-------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.STD_LOGIC_UNSIGNED.all;
USE ieee.numeric_std.ALL;
library work;
use work.types_pkg.all;

-- Entity
entity softmax_crt is
  port (    
    i_CLK      : in STD_LOGIC;
    i_CLR      : in STD_LOGIC;
    i_GO       : in STD_LOGIC;
    
    -- SINAIS DE CONTROLE
    -- clear
    o_CLR_VET0 : out STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0);   
    o_CLR_VET1 : out STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0);   
    o_CLR_VET2 : out STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0); 
    
    -- enable
    o_ENA_VET0 : out STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0);      
    o_ENA_VET1 : out STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0);      
    o_ENA_VET2 : out STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0); 
    
    -- sel mux
    o_SEL_MUX0  : out  std_logic_vector(6 DOWNTO 0);
    o_SEL_MUX1  : out  std_logic_vector(6 DOWNTO 0);
    
    -- sel demux
    o_SEL_DEMUX0  : out  std_logic_vector(6 DOWNTO 0);
    o_SEL_DEMUX1  : out  std_logic_vector(6 DOWNTO 0);
    
    -- enable acumulador
    o_ACC_ENA : out std_logic;
    
    -- clear acumulador
    o_ACC_CLR : out std_logic;
    
    -- sinaliza fim
    o_READY : out std_logic

  );
end softmax_crt;
  
  
--- Arch
architecture arch of softmax_crt is
  type t_STATE is (s_IDLE, s_LOAD, s_MUX_ENAX, s_CLR_CNT, s_MUX_DIV, s_END);
  SIGNAL r_STATE : t_STATE; -- state register
  SIGNAL w_NEXT : t_STATE; -- next state  
  
  -- sinaliza fim de multiplexacao
  signal w_START_MUX, w_END_MUX, w_CLR_CNT : std_logic := '0';
  
  -- contador multiplexacao
  signal r_MUX_CNT : std_logic_vector(6 downto 0) := (others => '0');
  
  -- decoder para os sinais de habilitacao
  component softmax_decoder_reg is 
    PORT (      
      i_SEL       : IN  std_logic_vector(6 DOWNTO 0); -- 6 bits para enderecamento
      o_Q         : OUT  STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0)  
    );
  end component;
  
  signal w_OUT_DEC1, w_OUT_DEC2 : STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0);
begin

  p_STATE : PROCESS (i_CLK, i_CLR)
  BEGIN
    IF (i_CLR = '1') THEN
      r_STATE <= s_IDLE; --initial state
    ELSIF (rising_edge(i_CLK)) THEN
      r_STATE <= w_NEXT; --next state
    END IF;
  END PROCESS;
            
  
  p_NEXT : PROCESS (r_STATE, w_END_MUX, i_GO)
  BEGIN
    CASE (r_STATE) IS
      WHEN s_IDLE => -- aguarda sinal go
        if (i_GO = '1') then
          w_NEXT <= s_LOAD; 
        else
          w_NEXT <= s_IDLE;
        end if;
        
      WHEN s_LOAD => -- carrega registradores de entrada
        w_NEXT <= s_MUX_ENAX; 
        
      WHEN s_MUX_ENAX =>
        if (w_END_MUX = '1') then
          w_NEXT <= s_CLR_CNT; 
        else  
          w_NEXT <= s_MUX_ENAX;
        end if;
        
      WHEN s_CLR_CNT =>
        w_NEXT <= s_MUX_DIV;  
        
      WHEN s_MUX_DIV =>
        if (w_END_MUX = '1') then
          w_NEXT <= s_END;
        else  
          w_NEXT <= s_MUX_DIV;          
        end if;
        
      WHEN s_END =>
        w_NEXT <= s_IDLE;     
        
      WHEN OTHERS =>
        w_NEXT <= s_IDLE;
    END CASE;
  END PROCESS;
  
  
  
  -- inicio contador de multiplexacao
  w_START_MUX <= '1' WHEN (r_STATE = s_MUX_ENAX or r_STATE = s_MUX_DIV) else '0';
  
  -- clear contador de multiplexacao
  w_CLR_CNT <= '1' when (r_STATE = s_CLR_CNT) else '0';
  
  -- end mux = 1 quando chegar em 34
  w_END_MUX <= '1' when (r_MUX_CNT = "100010") else '0';
  
  -- processo para o contador de multiplexacao
  p_MUX : process (i_CLK, w_START_MUX, w_CLR_CNT)
  begin
    if (w_CLR_CNT = '1') then 
      r_MUX_CNT <= (others => '0');
    elsif (rising_edge(i_CLK) and w_START_MUX = '1') then 
      r_MUX_CNT <= r_MUX_CNT + "000001";
    end if;
  end process;
  
    
  -- SINAIS DE CLEAR PARA OS ARRAYS DE REGISTRADORES
  o_CLR_VET0 <= (others => '1') when (r_STATE = s_IDLE or r_STATE = s_END) else (others => '0');
  o_CLR_VET1 <= (others => '1') when (r_STATE = s_IDLE or r_STATE = s_END) else (others => '0');
  o_CLR_VET2 <= (others => '1') when (r_STATE = s_IDLE or r_STATE = s_END) else (others => '0');
  
  -- sinais acumulador
  o_ACC_CLR <= '1' when (r_STATE = s_IDLE or r_STATE = s_END) else '0';
  o_ACC_ENA <= '1' when (r_STATE = s_MUX_ENAX) else '0';
  
  -- SINAIS DE habilitacao PARA OS ARRAYS DE REGISTRADORES
  u_DEC1 : softmax_decoder_reg             
            port map (r_MUX_CNT, w_OUT_DEC1);      
  u_DEC2 : softmax_decoder_reg             
            port map (r_MUX_CNT, w_OUT_DEC2);   
  o_ENA_VET0 <= (others => '1') when (r_STATE = s_LOAD) else (others => '0');  
  o_ENA_VET1 <= w_OUT_DEC1 when (r_STATE = s_MUX_ENAX) else (others => '0');
  o_ENA_VET2 <= w_OUT_DEC2 when (r_STATE = s_MUX_DIV) else (others => '0');
  
  
  -- sinais de selecao 
  -- sel mux
  o_SEL_MUX0  <= r_MUX_CNT;
  o_SEL_MUX1  <= r_MUX_CNT;
  -- sel demux 
  o_SEL_DEMUX0 <= r_MUX_CNT;
  o_SEL_DEMUX1 <= r_MUX_CNT;
  
  
  -- fim
  o_READY <= '1' when (r_STATE = s_END) else '0';
end arch;
