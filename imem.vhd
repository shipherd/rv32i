LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.numeric_std.ALL;
LIBRARY work;
USE work.common.ALL;

ENTITY imem IS--START
    PORT (
        addr : IN mem_addr_type;--input  address 
        dout : OUT word);--output  instruction
END imem;--END

ARCHITECTURE behavioral OF imem IS--START
    TYPE rom_arr IS ARRAY(0 TO 255) OF byte;--maximum  64  insts,  256  Bytes  in  total

    SIGNAL mem : rom_arr := --Little  Endian 
    (----	lfsr3:
    x"37", x"07", x"00", x"00", --0000  37070000	lui  a4,%hi(lfsr.2565)
    x"03", x"55", x"07", x"00", --0004  03550700	lhu  a0,%lo(lfsr.2565)(a4)
    x"93", x"57", x"75", x"00", --0008  93577500	srli	a5,a0,7
    x"B3", x"47", x"F5", x"00", --000c  B347F500	xor  a5,a0,a5
    x"13", x"95", x"97", x"00", --0010  13959700	slli	a0,a5,9
    x"33", x"45", x"F5", x"00", --0014  3345F500	xor  a0,a0,a5
    --x"13",x"05",x"10",x"00",--Li  a0,1
    x"13", x"15", x"05", x"01", --0018  13150501	slli	a0,a0,16
    x"13", x"55", x"05", x"01", --001c  13550501	srli	a0,a0,16
    x"93", x"57", x"D5", x"00", --0020  9357D500	srli	a5,a0,13
    x"33", x"45", x"F5", x"00", --0024  3345F500	xor  a0,a0,a5
    x"23", x"10", x"A7", x"00", --0028  2310A700	sh	a0,%lo(lfsr.2565)(a4) 
    x"67", x"80", x"00", x"00", --002c  67800000	ret
    --	main:
    x"13", x"01", x"01", x"FF", --  0030  130101FF	addi	sp,sp,-16
    x"23", x"26", x"11", x"00", --  0034  23261100	sw	ra,12(sp)
    x"23", x"24", x"81", x"00", --  0038  23248100	sw	s0,8(sp)
    x"23", x"22", x"91", x"00", --  003c  23229100	sw	s1,4(sp)
    --x"37",x"04",x"00",x"00",--  0040  37040000	lui  s0,0
    --x"13",x"04",x"04",x"00",--  0044  13040400	addi	s0,s0,0
    x"13", x"00", x"00", x"00", --  xxxx  xxxxxxxx	NOP;  for  balancing  the  imem 
    x"13", x"04", x"40", x"00", --  xxxx  xxxxxxxx	addi	s0,zero,4;  Outputs  address  starts  at  0x4 
    x"93", x"04", x"E4", x"01", --  0048  9304E401	addi	s1,s0,30
    --	.L3:
    --x"97",x"00",x"00",x"00",--  004c  97000000	call	lfsr3;auipc  x1,0 
    x"13", x"00", x"00", x"00", --  xxxx  xxxxxxxx	NOP;  for  balancing  the  imem 
    x"E7", x"00", x"00", x"00", --	E7000000	jalr  ra,  zero,0;  Call  lfsr3 
    x"23", x"00", x"A4", x"00", --  0054  2300A400	sb	a0,0(s0)
    x"13", x"04", x"14", x"00", --  0058  13041400	addi	s0,s0,1
    x"E3", x"18", x"94", x"FE", --  005c  E31894FE	bne  s0,s1,.L3
    x"13", x"05", x"00", x"00", --  0060  13050000	li	a0,0
    x"83", x"20", x"C1", x"00", --  0064  8320C100	lw	ra,12(sp)
    x"03", x"24", x"81", x"00", --  0068  03248100	lw	s0,8(sp)
    x"83", x"24", x"41", x"00", --  006c  83244100	lw	s1,4(sp)
    x"13", x"01", x"01", x"01", --  0070  13010101	addi	sp,sp,16
    x"67", x"80", x"00", x"00", --  0074  67800000	jr	ra
    OTHERS => x"00"--zero  memory
    );--END

BEGIN--START
    --little  endian
    dout(7 DOWNTO 0) <= mem(conv_integer(addr));--output  first  byte  of  instruction 
    dout(15 DOWNTO 8) <= mem(conv_integer(addr) + 1);--output  second  byte  of  instruction 
    dout(23 DOWNTO 16) <= mem(conv_integer(addr) + 2);--output  third  byte  of  instruction 
    dout(31 DOWNTO 24) <= mem(conv_integer(addr) + 3);--output  fourth  byte  of  instruction
END behavioral;--end