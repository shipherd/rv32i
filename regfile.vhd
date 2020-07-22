
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.numeric_std.ALL;
LIBRARY work;
USE work.common.ALL;
ENTITY regfile IS--start
    PORT (
        reset : IN std_logic;--reset 
        clk : IN std_logic;--clock 
        addra : IN reg_addr_type;--rs1 
        addrb : IN reg_addr_type;--rs2 
        rega : OUT word;--rs1's value 
        regb : OUT word;--rs2's value
        addrw : IN reg_addr_type;--write  address 
        dataw : IN word;--write  data
        we : IN std_logic);--write  enable 
END ENTITY regfile;--end

--
--  Note:  Because  this  core  is  FPGA-targeted,  the  idea  is  that  these  registers
--	will  get  implemented  as  dual-port  Distributed  RAM.	Because  there  is  no
--	such  thing  as  triple-port  memory  in  an  FPGA  (that  I  know  of),  and  we
--	need  3  ports  to  support  2  reads  and  1  write  per  cycle,  the  easiest  way
--	to  implement  that  is  to  have  two  identical  banks  of  registers  that  contain
--	the  same  data.	Each  uses  2  ports  and  everybody's  happy.
--
ARCHITECTURE rtl OF regfile IS--start
    TYPE regbank_t IS ARRAY (0 TO 31) OF word;--32  registers

    SIGNAL regbank0 : regbank_t := (OTHERS => (OTHERS => '0'));--bank one 
    SIGNAL regbank1 : regbank_t := (OTHERS => (OTHERS => '0'));--bank two
BEGIN --  architecture  Behavioral

    --  purpose:  create  registers
    --  type	:  sequential
    -- inputs : clk
    --  outputs:
    registers_proc : PROCESS (clk) IS--register  array 
    BEGIN -- process registers_proc
        IF reset = '1' THEN--if  reset
            regbank0(1) <= x"C0FEBABE";--test  data 
            regbank1(1) <= x"C0FEBABE";--test  data 
            regbank0(8) <= x"11111111";--test  data 
            regbank1(8) <= x"11111111";--test  data 
            regbank0(2) <= x"000000FF";--test  data 
            regbank1(2) <= x"000000FF";--test  data
        ELSIF rising_edge(clk) THEN--when  clock  edge
            IF (we = '1') AND (addrw /= "00000") THEN--if  write  enabled,  and  write  addr  !=0 
                regbank0(to_integer(unsigned(addrw))) <= dataw;--write  in  new  data 
                regbank1(to_integer(unsigned(addrw))) <= dataw;--write  in  new  data
            END IF;--end 
        END IF;--end
    END PROCESS registers_proc;--end

    -- asynchronous read
    rega <= regbank0(to_integer(unsigned(addra)));--output  for  rs1 
    regb <= regbank1(to_integer(unsigned(addrb)));--output  for  rs2

END ARCHITECTURE rtl;--end