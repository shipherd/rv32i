LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.numeric_std.ALL;
LIBRARY work;
USE work.common.ALL;

ENTITY dmem IS--START 
    PORT (
        reset : IN std_logic;--reset 
        clk : IN std_logic;--clock 
        raddr : IN mem_addr_type;--32 bits address
        dout : OUT word;--OUTPUT  a  WORD
        dsize : IN funct3_type;--Data  size,  if  we  =  '0'  then  read  size,  else  write  size 
        waddr : IN mem_addr_type;--32  bits  address
        din : IN word;--INPUT  a  WORD
        we : IN std_logic;--write  enable 
        debug_output : OUT word--debug  output,  regbank0(0)
    );
END ENTITY dmem;--END

--
--  Note:  Because  this  core  is  FPGA-targeted,  the  idea  is  that  these  registers
--	will  get  implemented  as  dual-port  Distributed  RAM.	Because  there  is  no
--	such  thing  as  triple-port  memory  in  an  FPGA  (that  I  know  of),  and  we
--	need  3  ports  to  support  2  reads  and  1  write  per  cycle,  the  easiest  way
--	to  implement  that  is  to  have  two  identical  banks  of  registers  that  contain
--	the  same  data.	Each  uses  2  ports  and  everybody's  happy.
--
ARCHITECTURE rtl OF dmem IS--START
    TYPE regbank_t IS ARRAY (0 TO 255) OF byte;--Basic  cell  is  byte,  256  bytes  in  total

    SIGNAL regbank0 : regbank_t := (--init mem array 
    x"E1", x"AC", x"00", x"00", --0000  E1AC
    OTHERS => x"00");--zero  memory 
BEGIN

    registers_proc : PROCESS (clk, reset, dsize, we) IS--mem  proc 
        VARIABLE tmp_byte : byte := x"00";--local  variable
    BEGIN -- process registers_proc
        IF reset = '1' THEN--reset  presents 
            dout <= x"00000000";--output  all  zeros
        ELSIF rising_edge(clk) THEN--when  clock  edge
            IF (we = '1') AND (unsigned(waddr) <= 255) THEN--if  the  read  address  is  not  too  large,  and  write  enable  is  one, 
                CASE dsize IS--for  different  sizes
                    WHEN FUNCT3_SB => regbank0(to_integer(unsigned(waddr))) <= din(7 DOWNTO 0);--byte,  writes  one  byte  only
                    WHEN FUNCT3_SH => --Little  Endian,  half  word,  2  bytes  written 
                        regbank0(to_integer(unsigned(waddr))) <= din(7 DOWNTO 0);--frist  byte 
                        regbank0(to_integer(unsigned(waddr)) + 1) <= din(15 DOWNTO 8);--second byte
                    WHEN FUNCT3_SW => --Little  Endian,  4  bytes  word 
                        regbank0(to_integer(unsigned(waddr))) <= din(7 DOWNTO 0);--first 
                        regbank0(to_integer(unsigned(waddr)) + 1) <= din(15 DOWNTO 8);--second 
                        regbank0(to_integer(unsigned(waddr)) + 2) <= din(23 DOWNTO 16);--third 
                        regbank0(to_integer(unsigned(waddr)) + 3) <= din(31 DOWNTO 24);--fourth 
                    WHEN OTHERS => NULL;--others=>N/A
                END CASE;--end 
            END IF;--end

        ELSIF (we = '0') AND (unsigned(raddr) <= 255) AND ((unsigned(raddr) + 1) <= 255) THEN-- when reading
            CASE dsize IS--different  sizes 
                WHEN FUNCT3_LB => --byte  size,
                    tmp_byte := regbank0(to_integer(unsigned(raddr)));-- temp  variable  =  one  byte  data
                    dout(7 DOWNTO 0) <= tmp_byte;--output  it
                    dout(31 DOWNTO 8) <= (OTHERS => tmp_byte(7));--Sign  Extended  Output 
                WHEN FUNCT3_LH => --Little  Endian,  half  word
                    dout(7 DOWNTO 0) <= regbank0(to_integer(unsigned(raddr)));--first  byte 
                    tmp_byte := regbank0(to_integer(unsigned(raddr)) + 1);--second  byte 
                    dout(15 DOWNTO 8) <= tmp_byte;--output  it
                    dout(31 DOWNTO 16) <= (OTHERS => tmp_byte(7));--Sign  Extended  Output 
                WHEN FUNCT3_LW => --Little  Endian,  4  bytes  word
                    dout(7 DOWNTO 0) <= regbank0(to_integer(unsigned(raddr)));--first 
                    dout(15 DOWNTO 8) <= regbank0(to_integer(unsigned(raddr)) + 1);--second 
                    dout(23 DOWNTO 16) <= regbank0(to_integer(unsigned(raddr)) + 2);--third 
                    dout(31 DOWNTO 24) <= regbank0(to_integer(unsigned(raddr)) + 3);--fourth 
                WHEN FUNCT3_LBU => --unsigned  byte
                    dout(7 DOWNTO 0) <= regbank0(to_integer(unsigned(raddr)));--actual  data 
                    dout(31 DOWNTO 8) <= (OTHERS => '0');--zero  extended
                WHEN FUNCT3_LHU => --half  word
                    dout(7 DOWNTO 0) <= regbank0(to_integer(unsigned(raddr)));--frist  byte 
                    dout(15 DOWNTO 8) <= regbank0(to_integer(unsigned(raddr)) + 1);--second byte 
                    dout(31 DOWNTO 16) <= (OTHERS => '0');--zero  extended
                WHEN OTHERS => dout <= x"C0FEBABE";--others=>magic  number 
            END CASE;--end
        END IF;--end
    END PROCESS registers_proc;--end

    -- asynchronous read
    --dout  <=  regbank0(to_integer(unsigned(raddr)));
    debug_output(7 DOWNTO 0) <= regbank0(0);--debug  output  first  byte 
    debug_output(15 DOWNTO 8) <= regbank0(1);--debug  output  second  byte 
    debug_output(31 DOWNTO 16) <= (OTHERS => '0');--zero  extended
END ARCHITECTURE rtl;--end