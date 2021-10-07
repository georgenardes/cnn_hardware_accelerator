-------------------
-- Somador de 32 bits testbench
-- 09/09/2021
-- George
-- R1


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY add32_tb is    
END add32_tb;

ARCHITECTURE arch32 OF add32_tb IS
    
  -- somador completo de 1 bit
  COMPONENT add32
      PORT (a         : IN  std_logic_vector(31 DOWNTO 0);
            b         : IN  std_logic_vector(31 DOWNTO 0);
            cin       : IN  STD_LOGIC;
            sum1      : OUT std_logic_vector(31 DOWNTO 0);
            cout      : OUT std_logic;
            overflow  : out std_logic;
            underflow : out std_logic);
  END COMPONENT;

  -- sinais de carry-inout
  SIGNAL c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, 
        c14, c15, c16, c17, c18, c19, c20, c21, c22, c23, c24, c25, 
        c26, c27, c28, c29, c30  : std_LOGIC;
        
  signal w_a         :  std_logic_vector(31 DOWNTO 0);
  signal w_b         :  std_logic_vector(31 DOWNTO 0);
  signal w_cin       :  STD_LOGIC;
  signal w_sum1      :  std_logic_vector(31 DOWNTO 0);
  signal w_cout      :  std_logic;
  signal w_overflow  :  std_logic;
  signal w_underflow :  std_logic;

BEGIN

  u_DUT : add32 port map (w_a, w_b, w_cin, w_sum1, w_cout,
                         w_overflow, w_underflow);
    
  process
  begin
    w_a         <= "10001000100010001000100010001000";
    w_b         <= "10001000100010001000100010001000";
    w_cin       <= '0';
    
    wait for 1 ns;
    
    assert (w_sum1 <= "10000000000000000000000000000000") report "resultado incorreto" severity error;
    assert (w_cout <= '1') report "cout incorreto" severity error;
    assert (w_overflow <= '0') report "w_overflow incorreto" severity error;
    assert (w_underflow <= '1') report "w_underflow incorreto" severity error;  

    wait for 1 ns;
    ---------------
    
    w_a         <= "01001000100010001000100010001000";
    w_b         <= "01001000100010001000100010001000";
    w_cin       <= '0';
    
    wait for 1 ns;
    
    assert (w_sum1 <= "01111111111111111111111111111111") report "resultado incorreto" severity error;
    assert (w_cout <= '0') report "cout incorreto" severity error;
    assert (w_overflow <= '1') report "w_overflow incorreto" severity error;
    assert (w_underflow <= '0') report "w_underflow incorreto" severity error;  

    wait for 1 ns;
		---------------
    
    w_a         <= "11001000100010001000100010001000";
    w_b         <= "11001000100010001000100010001000";
    w_cin       <= '0';
    
    wait for 1 ns;
    
    assert (w_sum1 <= "10010001000100010001000100010000") report "resultado incorreto" severity error;
    assert (w_cout <= '1') report "cout incorreto" severity error;
    assert (w_overflow <= '0') report "w_overflow incorreto" severity error;
    assert (w_underflow <= '0') report "w_underflow incorreto" severity error;  

    wait for 1 ns;
    ---------------
    
    w_a         <= "00001000100010001000100010001000";
    w_b         <= "00001000100010001000100010001000";
    w_cin       <= '0';
    
    wait for 1 ns;
    
    assert (w_sum1 <= "00010001000100010001000100010000") report "resultado incorreto" severity error;
    assert (w_cout <= '0') report "cout incorreto" severity error;
    assert (w_overflow <= '0') report "w_overflow incorreto" severity error;
    assert (w_underflow <= '0') report "w_underflow incorreto" severity error;  

    wait for 1 ns;
    ---------------

		-- TEST DONE
    assert false report "Test done." severity note;
    wait;

  end process;
END arch32;