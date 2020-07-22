LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.numeric_std.ALL;
LIBRARY work;
USE work.common.ALL;--Use  the  constants  defined  in  common.vhd

ENTITY decoder IS--START
    PORT (
        inst : IN word;--instruction  in 
        rs1_val : IN word;--rs1's  value  in 
        rs2_val : IN word;--rs2's  value  in 
        op1_sel : OUT Op1Sel; --Select  for  RS1 
        op2_sel : OUT Op2Sel;--Select  for  RS2
        func_sel : OUT FuncSel;--Select  for  ALU  Function 
        mem_we : OUT MemWr;--Select  for  Mem  Write  Enable 
        rf_we : OUT RFWen;--Select  for  RF  Write  Enable 
        wb_sel : OUT WBSel;--Select  for  RF  Write  Back  Data 
        pc_sel : OUT PCSel);--Select  for  PC  Write  Back  Data
END ENTITY decoder;

ARCHITECTURE rtl OF decoder IS--START

    SIGNAL opcode : opcode_type;--the  opcode  field  of  the  given  instruction 
    SIGNAL funct3 : funct3_type;--the  funct3  field  of  given  instruction 
    SIGNAL funct7 : funct7_type;--the  funct7  field  of  given  instruction 
BEGIN--START

    opcode <= inst(6 DOWNTO 0);--extract  the  opcode  field 
    funct3 <= inst(14 DOWNTO 12);--extract  the  funct3  field 
    funct7 <= inst(31 DOWNTO 25);--extract  the  funct7  field

    sel : PROCESS (inst, opcode, funct3, funct7, rs1_val, rs2_val) IS--do  the  decoding 
    BEGIN--START

        op1_sel <= op1_rs1;--set  the  default  value  of  op1_sel 
        op2_sel <= op2_none;--set  the  default  value  of  op2_sel 
        func_sel <= ALU_NONE;--set  the  default  value  of  func_sel 
        mem_we <= disable;--set  the  default  value  of  mem_we 
        rf_we <= disable;--set  the  default  value  of  rf_we 
        wb_sel <= wb_none;--set  the  default  value  of  wb_sel 
        pc_sel <= pc_pc4;--set  the  default  value  of  pc_sel

        IF (opcode = OP_UTYPE_AUIPC) OR --if  -->
            (opcode = OP_UTYPE_LUI) THEN --U  type

            op1_sel <= op1_uimme;-->op1  is  set  to  be  u  type  immediate

            IF opcode = OP_UTYPE_AUIPC THEN--  but  if  AUIPC  presents, 
                op2_sel <= op2_pc;--op2  has  the  value  of  PC 
                func_sel <= ALU_ADD;--alu  function  is  ADD
            END IF; 

            rf_we <= enable;--for  all  u  type,  rf  is  enabled 
            wb_sel <= wb_alu;--for  all  u  type,  alu  outupt  is  written  back

        ELSIF opcode = OP_JTYPE_JAL THEN --J type 
            op1_sel <= op1_none;--for  all  j  type,  op1  is  N/A 
            rf_we <= enable;--for  all  j  type,  rf  is  enabled 
            wb_sel <= wb_pc4;--for  all  j  type,  PC+4  writes  back 
            pc_sel <= pc_jump;--for  all  j  type,  PC  =PC+OFFSET

        ELSIF opcode = OP_BTYPE_COMMON THEN --B  type 
            op1_sel <= op1_none;--for  all  B  type,  op1  is  N/A

            CASE funct3 IS--switch  on  functs
                WHEN FUNCT3_BEQ => ----------when branch equal
                    IF (rs1_val = rs2_val) THEN--if  that  is  the  real  case 
                        pc_sel <= pc_branch;-----pc  =pc+branch_OFFSET
                    END IF; --otherwise
                WHEN FUNCT3_BNE => -----------when  branch  not  equal 
                    IF (rs1_val /= rs2_val) THEN
                        pc_sel <= pc_branch;------pc  =pc+branch_OFFSET 
                    END IF; --otherwise
                WHEN FUNCT3_BLT => -----------branch less than
                    IF (to_integer(signed(rs1_val)) < to_integer(signed(rs2_val))) THEN
                        pc_sel <= pc_branch; --pc =pc+branch_OFFSET
                    END IF; --otherwise
                WHEN FUNCT3_BGE => --greater than or equal to
                    IF (to_integer(signed(rs1_val)) >= to_integer(signed(rs2_val))) THEN

                        --pc =pc+branch_OFFSET
                        pc_sel <= pc_branch;
                        --otherwise less than if true

                    END IF;
                WHEN FUNCT3_BLTU =>
                    IF (to_integer(unsigned(rs1_val)) < to_integer(unsigned(rs2_val))) THEN
                        pc_sel <= pc_branch;

                        --pc =pc+branch_OFFSET
                    END IF; --otherwise
                WHEN FUNCT3_BGEU => --greater than or equal to (unsigned)
                    IF (to_integer(unsigned(rs1_val)) >= to_integer(unsigned(rs2_val))) THEN

                        pc_sel <= pc_branch; --pc =pc+branch_OFFSET
                    END IF;

                    --otherwise N/A
                WHEN OTHERS => NULL;
            END CASE;
        ELSIF (opcode = OP_ITYPE_LOAD_COMMON) OR --I  type 
            (opcode = OP_ITYPE_ARITH_COMMON) OR --I  type 
            (opcode = OP_ITYPE_JALR) THEN--I  type

            op2_sel <= op2_iimme;--for  all  I  type,  op2=i  type  immediate 
            rf_we <= enable;--for  all  I  type,  rf  is  enabled
            CASE opcode IS--switch on opcode
                WHEN OP_ITYPE_LOAD_COMMON => --load  type 
                    func_sel <= ALU_ADD;--alu  func  is  add 
                    wb_sel <= wb_dmem;--write  back  is  dmem
                WHEN OP_ITYPE_ARITH_COMMON => --i  type  arithmetic

                    CASE funct3 IS--switch  on  funct3
                        WHEN FUNCT3_ADDI => func_sel <= ALU_ADD;--addi->alu  func=add 
                        WHEN FUNCT3_SLTI => func_sel <= ALU_SLT;--SLTI->alu  func=slt 
                        WHEN FUNCT3_SLTIU => func_sel <= ALU_SLTU;--SLTIU->alu  func=sltu 
                        WHEN FUNCT3_XORI => func_sel <= ALU_XOR;--XORI->alu  func=xor 
                        WHEN FUNCT3_ORI => func_sel <= ALU_OR;--ORI->alu  func=or
                        WHEN FUNCT3_ANDI => func_sel <= ALU_AND;--ANDI->alu  func=and 
                        WHEN FUNCT3_SLLI => func_sel <= ALU_SLL;--SLLI->alu  func=sll 
                        WHEN FUNCT3_SRLI => --srli and srai have the same opcode

                            IF (funct7 = FUNCT7_SRLI) THEN--if  srli  determined  by  funct7 
                                func_sel <= ALU_SRL;--alu  func  =  SRL
                            ELSE--otherwise
                                func_sel <= ALU_SRA;--alu  func  =  sra 
                            END IF;

                        WHEN OTHERS => NULL;--others=>N/A

                    END CASE;
                    wb_sel <= wb_alu;--for  all  I  type,  write  back  =  alu  output 
                WHEN OP_ITYPE_JALR => --jalr
                    func_sel <= ALU_NONE;--no  need  for  alu  func 
                    pc_sel <= pc_jalr;--pc=rs1+I  immediate 
                    wb_sel <= wb_pc4;--write  back  is  pc+4
                WHEN OTHERS => NULL;--others=>N/A 
            END CASE;
        ELSIF opcode = OP_STYPE_COMMON THEN --S  type

            op2_sel <= op2_simme;--for  all  s  type,  op2  is  s  type  immediate
            func_sel <= ALU_ADD;--for  all  s  type,  alu  func  =  add 
            mem_we <= enable;--for  all  s  type,  need  to  dmem  write  back

        ELSIF opcode = OP_RTYPE_COMMON THEN --R  type

            op2_sel <= op2_rs2;--for  all  r  type,  op2  is  rs2's  value 
            rf_we <= enable;--for  all  r  type,  rf  enabled 
            wb_sel <= wb_alu;--for  all  r  type,  write  back  is  alu  output

            CASE funct3 IS--switch on funct3 
                WHEN FUNCT3_ADD => --add

                    IF funct7 = FUNCT7_ADD THEN--add  and  sub  have  the  same  funct3 
                        func_sel <= ALU_ADD;--add
                    ELSE--or
                        func_sel <= ALU_SUB;--sub 
                    END IF;

                WHEN FUNCT3_SLL => func_sel <= ALU_SLL;--alu  func  =sll 
                WHEN FUNCT3_SLT => func_sel <= ALU_SLT;--alu  func  =slt 
                WHEN FUNCT3_SLTU => func_sel <= ALU_SLTU;--alu  func  =sltu 
                WHEN FUNCT3_XOR => func_sel <= ALU_XOR;--alu  func  =xor 
                WHEN FUNCT3_SRL => --srl  and  sra  have  the  same  funct3
                    IF funct7 = FUNCT7_SRL THEN--when  srl  funct7 
                        func_sel <= ALU_SRL;--alu  func=srl
                    ELSE--otherwise
                        func_sel <= ALU_SRA;--alu  func  =  sra 
                    END IF;
                WHEN FUNCT3_OR => func_sel <= ALU_OR;--alu  func  =  or 
                WHEN FUNCT3_AND => func_sel <= ALU_AND;--alu  func  =  and 
                WHEN OTHERS => NULL;--  others=>N/A
            END CASE; 

        ELSE --Others
            --SYSTEM  FUNCTIONS  ARE  NOT  IMPLEMENTED
        END IF;
    END PROCESS sel;

END ARCHITECTURE rtl;