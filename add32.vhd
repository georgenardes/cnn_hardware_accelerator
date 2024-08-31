-------------------
-- Somador de 32 bits
-- 09/09/2021
-- George
-- R1

-- Descrição
-- Este bloco realiza a soma entre dois valores de 32 bits
-- com sinal de Carry In. O resultado também é em 32 bits
-- com sinal de Carry Out.

library ieee;
use ieee.std_logic_1164.all;

entity add32 is
  port (
    a         : in std_logic_vector(31 downto 0);
    b         : in std_logic_vector(31 downto 0);
    cin       : in std_logic;
    sum1      : out std_logic_vector(31 downto 0);
    cout      : out std_logic;
    overflow  : out std_logic;
    underflow : out std_logic);
end add32;

architecture arch32 of add32 is

  -- somador completo de 1 bit
  component add1
    port (
      a, b, cin : in std_logic;
      sum, cout : out std_logic);
  end component;

  -- sinais de carry-inout
  signal c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13,
  c14, c15, c16, c17, c18, c19, c20, c21, c22, c23, c24, c25,
  c26, c27, c28, c29, c30 : std_logic;

  -- sinal para o bit de sinal
  signal w_SIGNAL_BIT : std_logic;

  -- resultado da soma
  signal w_SUM_OUT : std_logic_vector(31 downto 0);

  signal w_OVERFLOW, w_UNDERFLOW : std_logic;

begin

  D_adder0  : add1 port map(a(0), b(0), cin, w_SUM_OUT(0), c0);
  D_adder1  : add1 port map(a(1), b(1), c0, w_SUM_OUT(1), c1);
  D_adder2  : add1 port map(a(2), b(2), c1, w_SUM_OUT(2), c2);
  D_adder3  : add1 port map(a(3), b(3), c2, w_SUM_OUT(3), c3);
  D_adder4  : add1 port map(a(4), b(4), c3, w_SUM_OUT(4), c4);
  D_adder5  : add1 port map(a(5), b(5), c4, w_SUM_OUT(5), c5);
  D_adder6  : add1 port map(a(6), b(6), c5, w_SUM_OUT(6), c6);
  D_adder7  : add1 port map(a(7), b(7), c6, w_SUM_OUT(7), c7);
  D_adder8  : add1 port map(a(8), b(8), c7, w_SUM_OUT(8), c8);
  D_adder9  : add1 port map(a(9), b(9), c8, w_SUM_OUT(9), c9);
  D_adder10 : add1 port map(a(10), b(10), c9, w_SUM_OUT(10), c10);
  D_adder11 : add1 port map(a(11), b(11), c10, w_SUM_OUT(11), c11);
  D_adder12 : add1 port map(a(12), b(12), c11, w_SUM_OUT(12), c12);
  D_adder13 : add1 port map(a(13), b(13), c12, w_SUM_OUT(13), c13);
  D_adder14 : add1 port map(a(14), b(14), c13, w_SUM_OUT(14), c14);
  D_adder15 : add1 port map(a(15), b(15), c14, w_SUM_OUT(15), c15);
  D_adder16 : add1 port map(a(16), b(16), c15, w_SUM_OUT(16), c16);
  D_adder17 : add1 port map(a(17), b(17), c16, w_SUM_OUT(17), c17);
  D_adder18 : add1 port map(a(18), b(18), c17, w_SUM_OUT(18), c18);
  D_adder19 : add1 port map(a(19), b(19), c18, w_SUM_OUT(19), c19);
  D_adder20 : add1 port map(a(20), b(20), c19, w_SUM_OUT(20), c20);
  D_adder21 : add1 port map(a(21), b(21), c20, w_SUM_OUT(21), c21);
  D_adder22 : add1 port map(a(22), b(22), c21, w_SUM_OUT(22), c22);
  D_adder23 : add1 port map(a(23), b(23), c22, w_SUM_OUT(23), c23);
  D_adder24 : add1 port map(a(24), b(24), c23, w_SUM_OUT(24), c24);
  D_adder25 : add1 port map(a(25), b(25), c24, w_SUM_OUT(25), c25);
  D_adder26 : add1 port map(a(26), b(26), c25, w_SUM_OUT(26), c26);
  D_adder27 : add1 port map(a(27), b(27), c26, w_SUM_OUT(27), c27);
  D_adder28 : add1 port map(a(28), b(28), c27, w_SUM_OUT(28), c28);
  D_adder29 : add1 port map(a(29), b(29), c28, w_SUM_OUT(29), c29);
  D_adder30 : add1 port map(a(30), b(30), c29, w_SUM_OUT(30), c30);
  -- bit de sinal
  D_adder31 : add1 port map(a(31), b(31), c30, w_SIGNAL_BIT, cout);
  w_SUM_OUT(31) <= w_SIGNAL_BIT;
  -- https://www.doc.ic.ac.uk/~eedwards/compsys/arithmetic/index.html
  -- 1) Overflow never occurs when adding operands with different signs. 

  -- Adding two positive numbers must give a positive result 
  -- a sem sinal e b sem sinal e resultado com sinal
  w_OVERFLOW <= not a(31) and not b(31) and w_SIGNAL_BIT;

  -- Adding two negative numbers must give a negative result 
  -- a com sinal e b com sinal e resultado sem sinal
  w_UNDERFLOW <= a(31) and b(31) and not w_SIGNAL_BIT;

  -- clip 
  sum1 <= "10000000000000000000000000000000" when (w_UNDERFLOW = '1') else
    "01111111111111111111111111111111" when (w_OVERFLOW = '1') else
    w_SUM_OUT;

  overflow  <= w_OVERFLOW;
  underflow <= w_UNDERFLOW;
end arch32;
