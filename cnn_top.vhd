-- CNN top file
-- integra todas as camadas da rede


library ieee;
use ieee.std_logic_1164.all;
library work;
use work.conv1_pkg.all;
use work.types_pkg.all;


entity cnn_top is
  port 
  (
    i_CLK       : in STD_LOGIC;
    i_CLR       : in STD_LOGIC;
    i_GO        : in STD_LOGIC;
    i_LOAD      : in std_logic;
    o_READY     : out std_logic
  );
end cnn_top;

architecture arch of cnn_top is 
  constant ADDR_WIDTH : integer := 10;
  constant DATA_WIDTH : integer := 8;

  
  -- bloco rom para imagem de entrada  
  component image_chanel IS
    generic
    (
      init_file_name : STRING := "input_chanel_1.mif"
    );
    port
    (
      address	: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
      clock		: IN STD_LOGIC  := '1';
      rden		: IN STD_LOGIC  := '1';
      q		    : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
    );
  end component;

  --------------------------------------------------------
  -- bloco rebuffer
  component rebuff1 is
    generic (
      ADDR_WIDTH : integer := 10;
      DATA_WIDTH : integer := 8;    
      NUM_BUFFER_LINES   : std_logic_vector(1 downto 0)   := "10";      -- 3 buffers
      IFMAP_WIDTH : std_logic_vector(5 downto 0)  := "011000";  -- 24
      IFMAP_HEIGHT : std_logic_vector(5 downto 0) := "100000";  -- 32
      OFMAP_WIDTH : std_logic_vector(5 downto 0)  := "011010";  -- 26
      OFMAP_HEIGHT : std_logic_vector(5 downto 0) := "100010";  -- 34
      PAD_H : std_logic_vector(5 downto 0)        := "100001";  -- 33 (indice para adicionar pad linha de baixo)
      PAD_W : std_logic_vector(5 downto 0)        := "011001"   -- 25 (indice para adicionar pad coluna da direita)
    );
    port (
      i_CLK       : in  std_logic;
      i_CLR       : in  std_logic;
      i_GO        : in  std_logic;
      i_DATA      : in  t_REBBUF1_IN;
      o_READ_ENA  : out std_logic;
      o_IN_ADDR   : out std_logic_vector (ADDR_WIDTH - 1 downto 0);
      o_OUT_ADDR  : out std_logic_vector (ADDR_WIDTH - 1 downto 0);
      o_WRITE_ENA : out std_logic;
      o_DATA      : out t_CONV1_IN;
      o_SEL_BUFF_LINE  : out std_logic_vector (1 downto 0);
      o_READY     : out std_logic
    );
  end component;
  
  ----------------------------------------------------------  
  
  -- primeira camada convolucional
  component conv1 is
    generic 
    (
      ADDR_WIDTH : integer := 10; 
      DATA_WIDTH : integer := 8
      
    );
    port 
    (
      i_CLK       : in STD_LOGIC;
      i_CLR       : in STD_LOGIC;
      i_GO        : in STD_LOGIC;
      i_LOAD      : in std_logic;
      o_READY     : out std_logic;
      i_IN_DATA       : t_CONV1_IN;
      i_IN_WRITE_ENA  : in std_logic;    
      i_IN_SEL_LINE   : in std_logic_vector (1 downto 0); 
      i_IN_WRITE_ADDR : in std_logic_vector (ADDR_WIDTH - 1 downto 0);
      i_OUT_READ_ENA  : in std_logic;
      i_OUT_READ_ADDR : in std_logic_vector (ADDR_WIDTH - 1 downto 0);
      o_OUT_DATA : out t_CONV1_OUT
    );
  end component;
  
  ---------------------------------------------------
  
  component rebuff2 is
    generic (
      ADDR_WIDTH : integer := 10;
      DATA_WIDTH : integer := 8;    
      NUM_BUFFER_LINES   : std_logic_vector(1 downto 0)   := "11";    -- 3 buffers
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
      i_DATA      : in  t_CONV1_OUT;
      o_READ_ENA  : out std_logic;
      o_IN_ADDR   : out std_logic_vector (ADDR_WIDTH - 1 downto 0);
      o_OUT_ADDR  : out std_logic_vector (ADDR_WIDTH - 1 downto 0);
      o_WRITE_ENA : out std_logic;
      o_DATA      : out t_POOL1_IN;
      o_SEL_BUFF_LINE  : out std_logic_vector (1 downto 0);
      o_READY     : out std_logic
    );
  end component;

  ---------------------------------------------------
  
  component pool1 is
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
      i_IN_DATA        : in t_POOL1_IN  := (others => (others => '0')) ;
      i_IN_WRITE_ENA   : in std_logic;
      i_IN_WRITE_ADDR  : in std_logic_vector (ADDR_WIDTH - 1 downto 0) := (others => '0');
      i_IN_SEL_LINE    : in std_logic_vector (1 downto 0);
      i_OUT_READ_ADDR0  : in std_logic_vector (ADDR_WIDTH - 1 downto 0) := (others => '0');
      o_BUFFER_OUT : out t_POOL1_OUT := (others => (others => '0'))    
    );
  end component;
  
  ----------------------------------------------------
  
  component rebuff3 is
    generic (
      ADDR_WIDTH : integer := 10;
      DATA_WIDTH : integer := 8;    
      NUM_BUFFER_LINES   : std_logic_vector(1 downto 0)   := "11";    -- 3 buffers
      IFMAP_WIDTH : std_logic_vector(5 downto 0)  := "001100";  -- 12
      IFMAP_HEIGHT : std_logic_vector(5 downto 0) := "010000";  -- 16
      OFMAP_WIDTH : std_logic_vector(5 downto 0)  := "001110";  -- 14
      OFMAP_HEIGHT : std_logic_vector(5 downto 0) := "010010";  -- 18    
      PAD_W : std_logic_vector(5 downto 0)        := "001101"; -- 13 (indice para adicionar pad coluna da direita)
      PAD_H : std_logic_vector(5 downto 0)        := "010001"  -- 17 (indice para adicionar pad linha de baixo)
    );
    port (
      i_CLK       : in  std_logic;
      i_CLR       : in  std_logic;
      i_GO        : in  std_logic;
      i_DATA      : in  t_POOL1_OUT;
      o_READ_ENA  : out std_logic;
      o_IN_ADDR   : out std_logic_vector (ADDR_WIDTH - 1 downto 0);
      o_OUT_ADDR  : out std_logic_vector (ADDR_WIDTH - 1 downto 0);
      o_WRITE_ENA : out std_logic;
      o_DATA      : out t_CONV2_IN;
      o_SEL_BUFF_LINE  : out std_logic_vector (1 downto 0);
      o_READY     : out std_logic
    );
  end component;  
  
  ---------------------------------------------------------
  
  
  component conv2 is
    generic 
    (
      DATA_WIDTH : integer := 8;
      ADDR_WIDTH : integer := 10
    );
    port 
    (
      i_CLK       : in STD_LOGIC;
      i_CLR       : in STD_LOGIC;
      i_GO        : in STD_LOGIC;
      i_LOAD      : in std_logic;
      o_READY     : out std_logic;
      i_IN_DATA       : t_CONV1_IN;
      i_IN_WRITE_ENA  : in std_logic;    
      i_IN_SEL_LINE   : in std_logic_vector (1 downto 0); 
      i_IN_WRITE_ADDR : in std_logic_vector (ADDR_WIDTH - 1 downto 0);
      i_OUT_READ_ENA  : in std_logic;
      i_OUT_READ_ADDR : in std_logic_vector (ADDR_WIDTH - 1 downto 0) := (others => '0');
      o_OUT_DATA : out t_CONV1_OUT      
    );
  end component;
  
  
  
  
  --------------- sinais rebuff1  
  -- dado de entrada
  signal w_REBUFF1_DATA_IN      : t_REBBUF1_IN;
  -- habilita leitura
  signal w_IMG_READ_ENA  :  std_logic;
  -- endereco a ser lido
  signal w_IMG_READ_ADDR   :  std_logic_vector (ADDR_WIDTH - 1 downto 0);
  -- endereco a ser escrito
  signal w_REBUFF1_WRITE_ADDR  :  std_logic_vector (ADDR_WIDTH - 1 downto 0);
  -- habilita escrita    
  signal w_REBUFF1_WRITE_ENA :  std_logic;
  -- dado de saida (mesmo q o de entrada)
  signal w_REBUFF1_DATA_OUT      :  t_CONV1_IN;
  -- linha de buffer selecionada
  signal w_REBUFF1_SEL_LINE   :  std_logic_vector (1 downto 0);   
  -- sinal ready reuffer 1
  signal w_REBUFF1_READY     :  std_logic;
  
    
  -------- SINAIS CONV1
  signal w_COVN1_GO        : STD_LOGIC;
  signal w_COVN1_LOAD      : std_logic;
  signal w_COVN1_READY     : std_logic;  
  --------------------------------------------------  
  
  -- saida dos buffers de saida da conv1
  signal w_CONV1_DATA_OUT : t_CONV1_OUT := (others => (others => '0'));
  
  
  
  
  
  --------------- sinais rebuff2    
  -- habilita leitura
  signal w_REBUFF2_READ_ENA  :  std_logic;
  -- endereco a ser lido
  signal w_REBUFF2_READ_ADDR   :  std_logic_vector (ADDR_WIDTH - 1 downto 0);
  -- endereco a ser escrito
  signal w_REBUFF2_WRITE_ADDR  :  std_logic_vector (ADDR_WIDTH - 1 downto 0);
  -- habilita escrita    
  signal w_REBUFF2_WRITE_ENA :  std_logic;  
  -- linha de buffer selecionada
  signal w_REBUFF2_SEL_LINE   :  std_logic_vector (1 downto 0); 
  -- sinal ready reuffer 1
  signal w_REBUFF2_READY     :  std_logic;
  
  
    
  -- sinais pool1
  -- saida rebbufer2 entrada pool1
  signal w_POOL1_READY : std_logic;
  signal w_POOL1_DATA_IN : t_POOL1_IN := (others => (others => '0'));  
  signal w_POOL1_DATA_OUT : t_POOL1_OUT := (others => (others => '0'));
  
  
  -- sinais rebuffer 3
  -- habilita leitura
  signal w_REBUFF3_READ_ENA  :  std_logic;
  -- endereco a ser lido
  signal w_REBUFF3_READ_ADDR   :  std_logic_vector (ADDR_WIDTH - 1 downto 0) := (others => '0');
  -- endereco a ser escrito
  signal w_REBUFF3_WRITE_ADDR  :  std_logic_vector (ADDR_WIDTH - 1 downto 0);
  -- habilita escrita    
  signal w_REBUFF3_WRITE_ENA :  std_logic;  
  -- linha de buffer selecionada
  signal w_REBUFF3_SEL_LINE   :  std_logic_vector (1 downto 0); 
  -- sinal ready rebuffer 3
  signal w_REBUFF3_READY     :  std_logic;
  
  
  -- sidnais conv2
  signal w_CONV2_DATA_IN : t_CONV2_IN := (others => (others => '0'));  
  signal w_CONV2_DATA_OUT : t_CONV2_OUT := (others => (others => '0')); 
  
  
  -- sinais rebuffer4
  -- habilita leitura
  signal w_REBUFF4_READ_ENA  :  std_logic;
  -- endereco a ser lido
  signal w_REBUFF4_READ_ADDR   :  std_logic_vector (ADDR_WIDTH - 1 downto 0);
  
begin
  
  -- imagem de entrada
  u_IMG_CHA_0 : image_chanel
                  generic map ("input_chanel_R.mif")
                  port map (
                    address	=> w_IMG_READ_ADDR,
                    clock		=> i_CLK,
                    rden		=> w_IMG_READ_ENA,
                    q		    => w_REBUFF1_DATA_IN(0)
                  );
                  
  -- imagem de entrada
  u_IMG_CHA_1 : image_chanel
                  generic map ("input_chanel_G.mif")
                  port map (
                    address	=> w_IMG_READ_ADDR,
                    clock		=> i_CLK,
                    rden		=> w_IMG_READ_ENA,
                    q		    => w_REBUFF1_DATA_IN(1)
                  );
  -- imagem de entrada
  u_IMG_CHA_2 : image_chanel
                  generic map ("input_chanel_B.mif")
                  port map (
                    address	=> w_IMG_READ_ADDR,
                    clock		=> i_CLK,
                    rden		=> w_IMG_READ_ENA,
                    q		    => w_REBUFF1_DATA_IN(2)
                  );
                  
  ------------------------------------------------------
  u_REBUFF_1 : rebuff1 
                  generic map 
                  (
                    ADDR_WIDTH    => ADDR_WIDTH ,
                    DATA_WIDTH    => DATA_WIDTH ,  
                    NUM_BUFFER_LINES      => "11"    , -- 3 buffers
                    IFMAP_WIDTH   => "011000", -- 24
                    IFMAP_HEIGHT  => "100000", -- 32
                    OFMAP_WIDTH   => "011010", -- 26
                    OFMAP_HEIGHT  => "100010", -- 34
                    PAD_H         => "100001", -- 33 (indice para adicionar pad linha de baixo)
                    PAD_W         => "011001"  -- 25 (indice para adicionar pad coluna da direita)
                  )
                  port map 
                  (
                    i_CLK       => i_CLK,
                    i_CLR       => i_CLR,
                    i_GO        => i_GO,
                    i_DATA      => w_REBUFF1_DATA_IN,
                    o_READ_ENA  => w_IMG_READ_ENA,
                    o_IN_ADDR   => w_IMG_READ_ADDR,
                    o_OUT_ADDR  => w_REBUFF1_WRITE_ADDR,
                    o_WRITE_ENA => w_REBUFF1_WRITE_ENA,
                    o_DATA      => w_REBUFF1_DATA_OUT,
                    o_SEL_BUFF_LINE  => w_REBUFF1_SEL_LINE,
                    o_READY     => w_REBUFF1_READY
                  );
  ------------------------------------------------------
	u_CONV1 : conv1 
    generic map
    (
      DATA_WIDTH => DATA_WIDTH,
      ADDR_WIDTH => ADDR_WIDTH
    )
    port map
    (
      i_CLK           => i_CLK  ,
      i_CLR           => i_CLR  ,
      i_GO            => w_REBUFF1_READY ,     
      i_LOAD          => i_LOAD         , 
      o_READY         => w_COVN1_READY  , 
      i_IN_DATA       => w_REBUFF1_DATA_OUT,
      i_IN_WRITE_ENA  => w_REBUFF1_WRITE_ENA,
      i_IN_SEL_LINE   => w_REBUFF1_SEL_LINE,
      i_IN_WRITE_ADDR => w_REBUFF1_WRITE_ADDR,
      i_OUT_READ_ENA  => w_REBUFF2_READ_ENA  ,
      i_OUT_READ_ADDR => w_REBUFF2_READ_ADDR ,
      o_OUT_DATA      => w_CONV1_DATA_OUT
		);
  
  ------------------------------------------------------
  
  u_REBUFF_2 : rebuff2 
                  generic map 
                  (
                    ADDR_WIDTH    => ADDR_WIDTH ,
                    DATA_WIDTH    => DATA_WIDTH ,  
                    NUM_BUFFER_LINES => "10"    , -- 2 buffers
                    IFMAP_WIDTH   => "011000", -- 24
                    IFMAP_HEIGHT  => "100000", -- 32
                    OFMAP_WIDTH   => "011000", -- 24
                    OFMAP_HEIGHT  => "100000", -- 32
                    PAD_H         => "100001", -- 33 (indice para adicionar pad linha de baixo)
                    PAD_W         => "011001"  -- 25 (indice para adicionar pad coluna da direita)
                  )
                  port map 
                  (
                    i_CLK       => i_CLK,
                    i_CLR       => i_CLR,
                    i_GO        => w_COVN1_READY,
                    i_DATA      => w_CONV1_DATA_OUT,
                    o_READ_ENA  => w_REBUFF2_READ_ENA,
                    o_IN_ADDR   => w_REBUFF2_READ_ADDR,
                    o_OUT_ADDR  => w_REBUFF2_WRITE_ADDR,
                    o_WRITE_ENA => w_REBUFF2_WRITE_ENA,
                    o_DATA      => w_POOL1_DATA_IN,
                    o_SEL_BUFF_LINE  => w_REBUFF2_SEL_LINE,
                    o_READY     => w_REBUFF2_READY
                  );
  
  -------------------------------------------------------
  
  u_POOL1 : pool1 
                  generic map (    
                    DATA_WIDTH   => 8,
                    ADDR_WIDTH   => 10,
                    NUM_CHANNELS => 6
                  )
                  port map (
                    i_CLK       => i_CLK,
                    i_CLR       => i_CLR,
                    i_GO        => w_REBUFF2_READY,
                    o_READY     => w_POOL1_READY,
                    i_IN_DATA        => w_POOL1_DATA_IN,
                    i_IN_WRITE_ENA   => w_REBUFF2_WRITE_ENA,
                    i_IN_WRITE_ADDR  => w_REBUFF2_WRITE_ADDR,
                    i_IN_SEL_LINE    => w_REBUFF2_SEL_LINE,
                    i_OUT_READ_ADDR0 => w_REBUFF3_READ_ADDR,
                    o_BUFFER_OUT     => w_POOL1_DATA_OUT
                  );
  
  -------------------------------------------------------
  
  u_REBUFF_3 : rebuff3 
                  generic map (
                    ADDR_WIDTH       => 10,
                    DATA_WIDTH       => 8,
                    NUM_BUFFER_LINES => "11",
                    IFMAP_WIDTH      => "001100",
                    IFMAP_HEIGHT     => "010000",
                    OFMAP_WIDTH      => "001110",
                    OFMAP_HEIGHT     => "010010",
                    PAD_W            => "001101",
                    PAD_H            => "010001"
                  )
                  port map (
                    i_CLK           => i_CLK,
                    i_CLR           => i_CLR,
                    i_GO            => w_POOL1_READY,
                    i_DATA          => w_POOL1_DATA_OUT,
                    o_READ_ENA      => w_REBUFF3_READ_ENA,
                    o_IN_ADDR       => w_REBUFF3_READ_ADDR,
                    o_OUT_ADDR      => w_REBUFF3_WRITE_ADDR,
                    o_WRITE_ENA     => w_REBUFF3_WRITE_ENA,
                    o_DATA          => w_CONV2_DATA_IN,
                    o_SEL_BUFF_LINE => w_REBUFF3_SEL_LINE,
                    o_READY         => w_REBUFF3_READY
                  );
   
  -------------------------------------------------------
  
  
  -- u_CONV2 : conv2 
  --               generic map
  --               (
  --                 DATA_WIDTH => 8,
  --                 ADDR_WIDTH => 10
  --               )
  --               port map
  --               (
  --                 i_CLK           => i_CLK,
  --                 i_CLR           => i_CLR,
  --                 i_GO            => w_REBUFF3_READY,
  --                 i_LOAD          => i_LOAD,
  --                 o_READY         => w_CONV2_READY,
  --                 i_IN_DATA       => w_CONV2_DATA_IN,
  --                 i_IN_WRITE_ENA  => w_REBUFF3_WRITE_ENA,
  --                 i_IN_SEL_LINE   => w_REBUFF3_SEL_LINE,
  --                 i_IN_WRITE_ADDR => w_REBUFF3_WRITE_ADDR,
  --                 i_OUT_READ_ENA  => w_REBUFF4_READ_ENA,
  --                 i_OUT_READ_ADDR => w_REBUFF4_READ_ADDR,
  --                 o_OUT_DATA      => w_CONV2_DATA_OUT
  --               );
  
  
  o_READY <= w_REBUFF3_READY;
end arch;
  


  