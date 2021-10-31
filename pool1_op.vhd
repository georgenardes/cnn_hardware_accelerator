-- maxpool1 operacional

-------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.STD_LOGIC_UNSIGNED.all;
library work;
use work.types_pkg.all;

-- Entity
entity pool1_op is
  generic (    
    DATA_WIDTH : integer := 8;
    ADDR_WIDTH : integer := 10;
    NUM_CHANNELS : integer := 6
  );
  port (
    i_CLK       : in  std_logic;
    i_CLR       : in  std_logic; 
    
    -- habilita deslocamento dos pixels no bloco op
    i_PIX_SHIFT_ENA : in STD_LOGIC;
    
    -- sinais para buffer de enbtrada
    i_IN_DATA      : in  t_ARRAY_OF_LOGIC_VECTOR(0 to NUM_CHANNELS-1)(DATA_WIDTH-1 downto 0) := (others => (others => '0'));
    i_IN_READ_ENA  : in std_logic;
    i_IN_WRITE_ENA : in std_logic;
    i_IN_SEL_LINE  : in std_logic_vector (1 downto 0);
    i_IN_READ_ADDR0  : in std_logic_vector (ADDR_WIDTH - 1 downto 0) := (others => '0');
    i_IN_READ_ADDR1  : in std_logic_vector (ADDR_WIDTH - 1 downto 0) := (others => '0');
    i_IN_WRITE_ADDR  : in std_logic_vector (ADDR_WIDTH - 1 downto 0) := (others => '0');
    -- sinais para buffer de saida
    i_OUT_READ_ENA    : in std_logic;
    i_OUT_WRITE_ENA   : in std_logic;
    i_OUT_SEL_LINE    : in std_logic_vector (1 downto 0);
    i_OUT_READ_ADDR0  : in std_logic_vector (ADDR_WIDTH - 1 downto 0) := (others => '0');
    i_OUT_WRITE_ADDR  : in std_logic_vector (ADDR_WIDTH - 1 downto 0) := (others => '0');
    
    o_BUFFER_OUT : out t_ARRAY_OF_LOGIC_VECTOR(0 to NUM_CHANNELS-1)(DATA_WIDTH-1 downto 0) := (others => (others => '0'))
  );
end pool1_op;

--- Arch
architecture arch of pool1_op is
    
  
  -- max_pool component
  component max_pooling is
    generic (DATA_WIDTH : INTEGER := 8);
    port (
      i_CLK       : in STD_LOGIC;
      i_CLR       : in STD_LOGIC;
      i_PIX_SHIFT_ENA : in STD_LOGIC;    
      i_PIX_ROW_1 : in STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
      i_PIX_ROW_2 : in STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
      o_PIX       : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0)
    );
  end component;
  
  -- buffer de entrada
  component io_buffer is
    generic 
    (
      NUM_BLOCKS : integer := 3;    
      DATA_WIDTH : integer := 8;    
      ADDR_WIDTH : integer := 10 -- 2**10  enderecos
    );    
    port 
    (
      i_CLK       : in  std_logic;
      i_CLR       : in  std_logic;
      i_DATA      : in  std_logic_vector (DATA_WIDTH - 1 downto 0);
      i_READ_ENA  : in std_logic := '0';
      i_WRITE_ENA : in std_logic;
      i_SEL_LINE  : in std_logic_vector (1 downto 0);
      i_READ_ADDR0   : in std_logic_vector (ADDR_WIDTH - 1 downto 0) := (others => '0');
      i_READ_ADDR1   : in std_logic_vector (ADDR_WIDTH - 1 downto 0) := (others => '0');
      i_READ_ADDR2   : in std_logic_vector (ADDR_WIDTH - 1 downto 0) := (others => '0');
      i_WRITE_ADDR  : in std_logic_vector (ADDR_WIDTH - 1 downto 0) := (others => '0');
      o_DATA_ROW_0  : out std_logic_vector (DATA_WIDTH - 1 downto 0);
      o_DATA_ROW_1  : out std_logic_vector (DATA_WIDTH - 1 downto 0);
      o_DATA_ROW_2  : out std_logic_vector (DATA_WIDTH - 1 downto 0)
    );
  end component;  
      
  -- linha de pixels
  signal w_PIX_ROW_1, w_PIX_ROW_2, w_o_PIX : t_ARRAY_OF_LOGIC_VECTOR(0 to NUM_CHANNELS-1)(DATA_WIDTH-1 downto 0) := (others => (others => '0'));
  
begin

       
  -- instanciar os rebuffer para cada canal
  GEN_CHANNELS : 
  for i in 0 to (NUM_CHANNELS-1) generate  
  begin
  
    u_BUFFER_IN : io_buffer 
                      generic map
                      (
                        NUM_BLOCKS => 2,   
                        DATA_WIDTH => 8,   
                        ADDR_WIDTH => 10 
                      )    
                      port map
                      (
                        i_CLK        => i_CLK ,
                        i_CLR        => i_CLR ,
                        i_DATA       => i_IN_DATA(i), -- dado para escrita em uma das linhas do buffer
                        i_READ_ENA   => i_IN_READ_ENA,
                        i_WRITE_ENA  => i_IN_WRITE_ENA,
                        i_SEL_LINE   => i_IN_SEL_LINE,
                        i_READ_ADDR0 => i_IN_READ_ADDR0,
                        i_READ_ADDR1 => i_IN_READ_ADDR1,
                        i_READ_ADDR2 => (others => '0'),
                        i_WRITE_ADDR => i_IN_WRITE_ADDR,
                        o_DATA_ROW_0 => w_PIX_ROW_1(i),
                        o_DATA_ROW_1 => w_PIX_ROW_2(i)
                        -- o_DATA_ROW_2 => 
                      );  
  
    
    u_MAX_POOL : max_pooling 
                    generic map (DATA_WIDTH)
                    port map 
                    (
                      i_CLK      => i_CLK,
                      i_CLR      => i_CLR,                      
                      i_PIX_SHIFT_ENA => i_PIX_SHIFT_ENA,
                      i_PIX_ROW_1 => w_PIX_ROW_1(i),
                      i_PIX_ROW_2 => w_PIX_ROW_2(i),
                      o_PIX       => w_o_PIX(i)
                    );        
    
    
    u_BUFFER_OUT : io_buffer 
                      generic map
                      (
                        NUM_BLOCKS => 1,   
                        DATA_WIDTH => 8,   
                        ADDR_WIDTH => 10 
                      )    
                      port map
                      (
                        i_CLK        => i_CLK ,
                        i_CLR        => i_CLR ,
                        i_DATA       => w_o_PIX(i), -- dado para escrita em uma das linhas do buffer
                        i_READ_ENA   => i_OUT_READ_ENA,
                        i_WRITE_ENA  => i_OUT_WRITE_ENA,
                        i_SEL_LINE   => i_OUT_SEL_LINE,
                        i_READ_ADDR0 => i_OUT_READ_ADDR0,
                        i_READ_ADDR1 => (others => '0'),
                        i_READ_ADDR2 => (others => '0'),
                        i_WRITE_ADDR => i_OUT_WRITE_ADDR,
                        o_DATA_ROW_0 => o_BUFFER_OUT(i)
                      );      
    
  end generate GEN_CHANNELS;
  
  
end arch;





