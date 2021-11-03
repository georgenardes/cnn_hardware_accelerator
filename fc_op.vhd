-- operacional fc
-------------------

-------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.STD_LOGIC_UNSIGNED.all;
library work;
use work.types_pkg.all;


-- Entity
entity fc_op is
  generic 
  (
    DATA_WIDTH : INTEGER := 8;           
    ADDR_WIDTH : INTEGER := 10;
    NUM_CHANNELS : integer := 64;
    NUM_UNITS : integer := 35
    
  );

  port (
    i_CLK       : in STD_LOGIC;
    i_CLR       : in STD_LOGIC;
    
    -- pixels de entrada
    i_PIX      : in  std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    
    -- PESO DE ENTRADA
    i_WEIGHT       : in t_ARRAY_OF_LOGIC_VECTOR(0 to NUM_UNITS-1)(DATA_WIDTH-1 downto 0) := (others => (others => '0'));
    
    -- habilita registradores de pixel e peso
    i_REG_PIX_ENA : in std_logic;
    i_REG_PES_ENA : in std_logic;
    
    -- habilita acumulador
    i_ACC_ENA : std_logic;
    i_ACC_CLR   : in STD_LOGIC;
    
    -- valores de saida
    o_PIX       : out t_ARRAY_OF_LOGIC_VECTOR(0 to NUM_UNITS-1)(DATA_WIDTH-1 downto 0) := (others => (others => '0'))

  );
end fc_op;



--- Arch
architecture arch of fc_op is
  
    
  -- Entity
  component neuronio is
    generic (i_DATA_WIDTH : INTEGER := 8;           
             o_DATA_WIDTH : INTEGER := 8);
    
    port (
      i_CLK       : in STD_LOGIC;
      i_CLR       : in STD_LOGIC;
      i_ACC_ENA   : in STD_LOGIC;
      i_REG_PIX_ENA : in STD_LOGIC;
      i_REG_PES_ENA : in STD_LOGIC;
      i_ACC_CLR   : in STD_LOGIC;
      i_PIX       : in STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);
      i_PES       : in STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);
      o_PIX       : out STD_LOGIC_VECTOR (o_DATA_WIDTH - 1 downto 0)
    );
  end component;
  
begin

  GEN_UNITS:
  for i in 0 to (NUM_UNITS-1) generate  
  begin
    
    u_UNIT : neuronio
        generic map (8, 8)
        port map
        (
          i_CLK         => i_CLK       ,
          i_CLR         => i_CLR       ,
          i_ACC_ENA     => i_ACC_ENA   ,
          i_REG_PIX_ENA => i_REG_PIX_ENA,
          i_REG_PES_ENA => i_REG_PES_ENA,          
          i_ACC_CLR     => i_ACC_CLR,
          i_PIX         => i_PIX,
          i_PES         => i_WEIGHT(i),
          o_PIX         => o_PIX(i)
        );
    
    
  end generate GEN_UNITS;
  
end arch;
