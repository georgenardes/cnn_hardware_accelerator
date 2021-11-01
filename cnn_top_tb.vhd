-- cnn_top_tb

-- CNN top file
-- integra todas as camadas da rede


library ieee;
use ieee.std_logic_1164.all;


entity cnn_top_tb is
end cnn_top_tb;



architecture arch of cnn_top_tb is 
  
  constant c_CLK_PERIOD : time := 2 ns;
  
  
  component cnn_top is
    port 
    (
      i_CLK       : in STD_LOGIC;
      i_CLR       : in STD_LOGIC;
      i_GO        : in STD_LOGIC;
      i_LOAD      : in std_logic;
      o_LOADED    : out std_logic;
      o_READY     : out std_logic
    );
  end component;
  
  
  signal w_CLK       : STD_LOGIC;
  signal w_CLR       : STD_LOGIC;
  signal w_GO        : STD_LOGIC;
  signal w_LOAD      : std_logic;
  signal w_LOADED    : std_logic;
  signal w_READY     : std_logic;
  
begin
  
  u_DUT : cnn_top 
          port map 
          (
            i_CLK    => w_CLK  ,
            i_CLR    => w_CLR  ,
            i_GO     => w_GO   ,
            i_LOAD   => w_LOAD ,
            o_LOADED => w_LOADED,
            o_READY  => w_READY
          );
          
          
  ---------------------
  p_CLK : process
  begin
    w_CLK <= '1';
    wait for c_CLK_PERIOD/2;
    w_CLK <= '0';
    wait for c_CLK_PERIOD/2;
  end process p_CLK;
  ---------------------
  
  p_TEST : process
	begin

		w_GO <= '0';
		w_LOAD <= '0';

	  --------------------------
		w_CLR <= '1'; -- clear 
		wait for 2 * c_CLK_PERIOD;
		w_CLR <= '0'; -- clear
		wait for c_CLK_PERIOD; 
		---------------------------

    -- carrega pesos
		w_LOAD <= '1';
		wait for c_CLK_PERIOD;
		w_LOAD <= '0';
		wait until w_LOADED = '1';
		-------------------

		-- inicia processamento
		w_GO <= '1';
		wait for c_CLK_PERIOD;
		w_GO <= '0';		
 		--------------------

    wait until w_READY = '1';

    -- TEST DONE
    assert false report "Test done." severity note;
    wait;

	end process p_TEST;         
  
end arch;
  


  