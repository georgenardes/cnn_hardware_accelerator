-- bloco opercional softmax
-- 15/09/2021
-- George
-- R1

-- Descrição
-- Este bloco realiza as operções do bloco
-- softmax

-------------------

library ieee;
use ieee.std_logic_1164.all;
library work;
use work.types_pkg.all;


-- Entity
entity softmax_op is
  port (
    i_CLK      : in STD_LOGIC;
    
    -- SINAIS DE CONTROLE
    -- clear
    i_CLR_VET0 : in STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0);   
    i_CLR_VET1 : in STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0);   
    i_CLR_VET2 : in STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0);
    
    -- enable
    i_ENA_VET0 : in STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0);      
    i_ENA_VET1 : in STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0);      
    i_ENA_VET2 : in STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0);   
    
    -- sel mux
    i_SEL_MUX0  : IN  std_logic_vector(6 DOWNTO 0);
    i_SEL_MUX1  : IN  std_logic_vector(6 DOWNTO 0);
    
    -- sel demux
    i_SEL_DEMUX0  : IN  std_logic_vector(6 DOWNTO 0);
    i_SEL_DEMUX1  : IN  std_logic_vector(6 DOWNTO 0);
    
    -- enable acumulador
    i_ACC_ENA : in std_logic;
    
    -- clear acumulador
    i_ACC_CLR : in std_logic;
    
    -- SINAIS DE DADOS
    i_VET  : in t_SOFTMAX_VET; -- dados de entrada  
    o_VET  : out t_SOFTMAX_VET -- dados de saida  
  );  
end softmax_op;

--- Arch
architecture arch of softmax_op is
  
  component reg_array is    
    port 
    (
      i_CLK     : in STD_LOGIC;              
      i_CLR_VET : in STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0);          
      i_ENA_VET : in STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0);          
      i_VET     : in t_SOFTMAX_VET; -- dados de entrada         
      o_VET     : OUT t_SOFTMAX_VET    
    );
  end component;
    
  component mux_35_x_1 is             
    PORT 
    (  
      i_A    : IN  t_SOFTMAX_VET;
      i_SEL  : IN  std_logic_vector(6 DOWNTO 0); 
      o_Q    : OUT std_logic_vector(c_SOFTMAX_DATA_WIDTH - 1 DOWNTO 0)
    );
  END component;

  component demux_1_x_35 is             
    PORT 
    (  
      i_A    : IN  std_logic_vector(c_SOFTMAX_DATA_WIDTH - 1 DOWNTO 0);
      i_SEL  : IN  std_logic_vector(6 DOWNTO 0); 
      o_Q    : OUT t_SOFTMAX_VET
    );
  END component;
  
  
  component softmax_enax_mem IS
    PORT
    (
      address	: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
      clock		: IN STD_LOGIC  := '1';
      q		    : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
    );
  END component;
  
  component add32 is
    PORT 
    (  
      a         : IN  std_logic_vector(31 DOWNTO 0);
      b         : IN  std_logic_vector(31 DOWNTO 0);
      cin       : IN  STD_LOGIC;
      sum1      : OUT std_logic_vector(31 DOWNTO 0);
      cout      : OUT std_logic;
      overflow  : out std_logic;
      underflow : out std_logic
    );
  END component;
  
  component registrador is 
    generic ( DATA_WIDTH : INTEGER := 8);         
    PORT 
    (  
      i_CLK       : IN  std_logic;
      i_CLR       : IN  std_logic;
      i_ENA       : IN  std_logic;
      i_A         : IN  std_logic_vector(DATA_WIDTH - 1 DOWNTO 0);          
      o_Q         : OUT std_logic_vector(DATA_WIDTH - 1 DOWNTO 0)
    );
  END component;
  
  component divisor is    
    port 
    (    
      i_DIVIDENDO : in STD_LOGIC_VECTOR (c_SOFTMAX_DATA_WIDTH - 1 downto 0);       
      i_DIVISOR   : in STD_LOGIC_VECTOR (c_SOFTMAX_DATA_WIDTH - 1 downto 0);
      o_RES       : OUT STD_LOGIC_VECTOR (c_SOFTMAX_DATA_WIDTH - 1 downto 0)
    );
  end component;
  
  -- saida do primeiro vetor de registrador
  -- entrada do primeiro mux
  signal w_REG_VET0 : t_SOFTMAX_VET;
  
  -- saida do primeiro mux
  -- entrada da lut enax
  signal w_OUT_MUX0 : STD_LOGIC_VECTOR (c_SOFTMAX_DATA_WIDTH - 1 downto 0);   

  -- saida lut enax
  -- entrada primeiro demux
  signal w_OUT_ENAX : STD_LOGIC_VECTOR (c_SOFTMAX_DATA_WIDTH - 1 downto 0);   
  
  -- saida do primeiro demux
  -- entrada do segundo vetor de registrador
  signal w_OUT_DEMUX0 : t_SOFTMAX_VET;
  
  -- saida do segundo vetor de registrador
  -- entrada do segundo mux
  signal w_REG_VET1 : t_SOFTMAX_VET;
  
  -- saida do segundo mux
  -- entrada do bloco divisor
  signal w_OUT_MUX1 : STD_LOGIC_VECTOR (c_SOFTMAX_DATA_WIDTH - 1 downto 0);  
  
  
  -- saida divisor
  -- entrada do segundo demux
  signal w_OUT_DIV : STD_LOGIC_VECTOR (c_SOFTMAX_DATA_WIDTH - 1 downto 0);  
  
  -- saida do segundo demux
  -- entrada do terceiro vetor de registrador
  signal w_OUT_DEMUX1 : t_SOFTMAX_VET;
  
  
  -- somador
  signal r_ADD_DIVISOR : STD_LOGIC_VECTOR (c_SOFTMAX_DATA_WIDTH - 1 downto 0);
  
begin
  
  -- acumulador process
  process (i_CLK, i_ACC_ENA, i_ACC_CLR, w_OUT_ENAX)
  begin
    if (i_ACC_CLR = '1') then 
      r_ADD_DIVISOR <= (others => '0');
    elsif (rising_edge(i_CLK)) then
      if (i_ACC_ENA = '1') then
        r_ADD_DIVISOR <= w_OUT_ENAX;
      end if;
    end if;
  end process;
  
  
  
  u_REG_ARRAY0 : reg_array 
                  port map 
                    ( i_CLK, 
                      i_CLR_VET0,
                      i_ENA_VET0,
                      i_VET,
                      w_REG_VET0
                    );
  
  u_MUX0 : mux_35_x_1 
                  PORT map
                    (  
                      w_REG_VET0,    
                      i_SEL_MUX0,
                      w_OUT_MUX0
                    );
  
  u_ENAX : softmax_enax_mem 
                  PORT map
                    (
                      w_OUT_MUX0,
                      i_CLK,
                      w_OUT_ENAX
                    );

  u_DEMUX0 : demux_1_x_35   
                  PORT map
                    (  
                      w_OUT_ENAX,
                      i_SEL_DEMUX0,
                      w_OUT_DEMUX0
                    );

  u_REG_ARRAY1 : reg_array 
                  port map 
                    ( i_CLK, 
                      i_CLR_VET1,
                      i_ENA_VET1,
                      w_OUT_DEMUX0,
                      w_REG_VET1
                    ); 
  
  u_MUX1 : mux_35_x_1 
                  PORT map
                    (  
                      w_REG_VET1,    
                      i_SEL_MUX1,
                      w_OUT_MUX1
                    );
 
  u_DIVISOR : divisor 
                  port map
                    (    
                      w_OUT_MUX1,
                      r_ADD_DIVISOR,
                      w_OUT_DIV
                    );
                    
  u_DEMUX1 : demux_1_x_35   
                  PORT map
                    (  
                      w_OUT_DIV,
                      i_SEL_DEMUX1,
                      w_OUT_DEMUX1
                    );

  u_REG_ARRAY2 : reg_array 
                  port map 
                    ( i_CLK, 
                      i_CLR_VET2,
                      i_ENA_VET2,
                      w_OUT_DEMUX1,
                      o_VET
                    ); 

end arch;
