
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.numeric_std.ALL;
LIBRARY work;
USE work.common.ALL;
ENTITY u_p2 IS--testbench 
END ENTITY u_p2;--testbench

ARCHITECTURE test OF u_p2 IS--testbench  for  2  stage  pipelined  rv32i

    COMPONENT rv32ip2 IS--testbench  for  2  stage  pipelined  rv32i 
        PORT (
            clk : IN std_logic;--clock
            rst : IN std_logic;--rest
            outputs : OUT word);--data  output  regbank0(0)
    END COMPONENT rv32ip2;--testbench  for  2  stage  pipelined  rv32i

    CONSTANT period : TIME := 10 ns;--period  is  10  ns 
    SIGNAL clk : std_logic := '0';--init  clock  0
    SIGNAL rst : std_logic := '1';--init  reset  1 
    SIGNAL val : word := x"00000000";--tmp  variable

BEGIN--testbench  for  2  stage  pipelined  rv32i

    cpu : rv32ip2 PORT MAP(--testbench  for  2  stage  pipelined  rv32i 
        clk => clk, --link  clock
        rst => rst, --link  reset 
        outputs => val--link  data  output
    );--testbench  for  2  stage  pipelined  rv32i

    proc_clock : PROCESS--testbench  for  2  stage  pipelined  rv32i 
    BEGIN--testbench  for  2  stage  pipelined  rv32i
        clk <= '0';--0  clock
        WAIT FOR period/2;--after  one  half  period 
        clk <= '1';--1  clock
        WAIT FOR period/2;--repeat
    END PROCESS;--testbench  for  2  stage  pipelined  rv32i

    proc_stimuli : PROCESS--testbench  for  2  stage  pipelined  rv32i
    BEGIN--testbench  for  2  stage  pipelined  rv32i 
        rst <= '1';--1  reset
        WAIT FOR period * 2;--run  for  2  periods 
        rst <= '0';--0  reset
        WHILE unsigned(val) /= x"00006041" LOOP--run  unitl  we  have  the  result 
            WAIT FOR period;--keep  running
        END LOOP;--end  loop
        ASSERT false REPORT "success  -  end  of  simulation" SEVERITY failure;-- end  of  simulation
    END PROCESS;--testbench  for  2  stage  pipelined  rv32i

END ARCHITECTURE test;--testbench  for  2  stage  pipelined  rv32i