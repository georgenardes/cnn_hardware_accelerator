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
use work.conv1_pkg.all;
use work.types_pkg.all;

entity conv1 is
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
    i_OUT_READ_ADDR : in std_logic_vector (ADDR_WIDTH - 1 downto 0) := (others => '0');
    --------------------------------------------------
    
    -- saida dos buffers de saida
    o_OUT_DATA : out t_CONV1_OUT
    
  );
end conv1;

architecture arch of conv1 is  
  constant H : integer := 34; -- iFMAP Height 
  constant W : integer := 26; -- iFMAP Width 
  constant C : integer := 3; -- iFMAP Chanels (filter Chanels also)
  constant R : integer := 3; -- filter Height 
  constant S : integer := 3; -- filter Width     
  constant M : integer := 6; -- Number of filters (oFMAP Chanels also)      
  constant OFFSET_ADDR : std_logic_vector := "0000011010"; -- 25dec
  constant NUM_PES_FILTER_CHA : std_logic_vector := "1000"; -- quantidade de peso por filtro por canal(R*S) (de 0 a 8)
  constant LAST_PES : std_logic_vector := "10100010"; -- quantidade de pesos (162)
  constant LAST_BIAS : std_logic_vector := "1100"; -- quantidade de bias e scale (12)    
  constant LAST_ROW : std_logic_vector := "100010"; -- 34 (0 a 33 = 34 pixels) (2 pixels de pad)
  constant LAST_COL : std_logic_vector := "11010";   -- 26 (0 a 25 = 26 pixels) (2 pixels de pad)
  

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
      OFFSET_ADDR : std_logic_vector := "0000011010"; -- 26
      NUM_PES_FILTER_CHA : std_logic_vector := "1000"; -- quantidade de peso por filtro por canal(R*S) (de 0 a 8)
      LAST_PES : std_logic_vector := "10100010"; -- quantidade de pesos (162)
      LAST_BIAS : std_logic_vector := "1100"; -- quantidade de bias e scale (12)    
      LAST_ROW : std_logic_vector := "100010"; -- 34 (0 a 33 = 34 pixels) (pixels de pad)
      LAST_COL : std_logic_vector := "11010"   -- 26 (0 a 25 = 26 pixels) (2 pixels de pad)
    );

    port (
      i_CLK           : in  std_logic;
      i_CLR           : in  std_logic;
      i_GO            : in  std_logic; -- inicia maq
      i_LOAD          : in  std_logic; -- carrega pesos
      o_READY         : out std_logic; -- fim maq
      
      ---------------------------------
      -- sinais para buffers de entrada
      ---------------------------------
      -- habilita leitura
      o_IN_READ_ENA   : out  std_logic;
      -- enderecos a serem lidos
      o_IN_READ_ADDR0 : out std_logic_vector (ADDR_WIDTH - 1 downto 0);
      o_IN_READ_ADDR1 : out std_logic_vector (ADDR_WIDTH - 1 downto 0);
      o_IN_READ_ADDR2 : out std_logic_vector (ADDR_WIDTH - 1 downto 0); 
      ---------------------------------
      ---------------------------------
      
      -- sinal para rom de pesos
      o_PES_READ_ENA  : out std_logic; 
      o_PES_READ_ADDR : out std_logic_vector(7 downto 0);  -- bits para enderecamento ROM de pesos
      
      -- SINAL PARA ROM DE BIAS E SCALES
      o_BIAS_READ_ADDR : out STD_LOGIC_VECTOR (4 DOWNTO 0);
      o_BIAS_READ_ENA  : out std_logic; 
      
      -- habilita escrita nos registradores de bias e scale
      o_BIAS_WRITE_ENA :  out std_logic;
      o_SCALE_WRITE_ENA : out std_logic;
      
      
      ---------------------------------
      -- sinais para núcleos convolucionais
      ---------------------------------
      -- habilita deslocamento dos registradores de pixels e pesos
      o_PIX_SHIFT_ENA : out  std_logic;
      o_PES_SHIFT_ENA : out  std_logic;
      
      -- endereco do NC para carregar pesos     
      o_NC_ADDR : out std_logic_vector(c_NC-1 downto 0);    
      
      -- seleciona linha dos registradores de deslocamento
      o_PES_ROW_SEL : out std_logic_vector(1 downto 0);

      -- seleciona saida de NCs
      o_NC_O_SEL      : out  std_logic_vector(c_NC_SEL_WIDHT - 1 downto 0);
      -- habilita acumulador de pixels de saida dos NCs
      o_ACC_ENA       : out  std_logic;
      -- reseta acumulador de pixels de saida dos NCs
      o_ACC_RST       : out  std_logic;
      -- seleciona configuração de conexao entre buffer e registradores de deslocamento
      o_ROW_SEL       : out std_logic_vector(1 downto 0); 
      ---------------------------------
      ---------------------------------
      
      ---------------------------------
      -- sinais para buffers de saida
      ---------------------------------
      -- habilita escrita buffer de saida
      o_OUT_WRITE_ENA : out  std_logic;
      -- incrementa endereco de saida
      o_OUT_INC_ADDR  : out  std_logic; 
      -- reset endreco de saida
      o_OUT_CLR_ADDR : out std_logic
      ---------------------------------
      ---------------------------------

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
      DATA_WIDTH : integer := 8;
      ADDR_WIDTH : integer := 10
    );
    port 
    (
      i_CLK       : in STD_LOGIC;
      i_CLR       : in STD_LOGIC;
      
      
      ---------------------------------
      -- sinais para buffers de entrada
      ---------------------------------
      -- habilita leitura
      i_IN_READ_ENA  : in std_logic;
      -- dado de entrada
      i_IN_DATA      : in  t_CONV1_IN;
      -- habilita escrita    
      i_IN_WRITE_ENA : in std_logic;    
      -- linha de buffer selecionada
      i_IN_SEL_LINE  : in std_logic_vector (1 downto 0);    
   
      -- enderecos a serem lidos
      i_IN_READ_ADDR0   : in std_logic_vector (ADDR_WIDTH - 1 downto 0);
      i_IN_READ_ADDR1   : in std_logic_vector (ADDR_WIDTH - 1 downto 0);
      i_IN_READ_ADDR2   : in std_logic_vector (ADDR_WIDTH - 1 downto 0); 
      
      -- endereco a ser escrito
      i_IN_WRITE_ADDR  : in std_logic_vector (ADDR_WIDTH - 1 downto 0);
      ---------------------------------
      ---------------------------------
      
      
      -- sinal para rom de pesos
      i_PES_READ_ENA  : in std_logic; 
      i_PES_READ_ADDR : in std_logic_vector(7 downto 0);  -- bits para enderecamento ROM de pesos
      
      -- SINAL PARA ROM DE BIAS E SCALES
      i_BIAS_READ_ADDR : IN STD_LOGIC_VECTOR (4 DOWNTO 0);
      i_BIAS_READ_ENA  : in std_logic; 
      
      -- habilita escrita nos registradores de bias e scale
      i_BIAS_WRITE_ENA :  in std_logic;
      i_SCALE_WRITE_ENA : in std_logic;
      
      ---------------------------------
      -- sinais para núcleos convolucionais
      ---------------------------------
      -- habilita deslocamento dos registradores de pixels e pesos
      i_PIX_SHIFT_ENA : in STD_LOGIC;    
      i_PES_SHIFT_ENA : in STD_LOGIC;    
      
      -- endereco do NC para carregar pesos     
      i_PES_SHIFT_ADDR : in std_logic_vector(c_NC-1 downto 0);    
      
      -- seleciona linha dos registradores de deslocamento
      i_PES_ROW_SEL : in std_logic_vector(1 downto 0);
      
      -- seleciona saida de NCs
      i_NC_O_SEL : IN  std_logic_vector(c_NC_SEL_WIDHT - 1 DOWNTO 0); 
      -- habilita acumulador de pixels de saida dos NCs
      i_ACC_ENA : in std_logic;
      -- reseta acumulador de pixels de saida dos NCs
      i_ACC_RST       : in  std_logic;
      
      -- seleciona configuração de conexao entre buffer e registradores de deslocamento
      i_ROW_SEL : in std_logic_vector(1 downto 0);    
      ---------------------------------
      ---------------------------------
      
      
      ---------------------------------
      -- sinais para buffers de saida
      ---------------------------------
      -- habilita escrita buffer de saida
      i_OUT_WRITE_ENA : in std_logic;
      -- habilita leitura buffer de saida
      i_OUT_READ_ENA : in std_logic;
      -- endereco de leitura buffer de saida
      i_OUT_READ_ADDR : in std_logic_vector (9 downto 0);
      -- incrementa endereco de saida
      i_OUT_INC_ADDR : in std_logic;
      -- reset endreco de saida
      i_OUT_CLR_ADDR : in std_logic;
      -- saida dos buffers de saida
      o_OUT_DATA : out t_CONV1_OUT
      ---------------------------------
      ---------------------------------

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
  signal w_PES_READ_ENA  : std_logic; 
  signal w_PES_READ_ADDR : std_logic_vector(7 downto 0);  -- bits para enderecamento ROM de pesos
  
  -- SINAL PARA ROM DE BIAS E SCALES
  signal w_BIAS_READ_ADDR : std_logic_vector(4 DOWNTO 0);
  signal w_BIAS_READ_ENA  : std_logic; 
  
  -- habilita escrita nos registradores de bias e scale
  signal w_BIAS_WRITE_ENA :  std_logic;
  signal w_SCALE_WRITE_ENA : std_logic;
  ----------------------------------
  
  
  ---------------------------------
  -- sinais para núcleos convolucionais
  ---------------------------------
  -- habilita deslocamento dos registradores de pixels e pesos
  signal w_PIX_SHIFT_ENA : std_logic;
  signal w_PES_SHIFT_ENA : std_logic;
  
  -- endereco do NC para carregar pesos     
  signal w_NC_ADDR : std_logic_vector(c_NC-1 downto 0);    
  
  -- seleciona linha dos registradores de deslocamento
  signal w_PES_ROW_SEL : std_logic_vector(1 downto 0);

  -- seleciona saida de NCs
  signal w_NC_O_SEL      : std_logic_vector(c_NC_SEL_WIDHT - 1 downto 0);
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
  -- habilita escrita buffer de saida
  signal w_OUT_WRITE_ENA : std_logic;
  -- incrementa endereco de saida
  signal w_OUT_INC_ADDR  : std_logic; 
  -- reset endreco de saida
  signal w_OUT_CLR_ADDR  : std_logic;
  ---------------------------------
  ---------------------------------
  

begin
  
  
  u_CONTROLE : CONV1_CRT     
              generic map 
              (
                H => H, -- iFMAP Height 
                W => W, -- iFMAP Width 
                C => C, -- iFMAP Chanels (filter Chanels also)
                R => R, -- filter Height 
                S => S, -- filter Width     
                M => M, -- Number of filters (oFMAP Chanels also)
                DATA_WIDTH  => 8,
                ADDR_WIDTH  => 10,    
                OFFSET_ADDR => OFFSET_ADDR, -- 24dec
                NUM_PES_FILTER_CHA => NUM_PES_FILTER_CHA, -- quantidade de peso por filtro por canal(R*S) (de 0 a 8)
                LAST_PES    => LAST_PES,  -- quantidade de pesos (162)
                LAST_BIAS   => LAST_BIAS, -- quantidade de bias e scale (12)
                LAST_ROW    => LAST_ROW,  -- 32 por conta do padd
                LAST_COL    => LAST_COL   -- 24 por conta do padd
               
              )
              port map
              (
                i_CLK           => i_CLK,
                i_CLR           => i_CLR,
                i_GO            => i_GO,
                i_LOAD          => i_LOAD,
                o_READY         => o_READY,
                o_IN_READ_ENA   => w_IN_READ_ENA,
                o_IN_READ_ADDR0 => w_IN_READ_ADDR0 ,
                o_IN_READ_ADDR1 => w_IN_READ_ADDR1 ,
                o_IN_READ_ADDR2 => w_IN_READ_ADDR2 ,
                o_PES_READ_ENA    => w_PES_READ_ENA   ,
                o_PES_READ_ADDR   => w_PES_READ_ADDR  ,
                o_BIAS_READ_ADDR  => w_BIAS_READ_ADDR ,
                o_BIAS_READ_ENA   => w_BIAS_READ_ENA  ,
                o_BIAS_WRITE_ENA  => w_BIAS_WRITE_ENA ,
                o_SCALE_WRITE_ENA => w_SCALE_WRITE_ENA,
                o_PIX_SHIFT_ENA => w_PIX_SHIFT_ENA,
                o_PES_SHIFT_ENA => w_PES_SHIFT_ENA,
                o_NC_ADDR       => w_NC_ADDR,
                o_PES_ROW_SEL   => w_PES_ROW_SEL   ,
                o_NC_O_SEL      => w_NC_O_SEL,                
                o_ACC_ENA       => w_ACC_ENA,
                o_ACC_RST       => w_ACC_RST,
                o_ROW_SEL       => w_ROW_SEL,
                o_OUT_WRITE_ENA => w_OUT_WRITE_ENA,
                o_OUT_INC_ADDR  => w_OUT_INC_ADDR,
                o_OUT_CLR_ADDR  => w_OUT_CLR_ADDR
              );
            
  u_OPERACIONAL : CONV1_OP
              generic map
              (
                H => H, -- iFMAP Height 
                W => W, -- iFMAP Width 
                C => C, -- iFMAP Chanels (filter Chanels also)
                R => R, -- filter Height 
                S => S, -- filter Width     
                M => M, -- Number of filters (oFMAP Chanels also)                
                DATA_WIDTH => 8,
                ADDR_WIDTH => 10
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
                i_PES_READ_ENA    => w_PES_READ_ENA    ,
                i_PES_READ_ADDR   => w_PES_READ_ADDR   ,
                i_BIAS_READ_ADDR  => w_BIAS_READ_ADDR  ,
                i_BIAS_READ_ENA   => w_BIAS_READ_ENA   ,
                i_BIAS_WRITE_ENA  => w_BIAS_WRITE_ENA  ,
                i_SCALE_WRITE_ENA => w_SCALE_WRITE_ENA ,
                i_PES_SHIFT_ADDR  => w_NC_ADDR,
                i_PES_ROW_SEL     => w_PES_ROW_SEL  , 
                i_IN_WRITE_ADDR => i_IN_WRITE_ADDR, -- endereco escrita buffer entrada
                i_PIX_SHIFT_ENA => w_PIX_SHIFT_ENA,
                i_PES_SHIFT_ENA => w_PES_SHIFT_ENA,
                i_NC_O_SEL      => w_NC_O_SEL,
                i_ACC_ENA       => w_ACC_ENA,
                i_ACC_RST       => w_ACC_RST,
                i_ROW_SEL       => w_ROW_SEL,    
                i_OUT_WRITE_ENA => w_OUT_WRITE_ENA,
                i_OUT_READ_ENA  => i_OUT_READ_ENA, -- leitura buffer saida
                i_OUT_READ_ADDR => i_OUT_READ_ADDR, -- endereco leitura buffer saida
                i_OUT_INC_ADDR  => w_OUT_INC_ADDR,
                i_OUT_CLR_ADDR  => w_OUT_CLR_ADDR,
                o_OUT_DATA      => o_OUT_DATA     -- dado buffer saida
              );  
  
  
end arch;
