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

  
  -- primeira camada convolucional
  component conv1 is
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
      
      -- sinais para comunicação com rebuffers
      -- dado de entrada
      i_IN_DATA       : t_CONV1_IN;
      -- habilita escrita    
      i_IN_WRITE_ENA  : in std_logic;    
      -- linha de buffer selecionada
      i_IN_SEL_LINE   : in std_logic_vector (1 downto 0); 
      -- endereco a ser escrito
      i_IN_WRITE_ADDR : in std_logic_vector (ADDR_WIDTH - 1 downto 0);
      --------------------------------------------------
      -- habilita leitura buffer de saida
      i_OUT_READ_ENA  : in std_logic;
      -- endereco de leitura buffer de saida
      i_OUT_READ_ADDR : in std_logic_vector (ADDR_WIDTH - 1 downto 0);
      --------------------------------------------------
      
      -- saida dos buffers de saida
      o_OUT_DATA : out t_CONV1_OUT
      
    );
  end component;
  
  
  --------------------------------------------------------
  -- bloco rebuffer
  component rebuff1 is
    generic (
      ADDR_WIDTH : integer := 10;
      DATA_WIDTH : integer := 8;    
      NUM_BUFF   : std_logic_vector(1 downto 0) := "11"; -- 3 buffers
      IFMAP_WIDTH : std_logic_vector(5 downto 0) := "100000"; -- 32
      IFMAP_HEIGHT : std_logic_vector(5 downto 0) := "011000"; -- 24
      OFMAP_WIDTH : std_logic_vector(5 downto 0) := "100010"; -- 34
      OFMAP_HEIGHT : std_logic_vector(4 downto 0) := "11010"; -- 26
      PAD_H : std_logic_vector(5 downto 0) := "100001"; -- 33
      PAD_W : std_logic_vector(5 downto 0) := "011001"; -- 25
      INPUT_MAX_ADDR : std_logic_vector(9 downto 0) := "0000100000" -- 32*#linhas
    );
    port (
      i_CLK       : in  std_logic;
      i_CLR       : in  std_logic;
      i_GO        : in  std_logic;

      -- dado de entrada
      i_DATA      : in  t_REBBUF1_IN;
      
      -- habilita leitura
      o_READ_ENA  : out std_logic;
      -- endereco a ser lido
      o_IN_ADDR   : out std_logic_vector (ADDR_WIDTH - 1 downto 0);
      -- endereco a ser escrito
      o_OUT_ADDR  : out std_logic_vector (ADDR_WIDTH - 1 downto 0);
      -- habilita escrita    
      o_WRITE_ENA : out std_logic;
      -- dado de saida (mesmo q o de entrada)
      o_DATA      : out t_CONV1_IN;
      -- linha de buffer selecionada
      o_SEL_BUFF  : out std_logic_vector (1 downto 0);
      
      o_READY     : out std_logic
    );
  end component;
  
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

  
  --------------- sinais 
  -- buffers de entrada e rebuffer
  -- dado de entrada
  signal w_REBUFF_IN_DATA      : t_REBBUF1_IN;
  -- habilita leitura
  signal w_READ_ENA  :  std_logic;
  -- endereco a ser lido
  signal w_IN_ADDR   :  std_logic_vector (ADDR_WIDTH - 1 downto 0);
  -- endereco a ser escrito
  signal w_OUT_ADDR  :  std_logic_vector (ADDR_WIDTH - 1 downto 0);
  -- habilita escrita    
  signal w_WRITE_ENA :  std_logic;
  -- dado de saida (mesmo q o de entrada)
  signal w_REBUFF_OUT_DATA      :  t_CONV1_IN;
  -- linha de buffer selecionada
  signal w_SEL_BUFF  :  std_logic_vector (1 downto 0);
  signal w_REBUFF_READY     :  std_logic;
  
    
  -------- SINAIS CONV1
  signal w_GO        : STD_LOGIC;
  signal w_LOAD      : std_logic;
  signal w_READY     : std_logic;
  
  -- sinais para comunicação com rebuffers
  -- dado de entrada
  signal w_IN_DATA       : t_CONV1_IN;
  -- habilita escrita    
  signal w_IN_WRITE_ENA  :  std_logic;    
  -- linha de buffer selecionada
  signal w_IN_SEL_LINE   :  std_logic_vector (1 downto 0); 
  -- endereco a ser escrito
  signal w_IN_WRITE_ADDR :  std_logic_vector (ADDR_WIDTH - 1 downto 0);
  --------------------------------------------------
  -- habilita leitura buffer de saida
  signal w_OUT_READ_ENA  :  std_logic;
  -- endereco de leitura buffer de saida
  signal w_OUT_READ_ADDR :  std_logic_vector (ADDR_WIDTH - 1 downto 0);
  --------------------------------------------------
  
  -- saida dos buffers de saida
  signal w_OUT_DATA : t_CONV1_OUT;

  
  
begin
  
  -- imagem de entrada
  u_IMG_CHA_0 : image_chanel
                  generic map ("input_chanel_R.mif")
                  port map (
                    address	=> w_IN_ADDR,
                    clock		=> i_CLK,
                    rden		=> w_READ_ENA,
                    q		    => w_REBUFF_IN_DATA(0)
                  );
                  
  -- imagem de entrada
  u_IMG_CHA_1 : image_chanel
                  generic map ("input_chanel_G.mif")
                  port map (
                    address	=> w_IN_ADDR,
                    clock		=> i_CLK,
                    rden		=> w_READ_ENA,
                    q		    => w_REBUFF_IN_DATA(1)
                  );
  -- imagem de entrada
  u_IMG_CHA_2 : image_chanel
                  generic map ("input_chanel_B.mif")
                  port map (
                    address	=> w_IN_ADDR,
                    clock		=> i_CLK,
                    rden		=> w_READ_ENA,
                    q		    => w_REBUFF_IN_DATA(2)
                  );
                  
  
  u_REBUFF_0 : rebuff1 
                  generic map 
                  (
                    ADDR_WIDTH  => ADDR_WIDTH,
                    DATA_WIDTH  => DATA_WIDTH,                    
                    NUM_BUFF     => "11", -- 3 buffers
                    IFMAP_WIDTH  => "100000", -- 32
                    IFMAP_HEIGHT => "011000", -- 24
                    OFMAP_WIDTH  => "100010", -- 34
                    OFMAP_HEIGHT => "11010", -- 26
                    PAD_H        => "100001", -- 33
                    PAD_W        => "011001", -- 25
                    INPUT_MAX_ADDR => "0000100000" -- 32*#linhas
                  )
                  port map 
                  (
                    i_CLK       => i_CLK,
                    i_CLR       => i_CLR,
                    i_GO        => i_GO,
                    i_DATA      => w_REBUFF_IN_DATA,
                    o_READ_ENA  => w_READ_ENA,
                    o_IN_ADDR   => w_IN_ADDR,
                    o_OUT_ADDR  => w_OUT_ADDR,
                    o_WRITE_ENA => w_WRITE_ENA,
                    o_DATA      => w_REBUFF_OUT_DATA,
                    o_SEL_BUFF  => w_SEL_BUFF,
                    o_READY     => w_REBUFF_READY
                  );
  --
  --u_REBUFF_1 : rebuffer2 
  --                generic map (
  --                  ADDR_WIDTH  => 8,
  --                  DATA_WIDTH  => 8,
  --                  NUM_BUFF     => "11"; -- 3 buffers
  --                  IFMAP_WIDTH  => "100000"; -- 32
  --                  IFMAP_HEIGHT => "011000"; -- 24
  --                  OFMAP_WIDTH  => "100010"; -- 34
  --                  OFMAP_HEIGHT => "11010"; -- 26
  --                  PAD_H        => "100001"; -- 33
  --                  PAD_W        => "011001"; -- 25
  --                  INPUT_MAX_ADDR => "0000100000" -- 32*#linhas
  --                );
  --                port (
  --                  i_CLK       => i_CLK,
  --                  i_CLR       => i_CLR,
  --                  i_GO        => i_GO,
  --                  i_DATA      => w_REBUFF_IN_DATA(1),
  --                  o_READ_ENA  => ,
  --                  o_IN_ADDR   => ,
  --                  o_OUT_ADDR  => ,
  --                  o_WRITE_ENA => ,
  --                  o_DATA      => w_REBUFF_OUT_DATA(1),
  --                  o_SEL_BUFF  => ,
  --                  o_READY     => 
  --                );
  --
  --u_REBUFF_2 : rebuffer2 
  --                generic map (
  --                  ADDR_WIDTH  => 8,
  --                  DATA_WIDTH  => 8,
  --                  NUM_BUFF     => "11"; -- 3 buffers
  --                  IFMAP_WIDTH  => "100000"; -- 32
  --                  IFMAP_HEIGHT => "011000"; -- 24
  --                  OFMAP_WIDTH  => "100010"; -- 34
  --                  OFMAP_HEIGHT => "11010"; -- 26
  --                  PAD_H        => "100001"; -- 33
  --                  PAD_W        => "011001"; -- 25
  --                  INPUT_MAX_ADDR => "0000100000" -- 32*#linhas
  --                );
  --                port (
  --                  i_CLK       => i_CLK,
  --                  i_CLR       => i_CLR,
  --                  i_GO        => i_GO,
  --                  i_DATA      => w_REBUFF_IN_DATA(2),
  --                  o_READ_ENA  => ,
  --                  o_IN_ADDR   => ,
  --                  o_OUT_ADDR  => ,
  --                  o_WRITE_ENA => ,
  --                  o_DATA      => w_REBUFF_OUT_DATA(2),
  --                  o_SEL_BUFF  => ,
  --                  o_READY     => 
  --                );
  --
  
          
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
      i_GO            => i_GO   ,
      i_LOAD          => i_LOAD ,
      o_READY         => o_READY,
      i_IN_DATA       => w_REBUFF_OUT_DATA,
      i_IN_WRITE_ENA  => w_WRITE_ENA,
      i_IN_SEL_LINE   => w_SEL_BUFF,
      i_IN_WRITE_ADDR => w_OUT_ADDR,
      i_OUT_READ_ENA  => w_OUT_READ_ENA  ,
      i_OUT_READ_ADDR => w_OUT_READ_ADDR ,
      o_OUT_DATA      => w_OUT_DATA
		);
  
  
  
  
end arch;
  


  