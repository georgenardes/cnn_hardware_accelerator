-------------------
-- Registrador Generico
-- 09/09/2021
-- George
-- R1

library ieee;
use ieee.std_logic_1164.all;

entity registrador is
  generic (DATA_WIDTH : integer := 8);
  port (
    i_CLK : in std_logic;
    i_CLR : in std_logic;
    i_ENA : in std_logic;
    i_A   : in std_logic_vector(DATA_WIDTH - 1 downto 0);
    o_Q   : out std_logic_vector(DATA_WIDTH - 1 downto 0)
  );
end registrador;

architecture arch of registrador is
  -- registrador
  signal r_A : std_logic_vector(DATA_WIDTH - 1 downto 0);

begin

  process (i_CLK, i_CLR, i_ENA, i_A)
  begin
    -- reset
    if (i_CLR = '1') then
      r_A <= (others => '0');
      -- subida clock
    elsif (rising_edge(i_CLK)) then
      -- enable ativo
      if (i_ENA = '1') then
        r_A <= i_A;
      end if;
    end if;
  end process;

  o_Q <= r_A;
end arch;
