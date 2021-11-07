-- Primeira camada convolucional
-------------------------------
-- Cx3 buffers de entrada 
-- MxC Nucleos convolucionais
-- Arvore de somadores
-- Reg
-- Relu
-- Mx1 buffers de saída


library ieee;
use ieee.std_logic_1164.all;
library work;
use work.types_pkg.all;

entity conv1 is
  generic 
  (
    DATA_WIDTH : integer := 8;
    ADDR_WIDTH : integer := 10;
    H : integer := 34; -- iFMAP Height 
    W : integer := 26; -- iFMAP Width 
    C : integer := 3; -- iFMAP Chanels (filter Chanels also)
    R : integer := 3; -- filter Height 
    S : integer := 3; -- filter Width     
    M : integer := 6; -- Number of filters (oFMAP Chanels also)        
    NUM_WEIGHT_FILTER_CHA : std_logic_vector := "1000";
    LAST_WEIGHT : std_logic_vector := "10100010"; 
    LAST_BIAS : std_logic_vector := "1100"; 
    LAST_ROW : std_logic_vector := "100010"; 
    LAST_COL : std_logic_vector := "11010"; 
    NC_SEL_WIDTH : integer := 2; 
    NC_ADDRESS_WIDTH : integer := 5; 
    NC_OHE_WIDTH : integer := 18;
    BIAS_OHE_WIDTH : integer := 12; 
    WEIGHT_ADDRESS_WIDTH : integer := 10; 
    BIAS_ADDRESS_WIDTH : integer := 6; 
    SCALE_SHIFT  : t_ARRAY_OF_INTEGER(0 to  5) := (8, 8, 7, 8, 8, 9);
    WEIGHT_FILE_NAME : string := "weights_and_biases/conv1.mif";
    BIAS_FILE_NAME    : string := "weights_and_biases/conv1_bias.mif";
    OUT_SEL_WIDTH : integer := 3 -- largura de bits para selecionar buffers de saida    
  );
  port 
  (
    i_CLK       : in STD_LOGIC;
    i_CLR       : in STD_LOGIC;
    i_GO        : in STD_LOGIC;
    o_READY     : out std_logic;
    
    -- sinais para comunicação com rebuffers
    -- dado de entrada
    i_IN_DATA      : in  t_ARRAY_OF_LOGIC_VECTOR(0 to C-1)(DATA_WIDTH-1 downto 0);
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
    i_OUT_READ_ADDR : in std_logic_vector (ADDR_WIDTH - 1 downto 0) := (others => '0');
    --------------------------------------------------
    
    -- saida dos buffers de saida
    o_OUT_DATA : out t_ARRAY_OF_LOGIC_VECTOR(0 to M-1)(DATA_WIDTH-1 downto 0)
    
  );
end conv1;

architecture arch of conv1 is  
  -- constant H : integer := 34; -- iFMAP Height 
  -- constant W : integer := 26; -- iFMAP Width 
  -- constant C : integer := 3; -- iFMAP Chanels (filter Chanels also)
  -- constant R : integer := 3; -- filter Height 
  -- constant S : integer := 3; -- filter Width     
  -- constant M : integer := 6; -- Number of filters (oFMAP Chanels also)      
  -- constant NUM_WEIGHT_FILTER_CHA : std_logic_vector := "1000"; -- quantidade de peso por filtro por canal(R*S) (de 0 a 8)
  -- constant LAST_WEIGHT : std_logic_vector := "10100010"; -- quantidade de pesos (162)
  -- constant LAST_BIAS : std_logic_vector := "1100"; -- quantidade de bias e scale (12)    
  -- constant LAST_ROW : std_logic_vector := "100010"; -- 34 (0 a 33 = 34 pixels) (2 pixels de pad)
  -- constant LAST_COL : std_logic_vector := "11010";   -- 26 (0 a 25 = 26 pixels) (2 pixels de pad)
  -- constant NC_SEL_WIDTH : integer := 2; -- largura de bits para selecionar saidas dos NCs de cada filtro  
  -- constant NC_ADDRESS_WIDTH : integer := 5; -- num bits para enderecamento de NCs
  -- constant NC_OHE_WIDTH : integer := 18; -- numero de bits para one-hot-encoder de NCs
  -- constant BIAS_OHE_WIDTH : integer := 12; -- numero de bits para one-hot-encoder de bias e scales
  -- constant WEIGHT_ADDRESS_WIDTH : integer := 10; -- numero de bits para enderecar pesos
  -- constant BIAS_ADDRESS_WIDTH : integer := 6; -- numero de bits para enderecar registradores de bias e scale
  -- constant SCALE_SHIFT  : t_ARRAY_OF_INTEGER(0 to M-1) := (8, 8, 7, 8, 8, 9); --num bits to shift
  
  
  -------------------------------
  -- ROM pesos
  -------------------------------
  component conv1_weights IS
    GENERIC 
    (
      init_file_name : STRING := "conv1.mif";
      DATA_WIDTH : INTEGER := 8;
      DATA_DEPTH : INTEGER := 10
    );
    PORT
    (
      address		: IN STD_LOGIC_VECTOR (DATA_DEPTH - 1 DOWNTO 0);
      clock		: IN STD_LOGIC  := '1';
      rden		: IN STD_LOGIC  := '1';
      q		: OUT STD_LOGIC_VECTOR (DATA_WIDTH - 1 DOWNTO 0)
    );   
  end component;
  -------------------------------
  -------------------------------
  -------------------------------
  -- ROM bias e scale down multipliers
  -------------------------------
  component conv1_bias IS
    GENERIC 
    (
      init_file_name : STRING := "conv2_bias.mif";
      DATA_WIDTH : INTEGER := 32;
      DATA_DEPTH : INTEGER := 5
    );
    PORT
    (
      address		: IN STD_LOGIC_VECTOR (DATA_DEPTH-1 DOWNTO 0);
      clken		: IN STD_LOGIC  := '1';
      clock		: IN STD_LOGIC  := '1';
      q		: OUT STD_LOGIC_VECTOR (DATA_WIDTH-1 DOWNTO 0)
    );
  end component;
  -------------------------------

  -- controle 
  component conv1_crt is
    generic 
    (
      H : integer := 34; -- iFMAP Height 
      W : integer := 26; -- iFMAP Width 
      C : integer := 3; -- iFMAP Chanels (filter Chanels also)
      R : integer := 3; -- filter Height 
      S : integer := 3; -- filter Width     
      M : integer := 6; -- Number of filters (oFMAP Chanels also)    
      DATA_WIDTH : integer := 8;
      ADDR_WIDTH : integer := 10;
      NC_SEL_WIDTH  : integer := 2; -- largura de bits para selecionar saidas dos NCs de cada filtro
      NC_ADDRESS_WIDTH : integer := 5; -- numero de bits para enderecar NCs 
      WEIGHT_ADDRESS_WIDTH : integer := 8; -- numero de bits para enderecar pesos
      BIAS_ADDRESS_WIDTH : integer := 5; -- numero de bits para enderecar registradores de bias e scales      
      NUM_WEIGHT_FILTER_CHA : std_logic_vector := "1000"; -- quantidade de peso por filtro por canal(R*S) (de 0 a 8)
      LAST_WEIGHT : std_logic_vector := "10100010"; -- quantidade de pesos (162)
      LAST_BIAS : std_logic_vector := "1100"; -- quantidade de bias e scale (12)    
      LAST_ROW : std_logic_vector := "100010"; -- 34 (0 a 33 = 34 pixels) (pixels de pad)
      LAST_COL : std_logic_vector := "11010";   -- 26 (0 a 25 = 26 pixels) (2 pixels de pad)
      OUT_SEL_WIDTH : integer := 3 -- largura de bits para selecionar buffers de saida     
    );

    port (
      i_CLK           : in  std_logic;
      i_CLR           : in  std_logic;
      i_GO            : in  std_logic; -- inicia maq
      o_READY         : out std_logic; -- fim maq
      o_IN_READ_ENA   : out  std_logic;
      o_IN_READ_ADDR0 : out std_logic_vector (ADDR_WIDTH - 1 downto 0);
      o_IN_READ_ADDR1 : out std_logic_vector (ADDR_WIDTH - 1 downto 0);
      o_IN_READ_ADDR2 : out std_logic_vector (ADDR_WIDTH - 1 downto 0); 
      o_WEIGHT_READ_ENA  : out std_logic; 
      o_WEIGHT_READ_ADDR : out std_logic_vector(WEIGHT_ADDRESS_WIDTH-1 downto 0);  -- bits para enderecamento ROM de pesos
      o_BIAS_READ_ADDR : out STD_LOGIC_VECTOR (BIAS_ADDRESS_WIDTH-1 DOWNTO 0);
      o_BIAS_READ_ENA  : out std_logic; 
      o_BIAS_WRITE_ENA :  out std_logic;
      o_SCALE_WRITE_ENA : out std_logic;
      o_PIX_SHIFT_ENA : out  std_logic;
      o_WEIGHT_SHIFT_ENA : out  std_logic;
      o_NC_ADDR       : out std_logic_vector(NC_ADDRESS_WIDTH-1 downto 0);    
      o_WEIGHT_ROW_SEL   : out std_logic_vector(1 downto 0);
      o_NC_O_SEL      : out  std_logic_vector(NC_SEL_WIDTH - 1 downto 0);
      o_ACC_ENA       : out  std_logic;
      o_ACC_RST       : out  std_logic;
      o_ROW_SEL       : out std_logic_vector(1 downto 0);       
      o_OUT_SEL       : out std_logic_vector(OUT_SEL_WIDTH-1 downto 0) := (others => '0');    
      o_OUT_WRITE_ENA : out  std_logic;
      o_OUT_INC_ADDR  : out  std_logic; 
      o_OUT_CLR_ADDR : out std_logic      
    );
  end component;
  -----------------------------------------
  -----------------------------------------
  
  -- operacional
  component conv1_op is
    generic 
    (
      H : integer := 32; -- iFMAP Height 
      W : integer := 24; -- iFMAP Width 
      C : integer := 3;  -- iFMAP Chanels (filter Chanels also)
      R : integer := 3; -- filter Height 
      S : integer := 3; -- filter Width     
      M : integer := 6; -- Number of filters (oFMAP Chanels also)  
      NC_SEL_WIDTH : integer := 2; -- largura de bits para selecionar saidas dos NCs de cada filtro
      NC_ADDRESS_WIDTH : integer := 5; -- numero de bits para enderecar NCs 
      NC_OHE_WIDTH : integer := 18; -- numero de bits para one-hot-encoder de NCs
      BIAS_OHE_WIDTH : integer := 12; -- numero de bits para one-hot-encoder de bias e scales
      WEIGHT_ADDRESS_WIDTH : integer := 8; -- numero de bits para enderecar pesos
      BIAS_ADDRESS_WIDTH : integer := 5; -- numero de bits para enderecar registradores de bias e scales
      DATA_WIDTH : integer := 8;
      ADDR_WIDTH : integer := 10;
      OUT_SEL_WIDTH : integer := 3; 
      SCALE_SHIFT : t_ARRAY_OF_INTEGER
    );
    port 
    (
      i_CLK       : in STD_LOGIC;
      i_CLR       : in STD_LOGIC;
      i_IN_READ_ENA  : in std_logic;
      i_IN_DATA      : in  t_ARRAY_OF_LOGIC_VECTOR(0 to C-1)(DATA_WIDTH-1 downto 0);
      i_IN_WRITE_ENA : in std_logic;    
      i_IN_SEL_LINE  : in std_logic_vector (1 downto 0);    
      i_IN_READ_ADDR0   : in std_logic_vector (ADDR_WIDTH - 1 downto 0);
      i_IN_READ_ADDR1   : in std_logic_vector (ADDR_WIDTH - 1 downto 0);
      i_IN_READ_ADDR2   : in std_logic_vector (ADDR_WIDTH - 1 downto 0); 
      i_IN_WRITE_ADDR  : in std_logic_vector (ADDR_WIDTH - 1 downto 0);
      i_WEIGHT       : in std_logic_vector(7 downto 0);
      i_BIAS_WRITE_ADDR : IN STD_LOGIC_VECTOR (BIAS_ADDRESS_WIDTH-1 DOWNTO 0);
      i_BIAS : in std_logic_vector (31 downto 0);
      i_BIAS_WRITE_ENA :  in std_logic;
      i_SCALE_WRITE_ENA : in std_logic;
      i_PIX_SHIFT_ENA : in STD_LOGIC;    
      i_WEIGHT_SHIFT_ENA : in STD_LOGIC;    
      i_WEIGHT_SHIFT_ADDR : in std_logic_vector(NC_ADDRESS_WIDTH-1 downto 0);    -- endereco do NC para carregar pesos     
      i_WEIGHT_ROW_SEL : in std_logic_vector(1 downto 0);
      i_NC_O_SEL : IN  std_logic_vector(NC_SEL_WIDTH - 1 DOWNTO 0); 
      i_ACC_ENA : in std_logic;
      i_ACC_RST : in std_logic;
      i_ROW_SEL : in std_logic_vector(1 downto 0);   
      i_OUT_SEL : in std_logic_vector(OUT_SEL_WIDTH-1 downto 0) := (others => '0'); 
      i_OUT_WRITE_ENA : in std_logic;
      i_OUT_READ_ENA : in std_logic;
      i_OUT_READ_ADDR : in std_logic_vector (9 downto 0) := (others => '0');
      i_OUT_INC_ADDR : in std_logic;
      i_OUT_CLR_ADDR : in std_logic;
      o_OUT_DATA : out t_ARRAY_OF_LOGIC_VECTOR(0 to M-1)(DATA_WIDTH-1 downto 0)      
    );
  end component;
  
  ---------------------------------
  -- sinais para buffers de entrada
  ---------------------------------
  -- habilita leitura
  signal w_IN_READ_ENA   : std_logic;
  -- enderecos a serem lidos
  signal w_IN_READ_ADDR0 : std_logic_vector (ADDR_WIDTH - 1 downto 0);
  signal w_IN_READ_ADDR1 : std_logic_vector (ADDR_WIDTH - 1 downto 0);
  signal w_IN_READ_ADDR2 : std_logic_vector (ADDR_WIDTH - 1 downto 0); 
  ---------------------------------
  ---------------------------------
  
  ---------------------------------
  -- sinais para memeoria de pesos e bias
  ---------------------------------
  -- sinal para rom de pesos
  signal w_WEIGHT_READ_ENA  : std_logic; 
  signal w_WEIGHT_READ_ADDR : std_logic_vector(WEIGHT_ADDRESS_WIDTH-1 downto 0);  -- bits para enderecamento ROM de pesos
  -- peso de entrada do NC
  signal w_i_WEIGHT : STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
  
  
  -- SINAL PARA ROM DE BIAS E SCALES
  signal w_BIAS_READ_ADDR : std_logic_vector(BIAS_ADDRESS_WIDTH-1 DOWNTO 0);
  signal w_BIAS_READ_ENA  : std_logic; 
  
  -- habilita escrita nos registradores de bias e scale
  signal w_BIAS_WRITE_ENA :  std_logic;
  signal w_SCALE_WRITE_ENA : std_logic;
  -- saida da ROM bias
  signal w_BIAS : std_logic_vector(31 downto 0);
  ----------------------------------
  
  
  ---------------------------------
  -- sinais para núcleos convolucionais
  ---------------------------------
  -- habilita deslocamento dos registradores de pixels e pesos
  signal w_PIX_SHIFT_ENA : std_logic;
  signal w_WEIGHT_SHIFT_ENA : std_logic;
  
  -- endereco do NC para carregar pesos     
  signal w_NC_ADDR : std_logic_vector(NC_ADDRESS_WIDTH-1 downto 0) := (others => '0');    
  
  -- seleciona linha dos registradores de deslocamento
  signal w_WEIGHT_ROW_SEL : std_logic_vector(1 downto 0);

  -- seleciona saida de NCs
  signal w_NC_O_SEL      : std_logic_vector(NC_SEL_WIDTH - 1 downto 0);
  -- habilita acumulador de pixels de saida dos NCs
  signal w_ACC_ENA       : std_logic;
  -- reseta acumulador de pixels de saida dos NCs
  signal w_ACC_RST       : std_logic;

  -- seleciona configuração de conexao entre buffer e registradores de deslocamento
  signal w_ROW_SEL       : std_logic_vector(1 downto 0); 
  ---------------------------------
  ---------------------------------

  ---------------------------------
  -- sinais para buffers de saida
  ---------------------------------
  -- seleciona buffer de saida
  signal w_OUT_SEL : std_logic_vector(OUT_SEL_WIDTH-1 downto 0) := (others => '0');  
  -- habilita escrita buffer de saida
  signal w_OUT_WRITE_ENA : std_logic;
  -- incrementa endereco de saida
  signal w_OUT_INC_ADDR  : std_logic; 
  -- reset endreco de saida
  signal w_OUT_CLR_ADDR  : std_logic;
  ---------------------------------
  ---------------------------------
  

begin


  -- memoria rom de pesos
  u_ROM_WEIGHTOS : conv1_weights
              generic map 
              (
                init_file_name => WEIGHT_FILE_NAME,
                DATA_WIDTH => 8,
                DATA_DEPTH => WEIGHT_ADDRESS_WIDTH
              )
              port map 
              (
              	address	=> w_WEIGHT_READ_ADDR,
                clock		=> i_CLK,
                rden		=> w_WEIGHT_READ_ENA,
                q		    => w_i_WEIGHT    
              );
  
  -- memeoria rom de BIAS E SCALE
  u_ROM_BIAS : conv1_bias
              generic map 
              (
                init_file_name => BIAS_FILE_NAME,
                DATA_WIDTH => 32,
                DATA_DEPTH => BIAS_ADDRESS_WIDTH
              )
              port map 
              (
              	address	=> w_BIAS_READ_ADDR,
                clken		=> w_BIAS_READ_ENA,
                clock		=> i_CLK,                
                q		    => w_BIAS   
              );
              
  u_CONTROLE : CONV1_CRT     
              generic map 
              (
                H => H, 
                W => W, 
                C => C, 
                R => R, 
                S => S, 
                M => M, 
                DATA_WIDTH            => DATA_WIDTH,
                ADDR_WIDTH            => ADDR_WIDTH,    
                NC_SEL_WIDTH          => NC_SEL_WIDTH, 
                NC_ADDRESS_WIDTH      => NC_ADDRESS_WIDTH, 
                WEIGHT_ADDRESS_WIDTH  => WEIGHT_ADDRESS_WIDTH, 
                BIAS_ADDRESS_WIDTH    => BIAS_ADDRESS_WIDTH,                 
                NUM_WEIGHT_FILTER_CHA => NUM_WEIGHT_FILTER_CHA, 
                LAST_WEIGHT     => LAST_WEIGHT,  
                LAST_BIAS       => LAST_BIAS, 
                LAST_ROW        => LAST_ROW,  
                LAST_COL        => LAST_COL,
                OUT_SEL_WIDTH   => OUT_SEL_WIDTH
              )
              port map
              (
                i_CLK           => i_CLK,
                i_CLR           => i_CLR,
                i_GO            => i_GO,                
                o_READY         => o_READY,
                o_IN_READ_ENA   => w_IN_READ_ENA,
                o_IN_READ_ADDR0 => w_IN_READ_ADDR0 ,
                o_IN_READ_ADDR1 => w_IN_READ_ADDR1 ,
                o_IN_READ_ADDR2 => w_IN_READ_ADDR2 ,
                o_WEIGHT_READ_ENA    => w_WEIGHT_READ_ENA   ,
                o_WEIGHT_READ_ADDR   => w_WEIGHT_READ_ADDR  ,
                o_BIAS_READ_ADDR  => w_BIAS_READ_ADDR ,
                o_BIAS_READ_ENA   => w_BIAS_READ_ENA  ,
                o_BIAS_WRITE_ENA  => w_BIAS_WRITE_ENA ,
                o_SCALE_WRITE_ENA => w_SCALE_WRITE_ENA,
                o_PIX_SHIFT_ENA => w_PIX_SHIFT_ENA,
                o_WEIGHT_SHIFT_ENA => w_WEIGHT_SHIFT_ENA,
                o_NC_ADDR       => w_NC_ADDR,
                o_WEIGHT_ROW_SEL   => w_WEIGHT_ROW_SEL   ,
                o_NC_O_SEL      => w_NC_O_SEL,                
                o_ACC_ENA       => w_ACC_ENA,
                o_ACC_RST       => w_ACC_RST,
                o_ROW_SEL       => w_ROW_SEL,
                o_OUT_SEL       =>  w_OUT_SEL,
                o_OUT_WRITE_ENA => w_OUT_WRITE_ENA,
                o_OUT_INC_ADDR  => w_OUT_INC_ADDR,
                o_OUT_CLR_ADDR  => w_OUT_CLR_ADDR
              );
            
  u_OPERACIONAL : CONV1_OP
              generic map
              (
                H => H, 
                W => W, 
                C => C, 
                R => R, 
                S => S, 
                M => M,       
                DATA_WIDTH => DATA_WIDTH,
                ADDR_WIDTH => ADDR_WIDTH,
                NC_ADDRESS_WIDTH  => NC_ADDRESS_WIDTH,
                NC_SEL_WIDTH      => NC_SEL_WIDTH,
                NC_OHE_WIDTH      => NC_OHE_WIDTH,
                BIAS_OHE_WIDTH    => BIAS_OHE_WIDTH,
                WEIGHT_ADDRESS_WIDTH => WEIGHT_ADDRESS_WIDTH,
                BIAS_ADDRESS_WIDTH => BIAS_ADDRESS_WIDTH,
                SCALE_SHIFT        => SCALE_SHIFT,
                OUT_SEL_WIDTH      => OUT_SEL_WIDTH
              )
              port map
              (
                i_CLK           => i_CLK,
                i_CLR           => i_CLR,
                i_IN_READ_ENA   => w_IN_READ_ENA,
                i_IN_DATA       => i_IN_DATA,     -- dado buffer entrada
                i_IN_WRITE_ENA  => i_IN_WRITE_ENA, -- escrita buffer entrada
                i_IN_SEL_LINE   => i_IN_SEL_LINE, -- linha buffer entrada
                i_IN_READ_ADDR0 => w_IN_READ_ADDR0 ,
                i_IN_READ_ADDR1 => w_IN_READ_ADDR1 ,
                i_IN_READ_ADDR2 => w_IN_READ_ADDR2 ,              
                i_WEIGHT             => w_i_WEIGHT,
                i_BIAS_WRITE_ADDR  => w_BIAS_READ_ADDR  ,
                i_BIAS            => w_BIAS,                
                i_BIAS_WRITE_ENA  => w_BIAS_WRITE_ENA  ,
                i_SCALE_WRITE_ENA => w_SCALE_WRITE_ENA ,
                i_WEIGHT_SHIFT_ADDR  => w_NC_ADDR,
                i_WEIGHT_ROW_SEL     => w_WEIGHT_ROW_SEL  , 
                i_IN_WRITE_ADDR => i_IN_WRITE_ADDR, -- endereco escrita buffer entrada
                i_PIX_SHIFT_ENA => w_PIX_SHIFT_ENA,
                i_WEIGHT_SHIFT_ENA => w_WEIGHT_SHIFT_ENA,
                i_NC_O_SEL      => w_NC_O_SEL,
                i_ACC_ENA       => w_ACC_ENA,
                i_ACC_RST       => w_ACC_RST,
                i_ROW_SEL       => w_ROW_SEL,  
                i_OUT_SEL       =>  w_OUT_SEL,
                i_OUT_WRITE_ENA => w_OUT_WRITE_ENA,
                i_OUT_READ_ENA  => i_OUT_READ_ENA, -- leitura buffer saida
                i_OUT_READ_ADDR => i_OUT_READ_ADDR, -- endereco leitura buffer saida
                i_OUT_INC_ADDR  => w_OUT_INC_ADDR,
                i_OUT_CLR_ADDR  => w_OUT_CLR_ADDR,
                o_OUT_DATA      => o_OUT_DATA     -- dado buffer saida
              );  
  
  
end arch;
