LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.numeric_std.ALL;
LIBRARY work;
USE work.common.ALL;

ENTITY pc IS--START
    PORT (
        clk : IN std_logic;--clock 
        rst : IN std_logic;--reset
        ra : OUT mem_addr_type;--read  address 
        wa : IN mem_addr_type;--write  address 
        we : IN std_logic);--write  enable
END pc;--END

ARCHITECTURE rtl OF pc IS --START
    SIGNAL pc_count : mem_addr_type;--stored  counter 
BEGIN--START
    pc_register : PROCESS (clk, rst, we) IS--the  register 
    BEGIN--START
        IF rst = '1' THEN--if  reset 
            pc_count <= x"00000030";--output  zeros
        ELSIF rising_edge(clk) THEN--clock  edge 
            IF we = '1' THEN--of  write  enabled
                pc_count <= wa;--write  new  data  in 
            ELSE--otherwise
                pc_count <= pc_count;--stay  the  same 
            END IF;--end
        END IF;--end
    END PROCESS pc_register;--end 
    ra <= pc_count;--output  the  stored  counter
END ARCHITECTURE rtl;--END