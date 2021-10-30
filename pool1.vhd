-- pool1 top

-------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.STD_LOGIC_UNSIGNED.all;
library work;
use work.types_pkg.all;

-- Entity
entity pool1 is
  generic (    
    DATA_WIDTH   : integer := 8;
    ADDR_WIDTH   : integer := 10;
    NUM_CHANNELS : integer := 6
  );
  port (
    i_CLK       : in std_logic;
    i_CLR       : in std_logic; 
    i_GO        : in std_logic;
    o_READY     : out std_logic;
    
    -- sinais para buffer de entrada
    i_IN_DATA        : t_POOL1_IN  := (others => (others => '0')) ;
    i_IN_WRITE_ENA   : in std_logic;
    i_IN_WRITE_ADDR  : in std_logic_vector (ADDR_WIDTH - 1 downto 0) := (others => '0');
    i_IN_SEL_LINE    : in std_logic_vector (1 downto 0);
        
    -- sinais para buffer de saida
    i_OUT_READ_ADDR0  : in std_logic_vector (ADDR_WIDTH - 1 downto 0) := (others => '0');
    
    o_BUFFER_OUT : out t_POOL1_OUT := (others => (others => '0'))    
  );
end pool1;

--- Arch
architecture arch of pool1 is
    
  
  component pool1_crt is
    generic (
      DATA_WIDTH : integer := 8;
      ADDR_WIDTH : integer := 10;
      MAX_ADDR   : std_logic_vector := "0110000000" -- W*H/2 => 32*24/2 = 384
    );

    port (
      i_CLK           : in  std_logic;
      i_CLR           : in  std_logic;
      i_GO            : in  std_logic; -- inicia maq    
      o_READY         : out std_logic; -- fim maq
      o_IN_READ_ADDR0 : out std_logic_vector (ADDR_WIDTH - 1 downto 0);
      o_IN_READ_ADDR1 : out std_logic_vector (ADDR_WIDTH - 1 downto 0);    
      o_PIX_SHIFT_ENA : out  std_logic;
      o_OUT_WRITE_ENA : out  std_logic;               
      o_OUT_WRITE_ADDR  : out std_logic_vector (ADDR_WIDTH - 1 downto 0) := (others => '0')
    );
  end component;


  component pool1_op is
    generic (    
      DATA_WIDTH : integer := 8;
      ADDR_WIDTH : integer := 10;
      NUM_CHANNELS : integer := 6
    );
    port (
      i_CLK       : in  std_logic;
      i_CLR       : in  std_logic; 
      i_PIX_SHIFT_ENA : in STD_LOGIC;
      i_IN_DATA      : t_POOL1_IN  := (others => (others => '0'));
      i_IN_READ_ENA  : in std_logic;
      i_IN_WRITE_ENA : in std_logic;
      i_IN_SEL_LINE  : in std_logic_vector (1 downto 0);
      i_IN_READ_ADDR0  : in std_logic_vector (ADDR_WIDTH - 1 downto 0) := (others => '0');
      i_IN_READ_ADDR1  : in std_logic_vector (ADDR_WIDTH - 1 downto 0) := (others => '0');
      i_IN_WRITE_ADDR  : in std_logic_vector (ADDR_WIDTH - 1 downto 0) := (others => '0');
      i_OUT_READ_ENA    : in std_logic;
      i_OUT_WRITE_ENA   : in std_logic;
      i_OUT_SEL_LINE    : in std_logic_vector (1 downto 0);
      i_OUT_READ_ADDR0  : in std_logic_vector (ADDR_WIDTH - 1 downto 0) := (others => '0');
      i_OUT_WRITE_ADDR  : in std_logic_vector (ADDR_WIDTH - 1 downto 0) := (others => '0');      
      o_BUFFER_OUT : out t_POOL1_OUT := (others => (others => '0'))    
    );
  end component;

  
  signal w_IN_READ_ADDR0   : std_logic_vector (ADDR_WIDTH - 1 downto 0);
  signal w_IN_READ_ADDR1   : std_logic_vector (ADDR_WIDTH - 1 downto 0);    
  signal w_PIX_SHIFT_ENA   : std_logic;
  signal w_OUT_WRITE_ENA   : std_logic;               
  signal w_OUT_WRITE_ADDR  : std_logic_vector (ADDR_WIDTH - 1 downto 0) := (others => '0');

  
begin

       
  u_CONTROLE :  pool1_crt
                  generic map (
                    DATA_WIDTH => DATA_WIDTH,
                    ADDR_WIDTH => ADDR_WIDTH,
                    MAX_ADDR   => "0110000000"
                  )
                  port map (
                    i_CLK            => i_CLK  ,
                    i_CLR            => i_CLR  ,
                    i_GO             => i_GO   ,
                    o_READY          => o_READY,
                    o_IN_READ_ADDR0  => w_IN_READ_ADDR0  ,
                    o_IN_READ_ADDR1  => w_IN_READ_ADDR1  ,
                    o_PIX_SHIFT_ENA  => w_PIX_SHIFT_ENA  ,
                    o_OUT_WRITE_ENA  => w_OUT_WRITE_ENA  ,
                    o_OUT_WRITE_ADDR => w_OUT_WRITE_ADDR 
                  );


  u_OPERACIONAL : pool1_op 
                  generic map (    
                    DATA_WIDTH   => DATA_WIDTH   ,
                    ADDR_WIDTH   => ADDR_WIDTH   ,
                    NUM_CHANNELS => NUM_CHANNELS 
                  )
                  port map (
                    i_CLK            => i_CLK,
                    i_CLR            => i_CLR,
                    i_PIX_SHIFT_ENA  => w_PIX_SHIFT_ENA,
                    i_IN_DATA        => i_IN_DATA,
                    i_IN_READ_ENA    => '0',
                    i_IN_WRITE_ENA   => i_IN_WRITE_ENA,
                    i_IN_WRITE_ADDR  => i_IN_WRITE_ADDR,
                    i_IN_SEL_LINE    => i_IN_SEL_LINE,
                    i_IN_READ_ADDR0  => w_IN_READ_ADDR0,
                    i_IN_READ_ADDR1  => w_IN_READ_ADDR1,                    
                    i_OUT_READ_ENA   => '0',
                    i_OUT_WRITE_ENA  => w_OUT_WRITE_ENA  ,
                    i_OUT_WRITE_ADDR => w_OUT_WRITE_ADDR,
                    i_OUT_SEL_LINE   => "00",
                    i_OUT_READ_ADDR0 => i_OUT_READ_ADDR0,                    
                    o_BUFFER_OUT     => o_BUFFER_OUT
                  );
  
  
  
  
end arch;





