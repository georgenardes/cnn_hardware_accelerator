-- softmax top
-- 19/09/2021
-- George
-- R1

-- Descrição
-- O bloco softmax top é composto pelos 
-- blocos softmax operacional e controle.

-------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.STD_LOGIC_UNSIGNED.all;
USE ieee.numeric_std.ALL;
library work;
use work.types_pkg.all;

-- Entity
entity softmax_top is
  port ( 
    i_CLK      : in STD_LOGIC;
    i_CLR      : in STD_LOGIC;
    i_GO       : in STD_LOGIC;
    i_VET  : in t_SOFTMAX_VET; -- dados de entrada  
    o_VET  : out t_SOFTMAX_VET; -- dados de saida  
    o_READY : out std_logic
  );
end softmax_top;
  
  
--- Arch
architecture arch of softmax_top is

  -- controle
  component softmax_crt is
  port (    
    i_CLK       : in STD_LOGIC;
    i_CLR       : in STD_LOGIC;
    i_GO        : in STD_LOGIC;
    o_CLR_VET0  : out STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0);   
    o_CLR_VET1  : out STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0);   
    o_CLR_VET2  : out STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0); 
    o_ENA_VET0  : out STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0);      
    o_ENA_VET1  : out STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0);      
    o_ENA_VET2  : out STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0); 
    o_SEL_MUX0  : out  std_logic_vector(6 DOWNTO 0);
    o_SEL_MUX1  : out  std_logic_vector(6 DOWNTO 0);
    o_SEL_DEMUX0  : out  std_logic_vector(6 DOWNTO 0);
    o_SEL_DEMUX1  : out  std_logic_vector(6 DOWNTO 0);
    o_ACC_ENA   : out std_logic;
    o_ACC_CLR   : out std_logic;
    o_READY     : out std_logic
  );
  end component;
  
  
  -- operacional
  component softmax_op is
  port (
    i_CLK       : in STD_LOGIC;
    i_CLR_VET0  : in STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0);   
    i_CLR_VET1  : in STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0);   
    i_CLR_VET2  : in STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0);
    i_ENA_VET0  : in STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0);      
    i_ENA_VET1  : in STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0);      
    i_ENA_VET2  : in STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0);   
    i_SEL_MUX0  : IN  std_logic_vector(6 DOWNTO 0);
    i_SEL_MUX1  : IN  std_logic_vector(6 DOWNTO 0);
    i_SEL_DEMUX0  : IN  std_logic_vector(6 DOWNTO 0);
    i_SEL_DEMUX1  : IN  std_logic_vector(6 DOWNTO 0);
    i_ACC_ENA   : in std_logic;
    i_ACC_CLR   : in std_logic;
    i_VET       : in t_SOFTMAX_VET; -- dados de entrada  
    o_VET       : out t_SOFTMAX_VET -- dados de saida  
  );  
  end component;
  
  -- sinais
  signal w_CLR_VET0  : STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0);   
  signal w_CLR_VET1  : STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0);   
  signal w_CLR_VET2  : STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0); 
  signal w_ENA_VET0  : STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0);      
  signal w_ENA_VET1  : STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0);      
  signal w_ENA_VET2  : STD_LOGIC_VECTOR (c_SOFTMAX_IN_WIDHT - 1 downto 0); 
  signal w_SEL_MUX0  : std_logic_vector(6 DOWNTO 0);
  signal w_SEL_MUX1  : std_logic_vector(6 DOWNTO 0);
  signal w_SEL_DEMUX0  : std_logic_vector(6 DOWNTO 0);
  signal w_SEL_DEMUX1  : std_logic_vector(6 DOWNTO 0);
  signal w_ACC_ENA   : std_logic;
  signal w_ACC_CLR   : std_logic;
    
    
begin
  u_CONTROL : softmax_crt
              port map (
                i_CLK         => i_CLK,
                i_CLR         => i_CLR,
                i_GO          => i_GO,
                o_CLR_VET0    => w_CLR_VET0  ,
                o_CLR_VET1    => w_CLR_VET1  ,
                o_CLR_VET2    => w_CLR_VET2  ,
                o_ENA_VET0    => w_ENA_VET0  ,
                o_ENA_VET1    => w_ENA_VET1  ,
                o_ENA_VET2    => w_ENA_VET2  ,
                o_SEL_MUX0    => w_SEL_MUX0  ,
                o_SEL_MUX1    => w_SEL_MUX1  ,
                o_SEL_DEMUX0  => w_SEL_DEMUX0,
                o_SEL_DEMUX1  => w_SEL_DEMUX1,
                o_ACC_ENA     => w_ACC_ENA   ,
                o_ACC_CLR     => w_ACC_CLR   ,
                o_READY       => o_READY
              );
               
  u_OP : softmax_op 
              port map (
                i_CLK         => i_CLK, 
                i_CLR_VET0    => w_CLR_VET0,
                i_CLR_VET1    => w_CLR_VET1,
                i_CLR_VET2    => w_CLR_VET2,
                i_ENA_VET0    => w_ENA_VET0,
                i_ENA_VET1    => w_ENA_VET1,
                i_ENA_VET2    => w_ENA_VET2,
                i_SEL_MUX0    => w_SEL_MUX0,
                i_SEL_MUX1    => w_SEL_MUX1,
                i_SEL_DEMUX0  => w_SEL_DEMUX0,
                i_SEL_DEMUX1  => w_SEL_DEMUX1,
                i_ACC_ENA     => w_ACC_ENA,
                i_ACC_CLR     => w_ACC_CLR,
                i_VET         => i_VET,
                o_VET         => o_VET
              );

end arch;
