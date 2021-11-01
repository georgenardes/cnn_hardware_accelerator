-- controle cnn

library ieee;
use ieee.std_logic_1164.all;
use ieee.STD_LOGIC_UNSIGNED.all;
USE ieee.numeric_std.all;
library work;
use work.types_pkg.all;

entity cnn_crt is
  port (
    i_CLK           : in  std_logic;
    i_CLR           : in  std_logic;
    i_LOAD          : in  std_logic;
    i_GO            : in  std_logic; -- inicia maq  
    o_LOAD_ENA      : out std_logic;  
    o_LOADED        : out std_logic;
    o_READY         : out std_logic -- fim maq
  );
end cnn_crt;

architecture arch of cnn_crt is
  type t_STATE is (
    s_IDLE, -- IDLE        
    s_LOAD,   -- carrega pesos 
    s_GO,     -- inicia processamento    
    s_LOADED, -- sinaliza pesos carregados
    s_END     -- sinaliza fim processamento
  );
  signal r_STATE : t_STATE; -- state register
  signal w_NEXT : t_STATE; -- next state    
  
  
begin

  p_STATE : process (i_CLK, i_CLR)
  begin
    if (i_CLR = '1') then
      r_STATE <= s_IDLE;      --initial state
    elsif (rising_edge(i_CLK)) then
      r_STATE <= w_NEXT;  --next state
    end if;
  end process;
    

  p_NEXT : process (r_STATE, i_GO, i_LOAD)
  begin
    case (r_STATE) is
      when s_IDLE => -- aguarda sinal go
        if (i_LOAD = '1') then
          w_NEXT <= s_LOAD;
        elsif (i_GO = '1') then
          w_NEXT <= s_GO;
        else
          w_NEXT <= s_IDLE;
        end if;
      
      when s_LOAD =>  
        w_NEXT <= s_LOADED;   
      
      when s_LOADED =>  
        w_NEXT <= s_IDLE;  
        
      when s_GO =>  
        w_NEXT <= s_END;  
                
      when s_END =>  -- fim
        w_NEXT <= s_IDLE;      

      when others =>
        w_NEXT <= s_IDLE;
        
    end case;
  end process;
  
  
  
  -- sinaliza fim maq estado
  o_READY <= '1' when (r_STATE = s_END) else '0';
  
end arch;
