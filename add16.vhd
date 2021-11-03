--- bit_adder.vhd
-- description of 1 bit adder
LIBRARY IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity BIT_ADDER1 is
        port( a, b, cin         : in  STD_LOGIC;
              sum, cout         : out STD_LOGIC );
end BIT_ADDER1;

architecture BHV of BIT_ADDER1 is
begin

        sum <=  (not a and not b and cin) or
                        (not a and b and not cin) or
                        (a and not b and not cin) or
                        (a and b and cin);

        cout <= (not a and b and cin) or
                        (a and not b and cin) or
                        (a and b and not cin) or
                        (a and b and cin);
end BHV;

------------------------------- add2 ---------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;


ENTITY add2 IS
    PORT( a, b  : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
          cin   : IN  STD_LOGIC;
          ans   : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
          cout  : OUT STD_LOGIC
    );
END add2;

ARCHITECTURE STRUCTURE OF add2 IS

    COMPONENT BIT_ADDER1
        PORT( a, b, cin  : IN  STD_LOGIC;
                sum, cout  : OUT STD_LOGIC
        );
    END COMPONENT;

    SIGNAL c1 : STD_LOGIC;

BEGIN

    b_adder0: BIT_ADDER1 PORT MAP (a(0), b(0), cin, ans(0), c1);
    b_adder1: BIT_ADDER1 PORT MAP (a(1), b(1), c1, ans(1), cout);

END STRUCTURE;



------------------------------- add16 ---------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY add16 is
    PORT (  a, b : IN  std_logic_vector(31 DOWNTO 0);
            cin  : IN  STD_LOGIC;
            sum1 : OUT std_logic_vector(31 DOWNTO 0);
            cout : OUT std_logic);
END add16;

ARCHITECTURE arch16 OF add16 IS

    COMPONENT add2
        PORT(  a, b      : IN    STD_LOGIC_VECTOR(1 DOWNTO 0);
               cin       : IN    STD_LOGIC;
               ans       : OUT   STD_LOGIC_VECTOR(1 DOWNTO 0);
               cout      : OUT   STD_LOGIC);
    END COMPONENT;

    SIGNAL c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14, c15  : std_LOGIC;

BEGIN

    D_adder0 : add2 PORT MAP ( a(1  DOWNTO 0)  , b(1  DOWNTO 0) , cin , sum1(1  DOWNTO 0)  , c1  );
    D_adder1 : add2 PORT MAP ( a(3  DOWNTO 2)  , b(3  DOWNTO 2) , c1  , sum1(3  DOWNTO 2)  , c2  );
    D_adder2 : add2 PORT MAP ( a(5  DOWNTO 4)  , b(5  DOWNTO 4) , c2  , sum1(5  DOWNTO 4)  , c3  );
    D_adder3 : add2 PORT MAP ( a(7  DOWNTO 6)  , b(7  DOWNTO 6) , c3  , sum1(7  DOWNTO 6)  , c4  );
    D_adder4 : add2 PORT MAP ( a(9  DOWNTO 8)  , b(9  DOWNTO 8) , c4  , sum1(9  DOWNTO 8)  , c5  );
    D_adder5 : add2 PORT MAP ( a(11 DOWNTO 10) , b(11 DOWNTO 10), c5  , sum1(11 DOWNTO 10) , c6  );
    D_adder6 : add2 PORT MAP ( a(13 DOWNTO 12) , b(13 DOWNTO 12), c6  , sum1(13 DOWNTO 12) , c7  );
    D_adder7 : add2 PORT MAP ( a(15 DOWNTO 14) , b(15 DOWNTO 14), c7  , sum1(15 DOWNTO 14) , c8  );
    D_adder8 : add2 PORT MAP ( a(17 DOWNTO 16) , b(17 DOWNTO 16), c8  , sum1(17 DOWNTO 16) , c9  );
    D_adder9 : add2 PORT MAP ( a(19 DOWNTO 18) , b(19 DOWNTO 18), c9  , sum1(19 DOWNTO 18) , c10 );
    D_adder10: add2 PORT MAP ( a(21 DOWNTO 20) , b(21 DOWNTO 20), c10 , sum1(21 DOWNTO 20) , c11 );
    D_adder11: add2 PORT MAP ( a(23 DOWNTO 22) , b(23 DOWNTO 22), c11 , sum1(23 DOWNTO 22) , c12 );
    D_adder12: add2 PORT MAP ( a(25 DOWNTO 24) , b(25 DOWNTO 24), c12 , sum1(25 DOWNTO 24) , c13 );
    D_adder13: add2 PORT MAP ( a(27 DOWNTO 26) , b(27 DOWNTO 26), c13 , sum1(27 DOWNTO 26) , c14 );
    D_adder14: add2 PORT MAP ( a(29 DOWNTO 28) , b(29 DOWNTO 28), c14 , sum1(29 DOWNTO 28) , c15 );
    D_adder15: add2 PORT MAP ( a(31 DOWNTO 30) , b(31 DOWNTO 30), c15 , sum1(31 DOWNTO 30) , cout);

END arch16;