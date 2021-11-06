-------------------
-- Núcleo Convolucional
-- 08/09/2021
-- George
-- R1

-- Descrição
-- Este bloco é composto por 18 registradores de deslocamento,
-- sendo 9 para os pixels de entrada e 9 para os pesos, 1 matriz
-- 3x3 de multiplicadores e uma arvore de somadores para
-- 9 valores.
-- Os valores de entrada serão de 8 bits de largura (com sinal),
-- os resultados da multiplicação serão de 16 bits e o resultado
-- da soma será de 32 bits.

-------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.STD_LOGIC_UNSIGNED.all;

-- Entity
entity nucleo_convolucional is
  generic (i_DATA_WIDTH : INTEGER := 8;
           w_CONV_OUT   : INTEGER := 16;           
           o_DATA_WIDTH : INTEGER := 32);
  

  port (
    i_CLK       : in STD_LOGIC;
    i_CLR       : in STD_LOGIC;
    
    -- habilita deslocamento dos registradores
    i_PIX_SHIFT_ENA : in STD_LOGIC;
    i_WEIGHT_SHIFT_ENA : in STD_LOGIC;    

    -- linhas de pixels
    i_PIX_ROW_1 : in STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);
    i_PIX_ROW_2 : in STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);
    i_PIX_ROW_3 : in STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);  
    
    -- habilita escrita em uma das linhas de pesos
    i_WEIGHT_ROW_SEL : in std_logic_vector (1 downto 0);
    
    -- peso de entrada
    i_WEIGHT : in STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);
    
    -- pixel de saida
    o_PIX       : out STD_LOGIC_VECTOR (o_DATA_WIDTH - 1 downto 0)

  );
end nucleo_convolucional;

--- Arch
architecture arch of nucleo_convolucional is
  
  type t_MAT is array (2 downto 0) of STD_LOGIC_VECTOR(i_DATA_WIDTH - 1 downto 0);
  type t_MULT_OUT_MAT is array (8 downto 0) of STD_LOGIC_VECTOR(w_CONV_OUT - 1 downto 0);
  
  -- registradores de deslocamento para os pixels
  signal w_PIX_ROW_1 : t_MAT := (others =>  ( others => '0'));
  signal w_PIX_ROW_2 : t_MAT := (others =>  ( others => '0'));
  signal w_PIX_ROW_3 : t_MAT := (others =>  ( others => '0'));
  
  -- registradores de deslocamento para os pesos
  signal w_WEIGHT_ROW_1 : t_MAT := (others =>  ( others => '0'));
  signal w_WEIGHT_ROW_2 : t_MAT := (others =>  ( others => '0'));
  signal w_WEIGHT_ROW_3 : t_MAT := (others =>  ( others => '0'));
  
  
  -- linhas de pesos
  signal w_i_WEIGHT_ROW_1 : STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);
  signal w_i_WEIGHT_ROW_2 : STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);
  signal w_i_WEIGHT_ROW_3 : STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);
  
  
  -- saida dos multiplicadores
  signal w_MULT_OUT : t_MULT_OUT_MAT := (others =>  ( others => '0'));
  
  -- Componentes
  
     
  -------------------------------
  -------------------------------
  component demux_1x4 is 
    PORT (  
      i_A           : IN  std_logic_vector(7 DOWNTO 0); -- peso
      i_SEL         : IN  std_logic_vector(1 DOWNTO 0); -- 2 bits para enderecamento entre as 3 linhas
      o_Q, o_R, o_S : OUT std_logic_vector(7 DOWNTO 0)
    );
  end component;  
  -------------------------------
    
  
  component multiplicador_conv is
    generic (i_DATA_WIDTH : INTEGER := 8;
             o_DATA_WIDTH : INTEGER := 16);
    port (              
      -- dados de entrada
      i_DATA_1 : in STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);
      i_DATA_2 : in STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);
      
      -- dado de saida
      o_DATA   : out STD_LOGIC_VECTOR (o_DATA_WIDTH - 1 downto 0)

    );
  end component;
  
  
  component arvore_soma_conv is
    generic (i_DATA_WIDTH : INTEGER := 16;           
             o_DATA_WIDTH : INTEGER := 32);

    port (
      i_DATA1  : in  STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);
      i_DATA2  : in  STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);
      i_DATA3  : in  STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);
      i_DATA4  : in  STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);
      i_DATA5  : in  STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);    
      i_DATA6  : in  STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);
      i_DATA7  : in  STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);
      i_DATA8  : in  STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);
      i_DATA9  : in  STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);
      o_DATA   : out STD_LOGIC_VECTOR (o_DATA_WIDTH - 1 downto 0)
    );
  end component;
  
begin
  p_DESLOCAMENTO : process (i_CLR, i_CLK)
  begin
    -- reset
    if (i_CLR = '1') then
      w_PIX_ROW_1 <= (others =>  ( others => '0'));
      w_PIX_ROW_2 <= (others =>  ( others => '0'));
      w_PIX_ROW_3 <= (others =>  ( others => '0'));
      
      w_WEIGHT_ROW_1 <= (others =>  ( others => '0'));
      w_WEIGHT_ROW_2 <= (others =>  ( others => '0'));
      w_WEIGHT_ROW_3 <= (others =>  ( others => '0'));
    
    elsif (rising_edge(i_CLK)) then
      
      -- desloca registradores de pixels
      if (i_PIX_SHIFT_ENA = '1') then     
                
        w_PIX_ROW_1(2) <= w_PIX_ROW_1(1); 
        w_PIX_ROW_2(2) <= w_PIX_ROW_2(1);
        w_PIX_ROW_3(2) <= w_PIX_ROW_3(1);
      
        w_PIX_ROW_1(1) <= w_PIX_ROW_1(0);
        w_PIX_ROW_2(1) <= w_PIX_ROW_2(0);
        w_PIX_ROW_3(1) <= w_PIX_ROW_3(0);
                
        w_PIX_ROW_1(0) <= i_PIX_ROW_1;
        w_PIX_ROW_2(0) <= i_PIX_ROW_2;
        w_PIX_ROW_3(0) <= i_PIX_ROW_3;
        
      end if;
      
      -- desloca registradores de pesos
      if (i_WEIGHT_SHIFT_ENA = '1' and i_WEIGHT_ROW_SEL = "00") then                  
        w_WEIGHT_ROW_1(2) <= w_WEIGHT_ROW_1(1);
        w_WEIGHT_ROW_1(1) <= w_WEIGHT_ROW_1(0);
        w_WEIGHT_ROW_1(0) <= w_i_WEIGHT_ROW_1;
      end if; 
      if (i_WEIGHT_SHIFT_ENA = '1' and i_WEIGHT_ROW_SEL = "01") then       
        w_WEIGHT_ROW_2(2) <= w_WEIGHT_ROW_2(1);
        w_WEIGHT_ROW_2(1) <= w_WEIGHT_ROW_2(0);
        w_WEIGHT_ROW_2(0) <= w_i_WEIGHT_ROW_2;
      end if; 
      if (i_WEIGHT_SHIFT_ENA = '1' and i_WEIGHT_ROW_SEL = "10") then               
        w_WEIGHT_ROW_3(2) <= w_WEIGHT_ROW_3(1);
        w_WEIGHT_ROW_3(1) <= w_WEIGHT_ROW_3(0);
        w_WEIGHT_ROW_3(0) <= w_i_WEIGHT_ROW_3;      
      end if;      
      
    end if;        
  end process;
  
  
  -- demultiplixa peso de entrada para linhas de pesos
  u_DEMUX_PEX : demux_1x4  
            port map
            (  
              i_A     => i_WEIGHT,      
              i_SEL   => i_WEIGHT_ROW_SEL,      
              o_Q     => w_i_WEIGHT_ROW_1, 
              o_R     => w_i_WEIGHT_ROW_2, 
              o_S     => w_i_WEIGHT_ROW_3
            );
    
  
  -- multiplicadores
  u_MUL_0 : multiplicador_conv 
              generic map (i_DATA_WIDTH, w_CONV_OUT)
              port map (w_PIX_ROW_1(0), w_WEIGHT_ROW_1(0), w_MULT_OUT(0));
        
  u_MUL_1 : multiplicador_conv 
              generic map (i_DATA_WIDTH, w_CONV_OUT)
              port map (w_PIX_ROW_1(1), w_WEIGHT_ROW_1(1), w_MULT_OUT(1));
  
  u_MUL_2 : multiplicador_conv 
              generic map (i_DATA_WIDTH, w_CONV_OUT)
              port map (w_PIX_ROW_1(2), w_WEIGHT_ROW_1(2), w_MULT_OUT(2));
  
  u_MUL_3 : multiplicador_conv 
              generic map (i_DATA_WIDTH, w_CONV_OUT)
              port map (w_PIX_ROW_2(0), w_WEIGHT_ROW_2(0), w_MULT_OUT(3));
  
  u_MUL_4 : multiplicador_conv 
              generic map (i_DATA_WIDTH, w_CONV_OUT)
              port map (w_PIX_ROW_2(1), w_WEIGHT_ROW_2(1), w_MULT_OUT(4));
  
  u_MUL_5 : multiplicador_conv 
              generic map (i_DATA_WIDTH, w_CONV_OUT)
              port map (w_PIX_ROW_2(2), w_WEIGHT_ROW_2(2), w_MULT_OUT(5));
  
  u_MUL_6 : multiplicador_conv 
              generic map (i_DATA_WIDTH, w_CONV_OUT)
              port map (w_PIX_ROW_3(0), w_WEIGHT_ROW_3(0), w_MULT_OUT(6));
  
  u_MUL_7 : multiplicador_conv 
              generic map (i_DATA_WIDTH, w_CONV_OUT)
              port map (w_PIX_ROW_3(1), w_WEIGHT_ROW_3(1), w_MULT_OUT(7));
  
  u_MUL_8 : multiplicador_conv 
              generic map (i_DATA_WIDTH, w_CONV_OUT)
              port map (w_PIX_ROW_3(2), w_WEIGHT_ROW_3(2), w_MULT_OUT(8));
  
  -- arvore de soma
  u_ARVORE_SOMA_CONV : arvore_soma_conv 
                        generic map (w_CONV_OUT, o_DATA_WIDTH)
                        port map (
                         w_MULT_OUT(0),
                         w_MULT_OUT(1),
                         w_MULT_OUT(2),
                         w_MULT_OUT(3),
                         w_MULT_OUT(4),
                         w_MULT_OUT(5),
                         w_MULT_OUT(6),
                         w_MULT_OUT(7),
                         w_MULT_OUT(8),                        
                         o_PIX 
                        );
            
  
end arch;
