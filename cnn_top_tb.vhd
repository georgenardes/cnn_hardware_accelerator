-- cnn_top_tb

-- CNN top file
-- integra todas as camadas da rede


library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use ieee.std_logic_textio.all; -- require for writing/reading std_logic etc
use ieee.numeric_std.all;


entity cnn_top_tb is
end cnn_top_tb;



architecture arch of cnn_top_tb is 
  
  constant c_CLK_PERIOD : time := 20 ns;
  
  
  component cnn_top is
    port 
    (
      i_CLK       : in STD_LOGIC;
      i_CLR       : in STD_LOGIC;
      i_GO        : in STD_LOGIC;
      i_LOAD      : in std_logic;
      i_SEL		    : in std_logic_vector(5 downto 0) := (others => '0');
      o_DATA      : out std_logic_vector(7 downto 0);      
      o_READY     : out std_logic;
      o_LOADED    : out std_logic
    );
  end component;
  
  
  signal w_CLK       : STD_LOGIC;
  signal w_CLR       : STD_LOGIC;
  signal w_GO        : STD_LOGIC;
  signal w_LOAD      : std_logic;
  signal w_SEL		   : std_logic_vector(5 downto 0) := (others => '0');
	signal w_DATA      : std_logic_vector(7 downto 0);        
  signal w_READY     : std_logic;
  signal w_LOADED    : std_logic;
  
  -- buffer for storing the text from input read-file
  file input_buf : text;  -- text is keyword
  
begin
  
  u_DUT : cnn_top 
          port map 
          (
            i_CLK    => w_CLK  ,
            i_CLR    => w_CLR  ,
            i_GO     => w_GO   ,            
            i_LOAD   => w_LOAD ,
            i_SEL	   => w_SEL	,
            o_DATA   => w_DATA ,
            o_READY  => w_READY,
            o_LOADED => w_LOADED           
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
    variable read_col_from_input_buf : line; -- read lines one by one from input_buf

    variable sel_out, addr, true_value : integer; -- to save col values
    variable val_SPACE : character;  -- for spaces between data in file
  
	begin

		w_GO <= '0';
    w_LOAD <= '0';
	  --------------------------
		w_CLR <= '1'; -- clear 
		wait for 2 * c_CLK_PERIOD;
		w_CLR <= '0'; -- clear
		wait for c_CLK_PERIOD; 
		---------------------------
    
    -- inicia carregamento
    w_LOAD <= '1';   
    wait for c_CLK_PERIOD;
    w_LOAD <= '0';  
    wait until w_LOADED = '1';

        
		-- inicia processamento
		w_GO <= '1';
		wait for c_CLK_PERIOD;
		w_GO <= '0';		
 		--------------------

    wait until w_READY = '1';
    
    
    -- if modelsim-project is created, then provide the relative path of 
    -- input-file (i.e. read_file_ex.txt) with respect to main project folder
    file_open(input_buf, "fc_out.txt",  read_mode); 
    -- else provide the complete path for the input file as show below 
    -- file_open(input_buf, "E:/VHDLCodes/input_output_files/read_file_ex.txt", read_mode); 

    
    while not endfile(input_buf) loop
      readline(input_buf, read_col_from_input_buf);
      read(read_col_from_input_buf, sel_out);
      read(read_col_from_input_buf, val_SPACE);           -- read in the space character
      -- read(read_col_from_input_buf, addr);
      -- read(read_col_from_input_buf, val_SPACE);           -- read in the space character
      read(read_col_from_input_buf, true_value);

      -- Pass the read values to signals
      -- w_ADDR <= std_logic_vector(to_unsigned(addr, w_ADDR'length));
      w_SEL	 <= std_logic_vector(to_unsigned(sel_out, w_SEL'length));
      
      wait for 4*c_CLK_PERIOD;  --  to load memory data
      
      -- verifica dado de saida
      assert w_DATA = std_logic_vector(to_signed(true_value, w_DATA'length))
          report "Valor de saida incorreto." severity error;
            
      wait for c_CLK_PERIOD;  --  to display results 
      
    end loop;

    file_close(input_buf);             
    

    -- TEST DONE
    assert false report "Test done." severity note;
    wait;

	end process p_TEST;         
  
end arch;
  


  