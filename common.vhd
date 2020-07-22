LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.numeric_std.ALL;

PACKAGE common IS

    SUBTYPE word IS std_logic_vector(31 DOWNTO 0);--Define  a  machine  word 
    SUBTYPE half IS std_logic_vector(15 DOWNTO 0);--Define  a  machine  half-word 
    SUBTYPE byte IS std_logic_vector(7 DOWNTO 0);--Define  a  machine  byte

    SUBTYPE reg_addr_type IS std_logic_vector(4 DOWNTO 0);--32  registers  in  total 
    SUBTYPE mem_addr_type IS std_logic_vector(31 DOWNTO 0);--32  bits  memory  address

    --instruction  fields
    SUBTYPE opcode_type IS std_logic_vector(6 DOWNTO 0);--opcode  has  7  bits 
    SUBTYPE funct3_type IS std_logic_vector(2 DOWNTO 0);--funct3  has  3  bits 
    SUBTYPE rd_type IS std_logic_vector(4 DOWNTO 0);--rd  has  5  bits
    SUBTYPE rs1_type IS std_logic_vector(4 DOWNTO 0);--rs1  has  5  bits 
    SUBTYPE rs2_type IS std_logic_vector(4 DOWNTO 0);--rs2  has  5  bits 
    SUBTYPE funct7_type IS std_logic_vector(6 DOWNTO 0);--funct7  has  7  bits

    --Decoder control signals
    SUBTYPE Op1Sel IS std_logic_vector(1 DOWNTO 0); --Select  for  OP1 
    SUBTYPE Op2Sel IS std_logic_vector(2 DOWNTO 0);--Select  for  OP2
    SUBTYPE FuncSel IS std_logic_vector(3 DOWNTO 0);--Select  for  ALU  Function 
    SUBTYPE MemWr IS std_logic;--Select  for  Mem  Write  Enable

    SUBTYPE RFWen IS std_logic;--Select  for  RF  Write  Enable
    SUBTYPE WBSel IS std_logic_vector(2 DOWNTO 0);--Select  for  RF  Write  Back  Data 
    SUBTYPE PCSel IS std_logic_vector(2 DOWNTO 0);--Select  for  PC  Write  Back  Data

    --Enable mem/reg write or not, must choose one 
    CONSTANT enable : std_logic := '1';-->ENABLED 
    CONSTANT disable : std_logic := '0';-->DISABLED

    --next PC value, must choose one 
    CONSTANT pc_pc4 : PCSel := "000";--PC=PC+4
    CONSTANT pc_jalr : PCSel := "001";--PC=RS1+OFFSET,  RD=PC+4
    CONSTANT pc_branch : PCSel := "010";--PC=PC+OFFSET,  if  branch  taken 
    CONSTANT pc_jump : PCSel := "011";--PC=PC+OFFSET,  RD=PC+4
    CONSTANT pc_e : PCSel := "100";--exception,  not  implemented

    --WBSels, can be undefined
    CONSTANT wb_csr : WBSel := "000";--CSR,  not  implemented 
    CONSTANT wb_pc4 : WBSel := "001";--write  PC+4  back  to  RD 
    CONSTANT wb_alu : WBSel := "010";--write  ALU  ouput  back  to  RD
    CONSTANT wb_dmem : WBSel := "011";--write  DMEM  output  back  to  RD 
    CONSTANT wb_none : WBSel := "111";--N/A

    --Op1Sels,  can  be  undefiend
    CONSTANT op1_uimme : Op1Sel := "00";--OP1=U  type  immediate 
    CONSTANT op1_rs1 : Op1Sel := "01";--OP1=rs1's  value 
    CONSTANT op1_none : Op1Sel := "11";--N/A

    --Op2Sels,  can  be  undefined
    CONSTANT op2_pc : Op2Sel := "000";--OP2=PC
    CONSTANT op2_iimme : Op2Sel := "001";--OP2=I  type  immediate 
    CONSTANT op2_simme : Op2Sel := "010";--OP2=S  type  immediate 
    CONSTANT op2_rs2 : Op2Sel := "011";--OP2=rs2's  value 
    CONSTANT op2_none : Op2Sel := "111";--N/A
    --ALU  Functions,  use  within  ALU
    CONSTANT ALU_NONE : FuncSel := "0000";--N/A 
    CONSTANT ALU_ADD : FuncSel := "0001";--Add
    CONSTANT ALU_ADDU : FuncSel := "0010";--Add  unsigned 
    CONSTANT ALU_SUB : FuncSel := "0011";--subtract
    CONSTANT ALU_SUBU : FuncSel := "0100";--subtract  unsigned 
    CONSTANT ALU_SLT : FuncSel := "0101";--set  less  than
    CONSTANT ALU_SLTU : FuncSel := "0110";--set  less  than  unsigned 
    CONSTANT ALU_AND : FuncSel := "0111";--arithmetic  and 
    CONSTANT ALU_OR : FuncSel := "1000";--arithmetic or
    CONSTANT ALU_XOR : FuncSel := "1001";--arithmetic xor 
    CONSTANT ALU_SLL : FuncSel := "1010";--shift left logical 
    CONSTANT ALU_SRA : FuncSel := "1011";--shift  right  arithmetic 
    CONSTANT ALU_SRL : FuncSel := "1100";--shift right logical

    --Branch  Types,  Defined  by  Funct3
    CONSTANT FUNCT3_BEQ : funct3_type := "000";--funct3 field of BEQ 
    CONSTANT FUNCT3_BNE : funct3_type := "001";--funct3 field of BNE 
    CONSTANT FUNCT3_BLT : funct3_type := "100";--funct3 field of BLT

    CONSTANT FUNCT3_BGE : funct3_type := "101";--funct3 field of BGE 
    CONSTANT FUNCT3_BLTU : funct3_type := "110";--funct3 field of BLTU 
    CONSTANT FUNCT3_BGEU : funct3_type := "111";--funct3 field of BGEU

    --Load  Types,  Defined  by  Funct3
    CONSTANT FUNCT3_LB : funct3_type := "000";--funct3  field  of  LB 
    CONSTANT FUNCT3_LH : funct3_type := "001";--funct3  field  of  LH 
    CONSTANT FUNCT3_LW : funct3_type := "010";--funct3  field  of  LW 
    CONSTANT FUNCT3_LBU : funct3_type := "100";--funct3  field  of  LBU 
    CONSTANT FUNCT3_LHU : funct3_type := "101";--funct3  field  of  LHU
    --Store  Types,  Defined  by  Funct3
    CONSTANT FUNCT3_SB : funct3_type := "000";--funct3  field  of  SB 
    CONSTANT FUNCT3_SH : funct3_type := "001";--funct3  field  of  SH 
    CONSTANT FUNCT3_SW : funct3_type := "010";--funct3  field  of  SW

    --FUNCT3 of JALR
    CONSTANT FUNCT3_JALR : funct3_type := "000";--funct3  field  of  JALR

    --FUNCT3 of I Type Arithmetic functions
    CONSTANT FUNCT3_ADDI : funct3_type := "000";--funct3  field  of  ADDI 
    CONSTANT FUNCT3_SLTI : funct3_type := "010";--funct3  field  of  SLTI 
    CONSTANT FUNCT3_SLTIU : funct3_type := "011";--funct3  field  of  SLTIU 
    CONSTANT FUNCT3_XORI : funct3_type := "100";--funct3  field  of  XORI 
    CONSTANT FUNCT3_ORI : funct3_type := "110";--funct3  field  of  ORI 
    CONSTANT FUNCT3_ANDI : funct3_type := "111";--funct3  field  of  ANDI 
    CONSTANT FUNCT3_SLLI : funct3_type := "001";--funct3  field  of  SLLI 
    CONSTANT FUNCT3_SRLI : funct3_type := "101";--funct3  field  of  SRLI 
    CONSTANT FUNCT3_SRAI : funct3_type := "101";--funct3  field  of  SRAI

    --FUNCT3 of R Type Arithmetic functions
    CONSTANT FUNCT3_ADD : funct3_type := "000";--funct3  field  of  ADD 
    CONSTANT FUNCT3_SUB : funct3_type := "000";--funct3  field  of  SUB 
    CONSTANT FUNCT3_SLL : funct3_type := "001";--funct3  field  of  SLL 
    CONSTANT FUNCT3_SLT : funct3_type := "010";--funct3  field  of  SLT 
    CONSTANT FUNCT3_SLTU : funct3_type := "011";--funct3  field  of  SLTU 
    CONSTANT FUNCT3_XOR : funct3_type := "100";--funct3  field  of  XOR 
    CONSTANT FUNCT3_SRL : funct3_type := "101";--funct3  field  of  SRL 
    CONSTANT FUNCT3_SRA : funct3_type := "101";--funct3  field  of  SRA 
    CONSTANT FUNCT3_OR : funct3_type := "110";--funct3  field  of  OR 
    CONSTANT FUNCT3_AND : funct3_type := "111";--funct3  field  of  AND

    ----FUNCT3  of  Fence  functions
    CONSTANT FUNCT3_FENCE : funct3_type := "000";--funct3  field  of  FENCE 
    CONSTANT FUNCT3_FENCEI : funct3_type := "001";--funct3  field  of  FENCEI

    ----FUNCT3  of  System  functions
    CONSTANT FUNCT3_ECALL : funct3_type := "000";--funct3  field  of  ECALL 
    CONSTANT FUNCT3_EBREAK : funct3_type := "000";--funct3  field  of  EBREAK 
    CONSTANT FUNCT3_CSRRW : funct3_type := "001";--funct3  field  of  CSRRW 
    CONSTANT FUNCT3_CSRRS : funct3_type := "010";--funct3  field  of  CSRRS 
    CONSTANT FUNCT3_CSRRC : funct3_type := "011";--funct3  field  of  CSRRC 
    CONSTANT FUNCT3_CSRRWI : funct3_type := "101";--funct3  field  of  CSRRWI 
    CONSTANT FUNCT3_CSRRSI : funct3_type := "110";--funct3  field  of  CSRRSI 
    CONSTANT FUNCT3_CSRRCI : funct3_type := "111";--funct3  field  of  CSRRCI

    --FUNCT7 of I Type OP Code
    CONSTANT FUNCT7_SLLI : funct7_type := "0000000";--funct7  field  of  SLLI 
    CONSTANT FUNCT7_SRLI : funct7_type := "0000000";--funct7  field  of  SRLI 
    CONSTANT FUNCT7_SRAI : funct7_type := "0100000";--funct7  field  of  SRAI
    --FUNCT7 of R Type OP Code
    CONSTANT FUNCT7_ADD : funct7_type := "0000000";--funct7  field  of  ADD 
    CONSTANT FUNCT7_SUB : funct7_type := "0100000";--funct7  field  of  SUB 
    CONSTANT FUNCT7_SLL : funct7_type := "0000000";--funct7  field  of  SLL 
    CONSTANT FUNCT7_SLT : funct7_type := "0000000";--funct7  field  of  SLT 
    CONSTANT FUNCT7_SLTU : funct7_type := "0000000";--funct7  field  of  SLTU 
    CONSTANT FUNCT7_XOR : funct7_type := "0000000";--funct7  field  of  XOR 
    CONSTANT FUNCT7_SRL : funct7_type := "0000000";--funct7  field  of  SRL 
    CONSTANT FUNCT7_SRA : funct7_type := "0100000";--funct7  field  of  SRA 
    CONSTANT FUNCT7_OR : funct7_type := "0000000";--funct7  field  of  OR 
    CONSTANT FUNCT7_AND : funct7_type := "0000000";--funct7  field  of  AND

    --U  Type  OP  Code
    CONSTANT OP_UTYPE_AUIPC : opcode_type := "0010111";--opcode  of  AUIPC 
    CONSTANT OP_UTYPE_LUI : opcode_type := "0110111";--opcode  of  LUI
    --J Type OP Code
    CONSTANT OP_JTYPE_JAL : opcode_type := "1101111";--opcode  of  JAL
    --B  Type  OP  Code
    CONSTANT OP_BTYPE_COMMON : opcode_type := "1100011";--opcode  of  B  type  instructions
    --I Type OP Code
    CONSTANT OP_ITYPE_LOAD_COMMON : opcode_type := "0000011";-- opcode  of  load  type  instructions
    CONSTANT OP_ITYPE_ARITH_COMMON : opcode_type := "0010011";-- opcode  of  I  type  arthmetic  instructions
    CONSTANT OP_ITYPE_JALR : opcode_type := "1100111";--opcode  of  JALR
    --S  Type  OP  Code
    CONSTANT OP_STYPE_COMMON : opcode_type := "0100011";--opcode  of  S  type  instructions
    --R  Type  OP  Code
    CONSTANT OP_RTYPE_COMMON : opcode_type := "0110011";--opcode  of  R  type  instructions
    --Other Types
    CONSTANT OP_FENCE_COMMON : opcode_type := "0001111";--opcode  of  FENCE  type  instructions 
    CONSTANT OP_SYSTEM_COMMON : opcode_type := "1110011";--opcode OF SYSTEM related instructions

    --Functions  to  get  immediate  part  of  a  given  instruction
    FUNCTION get_signed_Iimme(ins : word) RETURN word;--DEFINE  get_signed_Iimme 
    FUNCTION get_signed_Simme(ins : word) RETURN word;--DEFINE  get_signed_Simme 
    FUNCTION get_signed_Bimme(ins : word) RETURN word;--DEFINE  get_signed_Bimme 
    FUNCTION get_signed_Uimme(ins : word) RETURN word;--DEFINE  get_signed_Uimme 
    FUNCTION get_signed_Jimme(ins : word) RETURN word;--DEFINE  get_signed_Jimme

    --  ADDI  r0,  r0,  r0
    CONSTANT NOP : word := "00000000000000000000000000010011";

END PACKAGE common;--END

PACKAGE BODY common IS--START

    FUNCTION get_signed_Iimme(ins : word) RETURN word IS-- given  an  instruction  ins,  return  I  type  immediate
        VARIABLE immediate : word := (OTHERS => '0');--local  variable 
    BEGIN--START
        immediate(31 DOWNTO 11) := (OTHERS => ins(31));--Sign  Extend 
        immediate(10 DOWNTO 5) := ins(30 DOWNTO 25);--Actual  Value 
        immediate(4 DOWNTO 1) := ins(24 DOWNTO 21);--Actual  Value 
        immediate(0) := ins(20);--Actual  Value
        RETURN immediate;--return  the  value 
    END get_signed_Iimme;--END

    FUNCTION get_signed_Simme(ins : word) RETURN word IS-- given  an  instruction  ins,  return  S  type  immediate
        VARIABLE immediate : word := (OTHERS => '0');--local  variable 
    BEGIN--START
        immediate(31 DOWNTO 11) := (OTHERS => ins(31));--Sign  Extend 
        immediate(10 DOWNTO 5) := ins(30 DOWNTO 25);--Actual  Value 
        immediate(4 DOWNTO 1) := ins(11 DOWNTO 8);--Actual  Value 
        immediate(0) := ins(7);--Actual  Value
        RETURN immediate;--return  the  value 
    END get_signed_Simme;--END

    FUNCTION get_signed_Bimme(ins : word) RETURN word IS-- given  an  instruction  ins,  return  B  type  immediate
        VARIABLE immediate : word := (OTHERS => '0');--local  variable 
    BEGIN--START
        immediate(31 DOWNTO 12) := (OTHERS => ins(31));--Sign  Extend 
        immediate(11) := ins(7);--Actual  Value
        immediate(10 DOWNTO 5) := ins(30 DOWNTO 25);--Actual  Value 
        immediate(4 DOWNTO 1) := ins(11 DOWNTO 8);--Actual  Value 
        immediate(0) := '0';--Actual  Value
        RETURN immediate; --return  the  value 
    END get_signed_Bimme;--END

    FUNCTION get_signed_Uimme(ins : word) RETURN word IS-- given  an  instruction  ins,  return  U  type  immediate
        VARIABLE immediate : word := (OTHERS => '0');--local  variable 
    BEGIN--START
        immediate(31) := ins(31);--Sign  Extend
        immediate(30 DOWNTO 20) := ins(30 DOWNTO 20);--Actual  Value 
        immediate(19 DOWNTO 12) := ins(19 DOWNTO 12);--Actual  Value 
        immediate(11 DOWNTO 0) := (OTHERS => '0');--Actual  Value return  
        immediate; --return  the  value
    END get_signed_Uimme;--END

    FUNCTION get_signed_Jimme(ins : word) RETURN word IS-- given  an  instruction  ins,  return  J  type  immediate
        VARIABLE immediate : word := (OTHERS => '0');--local  variable 
    BEGIN--START
        immediate(31 DOWNTO 20) := (OTHERS => ins(31));--Sign  Extend 
        immediate(19 DOWNTO 12) := ins(19 DOWNTO 12);--Actual  Value 
        immediate(11) := ins(20);--Actual  Value
        immediate(10 DOWNTO 5) := ins(30 DOWNTO 25);--Actual  Value
        immediate(4 DOWNTO 1) := ins(24 DOWNTO 21);--Actual  Value 
        immediate(0) := '0';--Actual  Value
        RETURN immediate;--return  the  value 
    END get_signed_Jimme;--END

END PACKAGE BODY common;--END