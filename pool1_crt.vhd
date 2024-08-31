-- controle pool1
library ieee;
use ieee.std_logic_1164.all;
use ieee.STD_LOGIC_UNSIGNED.all;
library work;
use work.types_pkg.all;

entity pool1_crt is
  generic (
    DATA_WIDTH : integer          := 8;
    ADDR_WIDTH : integer          := 10;
    MAX_ADDR   : std_logic_vector := "0110000000" -- W*H/2 => 32*24/2 = 384
  );

  port (
    i_CLK   : in std_logic;
    i_CLR   : in std_logic;
    i_GO    : in std_logic;  -- inicia maq    
    o_READY : out std_logic; -- fim maq

    ---------------------------------
    -- sinais para buffers de entrada
    ---------------------------------    
    -- enderecos a serem lidos
    o_IN_READ_ADDR0 : out std_logic_vector (ADDR_WIDTH - 1 downto 0);
    o_IN_READ_ADDR1 : out std_logic_vector (ADDR_WIDTH - 1 downto 0);
    ---------------------------------
    ---------------------------------

    ---------------------------------
    -- sinais para opercação convolucao
    ---------------------------------
    -- habilita deslocamento dos registradores de pixels e pesos
    o_PIX_SHIFT_ENA : out std_logic;
    ---------------------------------
    -- sinais para buffers de saida
    ---------------------------------
    -- habilita escrita buffer de saida
    o_OUT_WRITE_ENA  : out std_logic;
    o_OUT_WRITE_ADDR : out std_logic_vector (ADDR_WIDTH - 1 downto 0) := (others => '0')
    ---------------------------------
    ---------------------------------

  );
end pool1_crt;

architecture arch of pool1_crt is
  type t_STATE is (
    s_IDLE, -- IDLE

    s_LOAD_PIX1, -- carrega pixel1
    s_REG_PIX1,  -- registra pixel1
    s_LOAD_PIX2, -- carrega pixel2    
    s_REG_PIX2,  -- registra pixel2

    s_WRITE_OUT, -- escreve nos blocos de saída o resultado da comparacao

    s_LAST_ROW, -- verifica ultima linha

    s_END -- fim
  );
  signal r_STATE : t_STATE; -- state register
  signal w_NEXT  : t_STATE; -- next state    

  -----------------------------------------------------------------------
  -- enderecos para cada linha de buffer de entrada
  -- a cada deslocamento a baixo o offset é incrementado
  -- o endereco é a soma entre o contador e o offset para aquele bloco
  -----------------------------------------------------------------------
  -- sinais contador para endereco de buffer de entrada  
  signal w_IN_READ_ADDR : std_logic_vector (ADDR_WIDTH - 1 downto 0);
  signal w_INC_IN_ADDR  : std_logic;
  signal w_RST_IN_ADDR  : std_logic;

  signal w_END_ROW      : std_logic;
  signal w_INC_OUT_ADDR : std_logic;

  -- componente contador para enderecaomento
  component counter is
    generic (
      DATA_WIDTH : integer := 8;
      STEP       : integer := 1
    );
    port (
      i_CLK       : in std_logic;
      i_RESET     : in std_logic;
      i_INC       : in std_logic;
      i_RESET_VAL : in std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
      o_Q         : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
  end component;

begin

  p_STATE : process (i_CLK, i_CLR)
  begin
    if (i_CLR = '1') then
      r_STATE <= s_IDLE; --initial state
    elsif (rising_edge(i_CLK)) then
      r_STATE <= w_NEXT; --next state
    end if;
  end process;
  p_NEXT : process (r_STATE, i_GO, w_END_ROW)
  begin
    case (r_STATE) is
      when s_IDLE => -- aguarda sinal go
        if (i_GO = '1') then
          w_NEXT <= s_LOAD_PIX1;
        else
          w_NEXT <= s_IDLE;
        end if;

      when s_LOAD_PIX1 => -- habilita leitura pixel de entrada
        w_NEXT <= s_REG_PIX1;

      when s_REG_PIX1 => -- habilita leitura pixel de entrada
        w_NEXT <= s_LOAD_PIX2;

      when s_LOAD_PIX2 => -- habilita leitura pixel de entrada
        w_NEXT <= s_REG_PIX2;

      when s_REG_PIX2 => -- habilita leitura pixel de entrada
        w_NEXT <= s_WRITE_OUT;
      when s_WRITE_OUT => -- salva no bloco de saida
        w_NEXT <= s_LAST_ROW;

      when s_LAST_ROW => -- verifica fim linhas
        if (w_END_ROW = '1') then
          w_NEXT <= s_END;
        else
          w_NEXT <= s_LOAD_PIX1;
        end if;

      when s_END => -- fim
        w_NEXT <= s_IDLE;

      when others =>
        w_NEXT <= s_IDLE;

    end case;
  end process;

  -----------------------------------------------------------------------
  -- sinais para buffers de entrada
  ---------------------------------  
  w_INC_IN_ADDR <= '1' when (r_STATE = s_LOAD_PIX1 or r_STATE = s_LOAD_PIX2) else
    '0';
  w_RST_IN_ADDR <= '1' when (i_CLR = '1') else
    '0';
  -- contador de endereco
  u_INPUT_ADDR : counter
  generic map(ADDR_WIDTH, 1)
  port map(
    i_CLK   => i_CLK,
    i_RESET => w_RST_IN_ADDR,
    i_INC   => w_INC_IN_ADDR,
    i_RESET_VAL => (others => '0'),
    o_Q     => w_IN_READ_ADDR
  );

  o_IN_READ_ADDR0 <= w_IN_READ_ADDR;
  o_IN_READ_ADDR1 <= w_IN_READ_ADDR;
  -----------------------------------------------------------------------    
  ---------------------------------
  w_END_ROW <= '1' when (w_IN_READ_ADDR = MAX_ADDR) else
    '0';

  ---------------------------------
  o_PIX_SHIFT_ENA <= '1' when (r_STATE = s_REG_PIX1 or r_STATE = s_REG_PIX2) else
    '0';
  ---------------------------------
  ---------------------------------
  -- sinais para buffers de saida
  ---------------------------------    
  -- habilita escrita buffer de saida  
  w_INC_OUT_ADDR <= '1' when (r_STATE = s_WRITE_OUT) else
    '0';
  o_OUT_WRITE_ENA <= w_INC_OUT_ADDR;

  -- contador de endereco
  u_OUTPUT_ADDR : counter
  generic map(ADDR_WIDTH, 1)
  port map(
    i_CLK   => i_CLK,
    i_RESET => i_CLR,
    i_INC   => w_INC_OUT_ADDR,
    i_RESET_VAL => (others => '0'),
    o_Q     => o_OUT_WRITE_ADDR
  );
  ---------------------------------

  -- sinaliza fim maq estado
  o_READY <= '1' when (r_STATE = s_END) else
    '0';

end arch;
