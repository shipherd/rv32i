LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.numeric_std.ALL;
LIBRARY work;
USE work.common.ALL;

ENTITY reg32 IS--start
    PORT (
        clk : IN std_logic;--clock 
        rst : IN std_logic;--reset 
        din : IN word;--data in
        we : IN std_logic;--write  enable 
        dout : OUT word);--data  out
END ENTITY reg32;--end

ARCHITECTURE rtl OF reg32 IS--start
    SIGNAL data : word := x"00000000";--local  variable 
BEGIN--start
    reg_proc : PROCESS (clk, rst, we) IS--32  bits  general  register 
    BEGIN--start
        IF rst = '1' THEN--if  reset 
            data <= x"00000000";--output  zeros
        ELSIF rising_edge(clk) THEN--clock  edge 
            IF we = '1' THEN--if  write  enabled
                data <= din; --write  in  new  data 
            ELSE--otherwise
                data <= data;--keep  data 
            END IF;--end
        END IF;--end
    END PROCESS reg_proc;--end 
    dout <= data;--output  data
END ARCHITECTURE rtl;--end