
------------------------------------------------------
-- PACOTE DE TIPOS CUSTOMIZADOS internos do bloco CONV1
------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

package conv1_pkg IS
  constant c_CONV1_DATA_WIDTH : integer := 32;
  constant c_CONV1_C : integer := 3;   -- numero de canais
  constant c_CONV1_M : integer := 6;   -- numero de filtros
  constant c_CONV1_NC : integer := c_CONV1_M*c_CONV1_C;   -- numero de NC
  constant c_SEL_WIDHT : integer := 2; 
  
  -- tipo para saida dos NC
  type t_NC_O_VET is array (0 to c_CONV1_NC - 1) of STD_LOGIC_VECTOR(c_CONV1_DATA_WIDTH-1 downto 0);    
  
  -- tipo para saida dos MUXs
  type t_MUX_O_VET is array (0 to c_CONV1_M - 1) of STD_LOGIC_VECTOR(c_CONV1_DATA_WIDTH-1 downto 0);
  type t_MUX_I_VET is array (0 to c_CONV1_C - 1) of STD_LOGIC_VECTOR(c_CONV1_DATA_WIDTH-1 downto 0);
  
end package conv1_pkg;
------------------------------------------------------



------------------------------------------------------
-- Mux 6x1 DE 32 BITS 
-- 01/10/2021
-- George
-- R1
------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL; 
library work;
use work.conv1_pkg.all;

ENTITY mux_conv1 is             
  PORT 
  (  
    i_A   : IN  t_MUX_I_VET;
    i_SEL : IN  std_logic_vector(c_SEL_WIDHT DOWNTO 0); 
    o_Q   : OUT std_logic_vector(c_CONV1_DATA_WIDTH - 1 DOWNTO 0)
  );
END mux_conv1;
ARCHITECTURE arch OF mux_conv1 IS
BEGIN  
  o_Q <= i_A(to_integer(signed(i_SEL)));
END arch;
------------------------------------------------------



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
use work.conv1_pkg.all;
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
    i_IN_DATA      : in  std_logic_vector (DATA_WIDTH - 1 downto 0);
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
    
    
    
    ---------------------------------
    -- sinais para núcleos convolucionais
    ---------------------------------
    -- habilita deslocamento dos registradores de pixels e pesos
    i_PIX_SHIFT_ENA : in STD_LOGIC;
    i_PES_SHIFT_ENA : in STD_LOGIC;    
    
    -- seleciona saida de NCs
    i_NC_O_SEL : IN  std_logic_vector(c_SEL_WIDHT DOWNTO 0); 
    -- habilita acumulador de pixels de saida dos NCs
    i_ACC_ENA : in std_logic;
    
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

      -- linhas de pesos
      i_PES_ROW_1 : in STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);
      i_PES_ROW_2 : in STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);
      i_PES_ROW_3 : in STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);

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
  component mux_conv1 is             
    PORT 
    (  
      i_A   : IN  t_MUX_I_VET;
      i_SEL : IN  std_logic_vector(c_SEL_WIDHT DOWNTO 0); 
      o_Q   : OUT std_logic_vector(c_CONV1_DATA_WIDTH - 1 DOWNTO 0)
    );
  end component;
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
  

  -- saida de todos NCs
  signal w_o_NC : t_NC_O_VET;
  
  -- saida mux NC
  signal w_o_MUX_NC : t_MUX_O_VET;  
  
  -- saida somador
  signal w_o_ADD : t_MUX_O_VET;  
  
  -- contador endereco saida
  signal r_OUT_ADDR : std_logic_vector(9 downto 0) := (others => '0'); 
  
  signal w_CONFIG0, w_CONFIG1 : std_logic;
  
begin
  
  w_CONFIG0 <= '1' when (i_ROW_SEL = "00") else '0';
  w_CONFIG1 <= '1' when (i_ROW_SEL = "01") else '0';
  
  -- input buffers e nucleos convolucionais
  GEN_NC_C: 
    for i in 0 to C-1 generate
      
      -- linhas de pixels
      signal w_RAM_PIX_ROW_1 : STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
      signal w_RAM_PIX_ROW_2 : STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
      signal w_RAM_PIX_ROW_3 : STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
      signal w_NC_PIX_ROW_1 : STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
      signal w_NC_PIX_ROW_2 : STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
      signal w_NC_PIX_ROW_3 : STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
      
      
      -- linhas de pesos
      signal w_i_PES_ROW_1 : STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
      signal w_i_PES_ROW_2 : STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
      signal w_i_PES_ROW_3 : STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);


    begin
    
    -- input buffers 
    BUFFX : io_buffer 
              generic map 
              (
                NUM_BLOCKS => 3,    -- tres blocos por buffer
                DATA_WIDTH => 8,    
                ADDR_WIDTH => 10   -- 2^10 enderecos                
              )
              port map 
              (
                i_CLK           ,
                i_CLR           ,
                i_IN_DATA       ,
                i_IN_READ_ENA   ,
                i_IN_WRITE_ENA  ,
                i_IN_SEL_LINE   ,
                i_IN_READ_ADDR0 ,
                i_IN_READ_ADDR1 ,
                i_IN_READ_ADDR2 ,
                i_IN_WRITE_ADDR ,
                w_RAM_PIX_ROW_1 ,
                w_RAM_PIX_ROW_2 ,
                w_RAM_PIX_ROW_3
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
    
    
    GEN_NC_M:   
      for j in 0 to M-1 generate
      
        -- NC pixel de saida
        signal w_o_PIX       :  STD_LOGIC_VECTOR (32 - 1 downto 0) := (others => '0');        
        signal w_cout, w_overflow, w_underflow  : std_logic;
                       
      begin
      
      -- nucleos convolucionais 
      NCX : nucleo_convolucional             
              port map 
              (
                i_CLK, 
                i_CLR,
                i_PIX_SHIFT_ENA,
                i_PES_SHIFT_ENA,
                w_NC_PIX_ROW_1,                
                w_NC_PIX_ROW_2,                
                w_NC_PIX_ROW_3,
                w_i_PES_ROW_1,
                w_i_PES_ROW_2,
                w_i_PES_ROW_3,
                w_o_PIX
              );
              
      -- registradores de saida para os NCs
      REGX : registrador 
              generic map (c_CONV1_DATA_WIDTH)
              port map 
              (
                i_CLK,
                i_CLR,
                '1',
                w_o_PIX,          
                w_o_NC((j*C)+i)  -- indexação (000,111,222,333,444,555)
              );
    end generate GEN_NC_M;
  end generate GEN_NC_C;
  
  
  
  -- multiplexadores e acumulador para resultado da convolucao
  GEN_MUX_M: 
  for i in 0 to M-1 generate
    
    -- entrada MUX saída NCs
    signal w_MUX_I_VET : t_MUX_I_VET;    
    
    -- sinais para somadores
    signal w_COUT, w_OVERFLOW, w_UNDERFLOW : std_logic;
    signal w_ADD_OUT : STD_LOGIC_VECTOR(c_CONV1_DATA_WIDTH-1 downto 0);
    
    -- sinal de saida relu
    signal w_RELU_OUT : STD_LOGIC_VECTOR(7 downto 0);
    
    -- saida blocos de memoria
    signal w_i_PIX_ROW_2, w_i_PIX_ROW_3 : std_logic_vector (7 downto 0);
    
  begin

    GEN_MUX_C:
    for j in 0 to C-1 generate
      w_MUX_I_VET(j) <= w_o_NC((i*C)+j);
    end generate GEN_MUX_C;
    
    -- mux para soma dos valores de saida
    MUXX : mux_conv1 
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
            generic map (c_CONV1_DATA_WIDTH)
            port map 
            (
              i_CLK,
              i_CLR,
              i_ACC_ENA,
              w_ADD_OUT,          
              w_o_ADD(i)  
            );    
    
    -- bloco RELU
    RELUX : relu 
              generic map (DATA_WIDTH => 8)    
              port map
              (
                -- pixel de entrada
                i_PIX => w_o_ADD(i)(7 downto 0),
                -- pixel de saida
                o_PIX => w_RELU_OUT
              );
    
    -- buffer de saida
    BUFFX : io_buffer 
              generic map 
              (
                NUM_BLOCKS => 1,    
                DATA_WIDTH => 8,    
                ADDR_WIDTH => 10                
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
                o_OUT_DATA(i)    , -- saida 
                w_i_PIX_ROW_2    , -- apenas uma linha de saida
                w_i_PIX_ROW_3      -- apenas uma linha de saida
              );
  
  
  end generate GEN_MUX_M;
  
  -- contador de endereco de saida 
  r_OUT_ADDR <= (others => '0') when (i_CLR = '1' or i_OUT_CLR_ADDR = '1') else 
                (r_OUT_ADDR + "0000000001") when (rising_edge(i_CLK) and i_OUT_INC_ADDR = '1') else
                r_OUT_ADDR;
  
end arch;







