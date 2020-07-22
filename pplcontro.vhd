LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.numeric_std.ALL;
LIBRARY work;
USE work.common.ALL;

ENTITY pplcontrol IS--start
    PORT (
        inst_s1 : IN word;--stage  one  instruction 
        inst_s2 : IN word;--stage  two  instruction 
        stall_disen : OUT std_logic;--output  stall
        fwd_op1_sel : OUT std_logic_vector(1 DOWNTO 0);--forwarding  for  op1 
        fwd_op2_sel : OUT std_logic_vector(1 DOWNTO 0);--forwarding  for  op2 
        fwd_rs2_en : OUT std_logic);--forwarding  for  rs2's  value
END ENTITY pplcontrol;

ARCHITECTURE rtl OF pplcontrol IS--start

    SIGNAL opcode1 : opcode_type;--stage  1  relevant  inst  field 
    SIGNAL rs11 : rs1_type;--stage  1  relevant  inst  field
    SIGNAL rs21 : rs2_type;--stage  1  relevant  inst  field

    SIGNAL opcode2 : opcode_type;--stage  2  relevant  inst  field 
    SIGNAL rd2 : rd_type;--stage  2  relevant  inst  field
BEGIN--start
    opcode1 <= inst_s1(6 DOWNTO 0);--stage  1  opcode

    rs11 <= inst_s1(19 DOWNTO 15);--stage  1  rs1 
    rs21 <= inst_s1(24 DOWNTO 20);--stage  1  rs2

    opcode2 <= inst_s2(6 DOWNTO 0);--stage  2  opcode 
    rd2 <= inst_s2(11 DOWNTO 7);--stage  2  rd
    stall_gen : PROCESS (opcode2, opcode1)--mux  for  stall  signal 
    BEGIN--start
        IF (opcode2 = OP_JTYPE_JAL) OR (opcode2 = OP_ITYPE_JALR) OR (opcode2 = OP_BTYPE_COMMON) THEN
            --if branch/jmp/jalr
            stall_disen <= '0';--Stall  when  redirecting 
        ELSE--otherwise
            stall_disen <= '1';--NOOOOOOOOOOOOOOOOOOOO
        END IF;
    END PROCESS stall_gen;

    fwd_sel_gen : PROCESS (rd2, rs11, rs21, opcode2, opcode1)--mux  for  forwarding  signals 
    BEGIN--start
        IF (rd2 = rs11) AND (opcode2 = OP_ITYPE_LOAD_COMMON) THEN--Load  RAW  hazard  on  RS1 
            fwd_op1_sel <= "10";--forwarding  dmem  output
        ELSIF (rd2 = rs11) AND (opcode2 /= OP_ITYPE_LOAD_COMMON) AND (opcode1 /= OP_STYPE_COMMON) THEN--alu  arithmetic  RAW  hazard
            fwd_op1_sel <= "01";--forwarding  it 
        ELSE--otherwise
            fwd_op1_sel <= "00";--do  not 
        END IF;

        IF (rd2 = rs21) AND (opcode2 = OP_ITYPE_LOAD_COMMON) THEN--Load  RAW  hazard  on  RS2 
            fwd_op2_sel <= "10";--forwarding  dmem  output
        ELSIF (rd2 = rs21) AND (opcode2 /= OP_ITYPE_LOAD_COMMON) AND (opcode1 /= OP_STYPE_COMMON) THEN--alu  arithmetic  RAW  hazard
            fwd_op2_sel <= "01";--forwarding  it 
        ELSE--otherwise
            fwd_op2_sel <= "00";--do  not 
        END IF;

    END PROCESS fwd_sel_gen;

    fwd_rs2_gen : PROCESS (rd2, rs11, rs21, opcode2, opcode1)--STORE  forwarding  mux 
    BEGIN--start

        IF (opcode1 = OP_STYPE_COMMON) AND (rd2 = rs21) THEN--when stage 1 opcode is S type and stage 2 rd is equal to stage 1 rs2 
            fwd_rs2_en <= '1';--do  it
        ELSE--otherwise
            fwd_rs2_en <= '0';--don't  do  it 
        END IF;

    END PROCESS fwd_rs2_gen; 
END ARCHITECTURE rtl;