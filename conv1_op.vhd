-- Conv1 Opercional

-------------------------------
-- Cx3 buffers de entrada 
-- MxC Nucleos convolucionais
-- Arvore de somadores
-- Reg
-- Relu
-- Mx1 buffers de saída
-------------------------------

------------------------------------------------------
-- conv1_op entity
------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.STD_LOGIC_UNSIGNED.all;
library work;
use work.types_pkg.all;

entity conv1_op is
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
    WEIGHTS_ADDRESS_WIDTH : integer := 8; -- numero de bits para enderecar pesos
    BIAS_ADDRESS_WIDTH : integer := 5; -- numero de bits para enderecar registradores de bias e scales
    DATA_WIDTH : integer := 8;
    ADDR_WIDTH : integer := 10;
    SCALE_SHIFT : t_ARRAY_OF_INTEGER
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
    i_IN_DATA      : in  t_ARRAY_OF_LOGIC_VECTOR(0 to C-1)(DATA_WIDTH-1 downto 0);
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
    i_PES : in std_logic_vector(7 downto 0);
    
    -- SINAL PARA ROM DE BIAS E SCALES        
    i_BIAS_WRITE_ADDR : IN STD_LOGIC_VECTOR (BIAS_ADDRESS_WIDTH-1 DOWNTO 0);
    i_BIAS : in std_logic_vector (31 downto 0);
    
    -- habilita escrita nos registradores de bias e scale
    i_BIAS_WRITE_ENA :  in std_logic;
    i_SCALE_WRITE_ENA : in std_logic;
    
    ---------------------------------
    -- sinais para núcleos convolucionais
    ---------------------------------
    -- habilita deslocamento dos registradores de pixels e pesos
    i_PIX_SHIFT_ENA : in STD_LOGIC;    
    i_PES_SHIFT_ENA : in STD_LOGIC;    
    i_PES_SHIFT_ADDR : in std_logic_vector(NC_ADDRESS_WIDTH-1 downto 0);    -- endereco do NC para carregar pesos     
    
    -- seleciona linha dos registradores de deslocamento
    i_PES_ROW_SEL : in std_logic_vector(1 downto 0);
    
    -- seleciona saida de NCs
    i_NC_O_SEL : IN  std_logic_vector(NC_SEL_WIDTH - 1 DOWNTO 0); 
    -- habilita acumulador de pixels de saida dos NCs
    i_ACC_ENA : in std_logic;
    -- reseta acumulador de pixels de saida dos NCs
    i_ACC_RST : in std_logic;
    
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
    i_OUT_READ_ADDR : in std_logic_vector (9 downto 0) := (others => '0');
    -- incrementa endereco de saida
    i_OUT_INC_ADDR : in std_logic;
    -- reset endreco de saida
    i_OUT_CLR_ADDR : in std_logic;
    -- saida dos buffers de saida
    o_OUT_DATA : out t_ARRAY_OF_LOGIC_VECTOR(0 to M-1)(DATA_WIDTH-1 downto 0)
    ---------------------------------
    ---------------------------------

  );
end conv1_op;

architecture arch of conv1_op is
  
  -------------------------------
  -- Buffer de entrada/saida
  -------------------------------
  component io_buffer is
    generic 
    (
      NUM_BLOCKS : integer := 3;    
      DATA_WIDTH : integer := 8;    
      ADDR_WIDTH : integer := 10
    );
    
    port 
    (
      i_CLK       : in  std_logic;
      i_CLR       : in  std_logic;
      
      -- dado de entrada
      i_DATA      : in  std_logic_vector (DATA_WIDTH - 1 downto 0);
      
      -- habilita leitura
      i_READ_ENA  : in std_logic;
      
      -- habilita escrita    
      i_WRITE_ENA : in std_logic;
      
      -- linha de buffer selecionada
      i_SEL_LINE  : in std_logic_vector (1 downto 0);
      
      -- endereco a ser lido
      i_READ_ADDR0   : in std_logic_vector (ADDR_WIDTH - 1 downto 0);
      i_READ_ADDR1   : in std_logic_vector (ADDR_WIDTH - 1 downto 0);
      i_READ_ADDR2   : in std_logic_vector (ADDR_WIDTH - 1 downto 0);
    
      -- endereco a ser escrito
      i_WRITE_ADDR  : in std_logic_vector (ADDR_WIDTH - 1 downto 0);
      
      -- dados de saida     
      o_DATA_ROW_0  : out std_logic_vector (DATA_WIDTH - 1 downto 0);
      o_DATA_ROW_1  : out std_logic_vector (DATA_WIDTH - 1 downto 0);
      o_DATA_ROW_2  : out std_logic_vector (DATA_WIDTH - 1 downto 0)
    );
  end component;
  -------------------------------
  
  -------------------------------
  -- Nucleo convolucional
  -------------------------------
  component nucleo_convolucional is
    generic 
    (
      i_DATA_WIDTH : INTEGER := 8;
      w_CONV_OUT   : INTEGER := 16;           
      o_DATA_WIDTH : INTEGER := 32
    );  

    port 
    (
      i_CLK       : in STD_LOGIC;
      i_CLR       : in STD_LOGIC;
      
      -- habilita deslocamento dos registradores
      i_PIX_SHIFT_ENA : in STD_LOGIC;
      i_PES_SHIFT_ENA : in STD_LOGIC;    

      -- linhas de pixels
      i_PIX_ROW_1 : in STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);
      i_PIX_ROW_2 : in STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);
      i_PIX_ROW_3 : in STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);  
      
      -- habilita escrita em uma das linhas de pesos
      i_PES_ROW_SEL : in std_logic_vector (1 downto 0);
      
      -- peso de entrada
      i_PES : in STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);
      
      -- pixel de saida
      o_PIX       : out STD_LOGIC_VECTOR (o_DATA_WIDTH - 1 downto 0)

    );
  end component;
  ------------------------------
  
  -------------------------------
  -- Registrador
  -------------------------------
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
  -------------------------------
  
  
  -------------------------------
  -- Somador 32 bits
  -------------------------------    
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
  end component;
  -------------------------------

  -------------------------------
  -- Mux conv 1 
  -------------------------------     
  component generic_multiplexer is      
    generic 
    (
      NC_SEL_WIDTH : integer := 2;
      DATA_WIDTH : integer := 32
    );
    PORT 
    (    
      i_A   : IN  t_ARRAY_OF_LOGIC_VECTOR(0 to (2**NC_SEL_WIDTH)-1)(DATA_WIDTH-1 downto 0) := (others => (others => '0'));
      i_SEL : IN  std_logic_vector(NC_SEL_WIDTH - 1 DOWNTO 0);
      o_Q   : OUT std_logic_vector(31 DOWNTO 0)
    );
  END component;
  ------------------------------- 
  
  
  -------------------------------
  -- RELU
  -------------------------------   
  component relu is
    generic (DATA_WIDTH : INTEGER := 8);    
    port 
    (
      -- pixel de entrada
      i_PIX : in STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
      -- pixel de saida
      o_PIX : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0)
    );
  end component;
  -------------------------------
  
  
  -------------------------------
  -- memoria
  -------------------------------
  component generic_ram IS
    GENERIC (DATA_WIDTH : INTEGER := 8;
             DATA_DEPTH : INTEGER := 10);     
    PORT
    (
      address	: IN STD_LOGIC_VECTOR (DATA_DEPTH - 1 DOWNTO 0);
      clock		: IN STD_LOGIC  := '1';
      data		: IN STD_LOGIC_VECTOR (DATA_WIDTH - 1 DOWNTO 0);
      wren		: IN STD_LOGIC ;
      q		    : OUT STD_LOGIC_VECTOR (DATA_WIDTH - 1 DOWNTO 0)
    );
  END component;
  -------------------------------   
  
  -------------------------------
  -------------------------------
  component one_hot_encoder is
    generic 
    (
      DATA_WIDTH : integer := 5;
      OUT_WIDTH  : integer := 18 -- quantidade de elementos enderecados   
    );
    port 
    (
       i_DATA : in std_logic_vector(DATA_WIDTH-1 downto 0);
       o_DATA : out std_logic_vector(OUT_WIDTH-1 downto 0)
    );
  end component;
  -------------------------------
  
  --- CONTADOR 
  component counter is
    generic 
    (    
      DATA_WIDTH : integer := 8;   
      STEP : integer := 1
    );
    port 
    (
      i_CLK       : in std_logic;
      i_RESET     : in std_logic;
      i_INC       : in std_logic;
      i_RESET_VAL : in std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
      o_Q         : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
  end component;

  
  
  
  -- sinal one-hot para habilitar escrita dos pesos nos NCs
  signal w_NC_PES_ADDR : std_logic_vector (NC_OHE_WIDTH - 1 downto 0);
  
  -- sinal one-hot para habilitar escrita dos bias e scales
  signal w_BIAS_SCALE_ADDR : std_logic_vector (BIAS_OHE_WIDTH-1 downto 0);   
  
  -- saida de todos NCs
  -- signal w_o_NC : t_NC_O_VET;
  signal w_o_NC : t_ARRAY_OF_LOGIC_VECTOR(0 to (C*M) - 1)(31 downto 0);
  
  -- saida mux NC
  -- signal w_o_MUX_NC : t_MUX_O_VET;  
  signal w_o_MUX_NC : t_ARRAY_OF_LOGIC_VECTOR(0 to M - 1)(31 downto 0);
  
  -- saida somador acumulador entre canais de filtros
  signal w_o_ADD : t_ARRAY_OF_LOGIC_VECTOR(0 to M - 1)(31 downto 0);
  
  -- saida soma bias + saida acumulador
  signal w_o_BIAS_ACC : t_ARRAY_OF_LOGIC_VECTOR(0 to M - 1)(31 downto 0);
  
  -- contador endereco saida
  signal r_OUT_ADDR : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0'); 
  signal w_RST_OUT_ADDR : std_logic;
  
  -- roteador de pixels (configuração linha de buffer para linha de shift-registers)
  signal w_CONFIG0, w_CONFIG1 : std_logic;
    
  -- entrada one-hot para reg bias
  signal w_BIAS_REG_ENA : std_logic_vector(M-1 downto 0);    
  
  -- saida registradores bias
  signal w_o_BIAS_REG : t_ARRAY_OF_LOGIC_VECTOR(0 to M - 1)(31 downto 0);
  
  -- entrada one-hot para reg scale
  signal w_SCALE_REG_ENA : std_logic_vector(M-1 downto 0); 
      
  -- saida registradores scale
  signal w_o_SCALE_REG : t_ARRAY_OF_LOGIC_VECTOR(0 to M - 1)(31 downto 0);
  
    
begin
  
  -- seleciona configuração de conexao entre buffer e registradores de deslocamento
  w_CONFIG0 <= '1' when (i_ROW_SEL = "00") else '0';
  w_CONFIG1 <= '1' when (i_ROW_SEL = "01") else '0';
  
  ------------------------------------------
  --  para cada input buffers e nucleos convolucionais
  GEN_CHANNELS: 
    for i in 0 to C-1 generate
      
      -- linhas de pixels
      signal w_RAM_PIX_ROW_1 : STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
      signal w_RAM_PIX_ROW_2 : STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
      signal w_RAM_PIX_ROW_3 : STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
      signal w_NC_PIX_ROW_1 : STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
      signal w_NC_PIX_ROW_2 : STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
      signal w_NC_PIX_ROW_3 : STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);                

    begin
    
    
    -- input buffers 
    IO_BUFFERS : io_buffer 
              generic map 
              (
                NUM_BLOCKS => 3,    -- tres blocos por buffer
                DATA_WIDTH => DATA_WIDTH,    
                ADDR_WIDTH => ADDR_WIDTH   -- 2^10 enderecos                
              )
              port map 
              (
               i_CLK         =>  i_CLK           ,
               i_CLR         =>  i_CLR           ,
               i_DATA        =>  i_IN_DATA(i)    ,
               i_READ_ENA    =>  i_IN_READ_ENA   ,
               i_WRITE_ENA   =>  i_IN_WRITE_ENA  ,
               i_SEL_LINE    =>  i_IN_SEL_LINE   ,
               i_READ_ADDR0  =>  i_IN_READ_ADDR0 ,
               i_READ_ADDR1  =>  i_IN_READ_ADDR1 ,
               i_READ_ADDR2  =>  i_IN_READ_ADDR2 ,
               i_WRITE_ADDR  =>  i_IN_WRITE_ADDR ,
               o_DATA_ROW_0  =>  w_RAM_PIX_ROW_1 ,
               o_DATA_ROW_1  =>  w_RAM_PIX_ROW_2 ,
               o_DATA_ROW_2  =>  w_RAM_PIX_ROW_3
              );
    
    -- a cada deslocamento a baixo as linhas de pixels 
    -- deve ser re-conectadas aos registradores dos NCs
    -- 1) nc_row1 < ram_row1 ; nc_row2 < ram_row2 ; nc_row3 <= ram_row3
    -- 2) nc_row1 < ram_row2 ; nc_row2 < ram_row3 ; nc_row3 <= ram_row1
    -- 3) nc_row1 < ram_row3 ; nc_row2 < ram_row1 ; nc_row3 <= ram_row2
    w_NC_PIX_ROW_1 <= w_RAM_PIX_ROW_1 when (w_CONFIG0 = '1') else 
                      w_RAM_PIX_ROW_2 when (w_CONFIG1 = '1') else
                      w_RAM_PIX_ROW_3;
    w_NC_PIX_ROW_2 <= w_RAM_PIX_ROW_2 when (w_CONFIG0 = '1') else 
                      w_RAM_PIX_ROW_3 when (w_CONFIG1 = '1') else
                      w_RAM_PIX_ROW_1;
    w_NC_PIX_ROW_3 <= w_RAM_PIX_ROW_3 when (w_CONFIG0 = '1') else 
                      w_RAM_PIX_ROW_1 when (w_CONFIG1 = '1') else
                      w_RAM_PIX_ROW_2;
                 
    
    -----------------------------------
    -- para cada filtro
    GEN_FILTERS:   
      for j in 0 to M-1 generate
      
        -- NC pixel de saida
        signal w_o_PIX       :  STD_LOGIC_VECTOR (31 downto 0) := (others => '0');        
        signal w_cout, w_overflow, w_underflow  : std_logic := '0';
				signal w_PES_SHIFT_ENABLE : std_logic := '0';                       

      begin
		
			-- habilita deslocamento de peso                       
      w_PES_SHIFT_ENABLE <= w_NC_PES_ADDR((j*C)+i) AND i_PES_SHIFT_ENA;

      -- nucleos convolucionais 
      NCX : nucleo_convolucional             
              port map 
              (
                i_CLK           => i_CLK,          
                i_CLR           => i_CLR,           
                i_PIX_SHIFT_ENA => i_PIX_SHIFT_ENA,
                i_PES_SHIFT_ENA => w_PES_SHIFT_ENABLE,  
                i_PIX_ROW_1     => w_NC_PIX_ROW_1,    
                i_PIX_ROW_2     => w_NC_PIX_ROW_2,    
                i_PIX_ROW_3     => w_NC_PIX_ROW_3,  
                i_PES_ROW_SEL   => i_PES_ROW_SEL, -- habilita linha de peso
                i_PES           => i_PES,       -- peso de entrada
                o_PIX           => w_o_PIX
              );
              
      -- registradores de saida para os NCs
      REGX : registrador 
              generic map (32)
              port map 
              (
                i_CLK,
                i_CLR,
                '1',
                w_o_PIX,          
                w_o_NC((j*C)+i)  -- indexação (000,111,222,333,444,555)
              );
    end generate GEN_FILTERS;
  end generate GEN_CHANNELS;
  
  
  
  -- multiplexadores e acumulador para resultado da convolucao
  GEN_FILTER_OUT: 
  for i in 0 to M-1 generate
    
    -- entrada MUX saída NCs      
    signal w_MUX_I_VET : t_ARRAY_OF_LOGIC_VECTOR(0 to (2**NC_SEL_WIDTH)-1)(31 downto 0) := (others => (others => '0'));
        
    -- sinais para somadores
    signal w_COUT, w_OVERFLOW, w_UNDERFLOW : std_logic;
    signal w_ADD_OUT : STD_LOGIC_VECTOR(31  downto 0);
    
    -- sinal de saida relu
    signal w_RELU_OUT : STD_LOGIC_VECTOR(7 downto 0);       
    
    -- saida scale down
    signal w_o_SCALE_DOWN : std_logic_vector(63 downto 0) := (others => '0');
    
    -- cast para 32 bits
    signal w_o_CAST : std_logic_vector(31 downto 0) := (others => '0');


		signal w_BIAS_WRITE_ENA : std_logic;
		signal w_SCALE_WRITE_ENA : std_logic;
    
  begin
    
    -- saida NC entrada mux
    -----------------------
    GEN_MUX_C:
    for j in 0 to C-1 generate
      w_MUX_I_VET(j) <= w_o_NC((i*C)+j);
    end generate GEN_MUX_C;
    -----------------------
    
    
    -- mux para soma dos valores de saida
    MUXX : generic_multiplexer 
                generic map (NC_SEL_WIDTH, 32)
                port map
                (
                  i_A  => w_MUX_I_VET,
                  i_SEL=> i_NC_O_SEL,
                  o_Q  => w_o_MUX_NC(i)
                );
    
    -- somador para acumular saida dos canais de um NC
    ADDX : add32
            port map 
            (
              a         => w_o_ADD(i),
              b         => w_o_MUX_NC(i),
              cin       => '0',
              sum1      => w_ADD_OUT,
              cout      => w_COUT,
              overflow  => w_OVERFLOW,
              underflow => w_UNDERFLOW
            );
    
    -- registrador para acumular saida dos canais de um NC
    REGX : registrador 
            generic map (32)
            port map 
            (
              i_CLK,
              i_ACC_RST,
              i_ACC_ENA,
              w_ADD_OUT,          
              w_o_ADD(i)  
            );    
    
		-- habilita escrita reg bias
		w_BIAS_WRITE_ENA <= w_BIAS_SCALE_ADDR(i) and i_BIAS_WRITE_ENA;

    -- registrador de BIAS    
    BIAS_REGX : registrador 
            generic map (32)
            port map 
            (
              i_CLK,
              i_CLR,
              w_BIAS_WRITE_ENA, 
              i_BIAS,           -- entrada (saida da ROM bias)
              w_o_BIAS_REG(i)  
            );
    
		-- habilita escrita reg scale
		w_SCALE_WRITE_ENA <= w_BIAS_SCALE_ADDR(i+M) and i_SCALE_WRITE_ENA;

    -- registrador de scale down    
    SCALE_REGX : registrador 
            generic map (32)
            port map 
            (
              i_CLK,
              i_CLR,
              w_SCALE_WRITE_ENA, -- saida one-hot para reg scale
              i_BIAS,          -- entrada (saida da ROM bias)
              w_o_SCALE_REG(i)  
            );
    
    -- adiciona saida acumulador + bias
    w_o_BIAS_ACC(i) <= w_o_ADD(i) + w_o_BIAS_REG(i); 
    
    -- scale down (32*32 = 64bits)
    -- multiplex entre 0 e valor do scale down selecionado pelo bit de sinal    
    w_o_SCALE_DOWN <= (others => '0') when (w_o_BIAS_ACC(i)(31) = '1') else w_o_BIAS_ACC(i) * w_o_SCALE_REG(i);
        
    -- cast para 32 bits
    w_o_CAST(31 downto SCALE_SHIFT(i)) <= w_o_SCALE_DOWN(63 downto 32+SCALE_SHIFT(i));    
    
    
    -- bloco RELU
    RELUX : relu 
              generic map (DATA_WIDTH => 8)    
              port map
              (
                -- pixel de entrada
                i_PIX => w_o_CAST(SCALE_SHIFT(i)+7 downto SCALE_SHIFT(i)),
                -- pixel de saida
                o_PIX => w_RELU_OUT
              );
    
    -- buffer de saida
    OUT_BUFFER : io_buffer 
              generic map 
              (
                NUM_BLOCKS => 1,    
                DATA_WIDTH => DATA_WIDTH,    
                ADDR_WIDTH => ADDR_WIDTH
              )
              port map 
              (
                i_CLK            ,
                i_CLR            ,
                w_RELU_OUT       , -- saida bloco relu/ entrada buffer
                i_OUT_READ_ENA   , -- habilita leitura do bloco de saida
                i_OUT_WRITE_ENA  , -- habilita escrita no bloco de saida
                "00"             , -- não necessario selecionar, pois só um bloco de saida por buffer
                i_OUT_READ_ADDR  , -- endereco de leitura
                i_OUT_READ_ADDR  , -- não importa (apenas um bloco)
                i_OUT_READ_ADDR  , -- não importa (apenas um bloco)
                r_OUT_ADDR       , -- endereco de escrita
                o_OUT_DATA(i)     -- saida 
              );
  
  
  end generate GEN_FILTER_OUT;
  
    
  -- decodifica endereco de NC para habilitar escrita nos reg de deslocamento PESOS
  u_OHE_PES : one_hot_encoder
          generic map (DATA_WIDTH => NC_ADDRESS_WIDTH, -- bits para enderecamento NC
                       OUT_WIDTH  => M*C) -- numero de NC
          port map 
          (
             i_DATA => i_PES_SHIFT_ADDR,
             o_DATA => w_NC_PES_ADDR
          );  
  
  
  -- decodifica endereco da memoria ROM_BIAS para habilitar registradores de BIAS e SCALE
  u_OHE_BIAS : one_hot_encoder
          generic map (DATA_WIDTH => BIAS_ADDRESS_WIDTH, -- bits para enderecamento REG_BIAS + REG_SCALE
                       OUT_WIDTH => 2*M) -- numero de registradores
          port map 
          (
             i_DATA => i_BIAS_WRITE_ADDR,
             o_DATA => w_BIAS_SCALE_ADDR
          );
  
  
  
  w_RST_OUT_ADDR <= '1' when (i_CLR = '1' or i_OUT_CLR_ADDR = '1') else '0';
  
  -- contador de endereco de saida 
  u_OUT_ADDR : counter 
            generic map
            (    
              DATA_WIDTH => ADDR_WIDTH,  
              STEP => 1
            )
            port map
            (
              i_CLK       => i_CLK,
              i_RESET     => w_RST_OUT_ADDR,
              i_INC       => i_OUT_INC_ADDR,
              i_RESET_VAL => (others => '0'),
              o_Q         => r_OUT_ADDR
            );
  
end arch;







