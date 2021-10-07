-------------------
-- Neurônio
-- 12/09/2021
-- George
-- R1

-- Descrição
-- Este bloco é composto por 1 multiplicador de 8 bits e um
-- acumulador de 32 bits.

-------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.STD_LOGIC_UNSIGNED.all;

-- Entity
entity neuronio is
  generic (i_DATA_WIDTH : INTEGER := 8;           
           o_DATA_WIDTH : INTEGER := 32);
  
  port (
    i_CLK       : in STD_LOGIC;
    i_CLR       : in STD_LOGIC;
    
    -- habilita registrador acumulador, registrador pixel e peso
    i_ACC_ENA : in STD_LOGIC;
    i_REG_PIX_ENA : in STD_LOGIC;
    i_REG_PES_ENA : in STD_LOGIC;
    
    -- reseta acumulador
    i_ACC_CLR : in STD_LOGIC;
    
    -- pixel de entrada
    i_PIX : in STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);

    -- peso de entrada
    i_PES : in STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);
    
    -- pixel de saida
    o_PIX       : out STD_LOGIC_VECTOR (o_DATA_WIDTH - 1 downto 0)

  );
end neuronio;

--- Arch
architecture arch of neuronio is
  
  -- multiplicador de 8 bit
  component pmul8 is  -- 8 x 8 = 16 bit unsigned product multiplier
  port(a : in  std_logic_vector(7 downto 0);  -- multiplicand
       b : in  std_logic_vector(7 downto 0);  -- multiplier
       p : out std_logic_vector(15 downto 0)); -- product
  end component;
  
  -- somador 32 bits
  component add32 is
    port (
      a : in  STD_LOGIC_VECTOR(o_DATA_WIDTH -1 downto 0); 
      b : in  STD_LOGIC_VECTOR(o_DATA_WIDTH -1 downto 0);
      cin  : in  STD_LOGIC;
      sum1 : out STD_LOGIC_VECTOR(o_DATA_WIDTH -1 downto 0);
      cout : out STD_LOGIC);
  end component;
  
    
  -- saida multiplicador, mas com 32 bits (pois será entrada do somador)
  signal w_MULT_OUT : std_logic_vector(o_DATA_WIDTH-1 downto 0) := (others => '0'); 
  
  -- saida somador
  signal w_ADD_OUT : std_logic_vector(o_DATA_WIDTH-1 downto 0) := (others => '0'); 
  
  -- registradores pixel, peso e acumulador
  signal r_PIX, r_PES : std_logic_vector(i_DATA_WIDTH-1 downto 0);   
  signal r_ACC : std_logic_vector(o_DATA_WIDTH-1 downto 0); 
  
  -- carryout do acumulador;
  signal w_COUT : std_logic;
  
begin
  p_INPUT_REG : process (i_CLR, i_CLK, i_PIX, i_PES)
  begin
    -- reset
    if (i_CLR = '1') then
      r_PIX <= (others => '0');
      r_PES <= (others => '0');      
         
    -- subida de clock 
    elsif (rising_edge(i_CLK)) then
               
      -- registra pixel de entrada
      if (i_REG_PIX_ENA = '1') then       
        r_PIX <= i_PIX;
      end if;      
      
      -- registra peso de entrada
      if (i_REG_PES_ENA = '1') then       
        r_PES <= i_PES;
      end if;      
      
    end if;  
  end process;
  
  p_REG_ACC : process (i_CLR, i_CLK, i_ACC_CLR)
  begin
    -- reseta acumulador
    if (i_CLR = '1' or i_ACC_CLR = '1') then      
      r_ACC <= (others => '0');
      
    -- subida de clock 
    elsif (rising_edge(i_CLK)) then
         
      -- acumula resultado da multiplicacao
      if (i_ACC_ENA = '1') then     
        r_ACC <= w_ADD_OUT;
      end if;
            
    end if;        
  end process;
  
  
  -- multiplicador
  u_MUL : pmul8 port map (r_PIX, r_PES, w_MULT_OUT(15 downto 0));
  
  -- somador
  u_ADD : add32 port map (r_ACC, w_MULT_OUT, '0', w_ADD_OUT, w_COUT);
  
  -- saida
  o_PIX <= w_ADD_OUT;           
  
end arch;
