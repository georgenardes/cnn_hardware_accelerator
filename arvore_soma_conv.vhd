-------------------
-- Arvore de soma para convolucao
-- 09/09/2021
-- George
-- R1

-- Descrição
-- Este componente realizará a soma
-- entre 9 valores de 16 bits com sinal,
-- que resultará em um valor de 32 bits com sinal.
-------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity arvore_soma_conv is
  generic (i_DATA_WIDTH : INTEGER := 16;           
           o_DATA_WIDTH : INTEGER := 32);

  port (
    i_DATA1  : in  STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);
    i_DATA2  : in  STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);
    i_DATA3  : in  STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);
    i_DATA4  : in  STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);
    i_DATA5  : in  STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);    
    i_DATA6  : in  STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);
    i_DATA7  : in  STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);
    i_DATA8  : in  STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);
    i_DATA9  : in  STD_LOGIC_VECTOR (i_DATA_WIDTH - 1 downto 0);
    o_DATA   : out STD_LOGIC_VECTOR (o_DATA_WIDTH - 1 downto 0)
  );

end arvore_soma_conv;

architecture arch of arvore_soma_conv is
  -- saida de somadores
  signal w_SUM1_OUT, w_SUM2_OUT, w_SUM3_OUT, w_SUM4_OUT, 
         w_SUM5_OUT, w_SUM6_OUT, 
         w_SUM7_OUT : STD_LOGIC_VECTOR(o_DATA_WIDTH -1 downto 0);
  
  -- carry out de somadores
  signal w_SUM1_COUT, w_SUM2_COUT, w_SUM3_COUT, 
         w_SUM4_COUT, w_SUM5_COUT, w_SUM6_COUT,
         w_SUM7_COUT,  w_SUM8_COUT : STD_LOGIC;
  
  
  -- Sinais para adaptação das entradas de 16 bits
  -- para 32 bits.
  -- Motivo: para teste como o modelsim, é necesário criar 
  -- sinais de 32 bits e conecta-los às entradas dos
  -- somadores em vez de selecionar uma faixa de valores,
  -- na instanciação dos componentes.  
  type t_MAT is array (8 downto 0) of STD_LOGIC_VECTOR(o_DATA_WIDTH - 1 downto 0);
	signal w_ENTRADAS : t_MAT := (others =>  ( others => '0')); 
  

  component add32 is
    port (
      a : in  STD_LOGIC_VECTOR(o_DATA_WIDTH -1 downto 0); 
      b : in  STD_LOGIC_VECTOR(o_DATA_WIDTH -1 downto 0);
      cin  : in  STD_LOGIC;
      sum1 : out STD_LOGIC_VECTOR(o_DATA_WIDTH -1 downto 0);
      cout : out STD_LOGIC);
  end component;

begin
  
  -- conversão entrada 16 bits para 32 bits
	w_ENTRADAS(0)(15 downto 0) <= i_DATA1;
  w_ENTRADAS(1)(15 downto 0) <= i_DATA2;
  w_ENTRADAS(2)(15 downto 0) <= i_DATA3;
  w_ENTRADAS(3)(15 downto 0) <= i_DATA4;
  w_ENTRADAS(4)(15 downto 0) <= i_DATA5;
  w_ENTRADAS(5)(15 downto 0) <= i_DATA6;
  w_ENTRADAS(6)(15 downto 0) <= i_DATA7;
  w_ENTRADAS(7)(15 downto 0) <= i_DATA8;
  w_ENTRADAS(8)(15 downto 0) <= i_DATA9;  
  

  -- primeira coluna de somadores
  u_ADD1 : add32 port map (
                  a        =>  w_ENTRADAS(0), 
                  b        =>  w_ENTRADAS(1), 
                  cin      =>  '0',
                  sum1     =>  w_SUM1_OUT,
                  cout     =>  w_SUM1_COUT
                  );
  u_ADD2 : add32 port map (
                  a        =>  w_ENTRADAS(2), 
                  b        =>  w_ENTRADAS(3), 
                  cin      =>  '0',
                  sum1     =>  w_SUM2_OUT,
                  cout     =>  w_SUM2_COUT
                  );                
  u_ADD3 : add32 port map (
                  a        =>  w_ENTRADAS(4), 
                  b        =>  w_ENTRADAS(5), 
                  cin      =>  '0',
                  sum1     =>  w_SUM3_OUT,
                  cout     =>  w_SUM3_COUT
                  );
  u_ADD4 : add32 port map (
                  a        =>  w_ENTRADAS(6),
                  b        =>  w_ENTRADAS(7),
                  cin      =>  '0',
                  sum1     =>  w_SUM4_OUT,
                  cout     =>  w_SUM4_COUT
                  );
                  
  -- segunda coluna de somadores
  u_ADD5 : add32 port map (
                  a        =>  w_SUM1_OUT,
                  b        =>  w_SUM2_OUT,
                  cin      =>  '0',
                  sum1     =>  w_SUM5_OUT,
                  cout     =>  w_SUM5_COUT
                  );
  u_ADD6 : add32 port map (
                  a        =>  w_SUM3_OUT,
                  b        =>  w_SUM4_OUT,
                  cin      =>  '0',
                  sum1     =>  w_SUM6_OUT,
                  cout     =>  w_SUM6_COUT
                  );  
                  
  -- terceira coluna de somadores
  u_ADD7 : add32 port map (
                  a        =>  w_SUM5_OUT,
                  b        =>  w_SUM6_OUT,
                  cin      =>  '0',
                  sum1     =>  w_SUM7_OUT,
                  cout     =>  w_SUM7_COUT
                  );  
                  
                
  -- quarta coluna de somadores
  u_ADD8 : add32 port map (
                  a        =>  w_SUM7_OUT,
                  b        =>  w_ENTRADAS(8),
                  cin      =>  '0',
                  sum1     =>  o_DATA,
                  cout     =>  w_SUM8_COUT
                  );

end arch;
