LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.numeric_std.ALL;
LIBRARY work;
USE work.common.ALL;

ENTITY rv32i IS--RV32I  without  pipeline  entity 
    PORT (
        clk : IN std_logic;--clock
        rst : IN std_logic;--reset
        outputs : OUT word);--debug  output 
END ENTITY rv32i;--END  RV32I

ARCHITECTURE rtl OF rv32i IS--implement  rv32i

    --DEFINE alu START
    COMPONENT alu IS
        PORT (
            alu_func : IN FuncSel;--Selection  signal  of  ALU  functions 
            op1 : IN word;--Oprand  1  input  to  ALU
            op2 : IN word;--Oprand  2  input  to  ALU
            result : OUT word);--The  output  of  the  given  ALU  function 
    END COMPONENT alu;--DEFINE  alu  END

    COMPONENT decoder IS--decoder 
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
    END COMPONENT decoder;--END

    COMPONENT dmem IS--data  memory
        PORT (
            reset : IN std_logic;--reset 
            clk : IN std_logic;--clock
            raddr : IN mem_addr_type;--32  bits  address 
            dout : OUT word;--OUTPUT  a  WORD
            dsize : IN funct3_type;--Data  size,  if  we  =  '0'  then  read  size,  else  write  size 
            waddr : IN mem_addr_type;--32  bits  address
            din : IN word;--INPUT  a  WORD
            we : IN std_logic;--write  enable 
            debug_output : OUT word--debug  output,  regbank0(0)
        );
    END COMPONENT dmem;--END

    COMPONENT imem IS--inst  memory
        PORT (
            addr : IN mem_addr_type;--input  address 
            dout : OUT word);--output  instruction
    END COMPONENT imem;--END

    COMPONENT pc IS--program  counter 
        PORT (
            clk : IN std_logic;--clock
            rst : IN std_logic;--reset
            ra : OUT mem_addr_type;--read  address 
            wa : IN mem_addr_type;--write  address 
            we : IN std_logic);--write  enable
    END COMPONENT pc;--END

    COMPONENT regfile IS--register  file 
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
    END COMPONENT regfile;--end

    --Signals
    SIGNAL inst : word;--instruction  signal
    --Instruction Fields
    SIGNAL opcode : opcode_type;--opcode  field  of  inst 
    SIGNAL funct3 : funct3_type;--funct3  field  of  inst 
    SIGNAL rd : rd_type;--rd  field  of  inst
    SIGNAL rs1 : rs1_type;--rs1  field  of  inst 
    SIGNAL rs2 : rs2_type;--rs2  field  of  rs2
    SIGNAL funct7 : funct7_type;--funct7  field  of  inst
    --Immediates
    SIGNAL iimme : word;--i  type  immediate 
    SIGNAL simme : word;--s  type  immediate 
    SIGNAL bimme : word;--b  type  immediate 
    SIGNAL uimme : word;--u  type  immediate 
    SIGNAL jimme : word;--j  type  immediate
    --Control  Signals
    SIGNAL op1_sel : Op1Sel; --Select  for  RS1 
    SIGNAL op2_sel : Op2Sel;--Select  for  RS2
    SIGNAL func_sel : FuncSel;--Select  for  ALU  Function 
    SIGNAL mem_we : MemWr;--Select  for  Mem  Write  Enable 
    SIGNAL rf_we : RFWen;--Select  for  RF  Write  Enable 
    SIGNAL wb_sel : WBSel;--Select  for  RF  Write  Back  Data 
    SIGNAL pc_sel : PCSel;--Select  for  PC  Write  Back  Data

    --Component  Data  Outputs
    SIGNAL alu_out : word;--alu  output 
    SIGNAL reg_out_rs1 : word;--rs1's  value 
    SIGNAL reg_out_rs2 : word;--rs2's  value
    SIGNAL dmem_out : word;--data  memory  output 
    SIGNAL pc_out : word;--program  counter  output
    SIGNAL imem_out : word;--inst  memory  output

    --Component  Data  Inputs
    SIGNAL alu_in_op1 : word;--input  for  alu  op1 
    SIGNAL alu_in_op2 : word;--input  for  alu  op2
    SIGNAL pc_in : word;--new  address  for  program  counter 
    SIGNAL pc_we : std_logic;--pc write enable
    SIGNAL rf_in : word;--new  data  register  field

    --Temp  Signals
    SIGNAL pc_plus_4 : word;--holds  pc+4
    SIGNAL pc_plus_jal_offset : word;--holds  pc+offset 
    SIGNAL rs1_plus_jalr_offset : word;--holds  rs1+offset 
    SIGNAL pc_plus_branch_offset : word;--pc+branch_offset

BEGIN--start

    alu0 : alu PORT MAP(--mapping  for  alu
        alu_func => func_sel, --chose  alu  function 
        op1 => alu_in_op1, --chose alu op1 input 
        op2 => alu_in_op2, --chose alu op2 input 
        result => alu_out);--output of alu

    dec0 : decoder PORT MAP(--mapping of decoder 
        inst => inst, --input  instruction 
        rs1_val => reg_out_rs1, --input  rs1's  value 
        rs2_val => reg_out_rs2, --input  rs2's  value 
        op1_sel => op1_sel, --Select  for  RS1 
        op2_sel => op2_sel, --Select  for  RS2
        func_sel => func_sel, --Select  for  ALU  Function 
        mem_we => mem_we, --Select  for  Mem  Write  Enable 
        rf_we => rf_we, --Select  for  RF  Write  Enable 
        wb_sel => wb_sel, --Select  for  RF  Write  Back  Data 
        pc_sel => pc_sel--Select  for  PC  Write  Back  Data
    );

    dmem0 : dmem PORT MAP(--mapping  for  data  memory 
        reset => rst, --reset
        clk => clk, --clock
        raddr => alu_out, --32  bits  address 
        dout => dmem_out, --OUTPUT  a  WORD
        dsize => funct3, --Data  size,  if  we  =  '0'  then  read  size,  else  write  size 
        waddr => alu_out, --32  bits  address
        din => reg_out_rs2, --INPUT  a  WORD 
        we => mem_we, --write  enable
        debug_output => outputs);--output  regbank0(0)

    imem0 : imem PORT MAP(--mapping  for  inst  memory 
        addr => pc_out, --inst address = pc value 
        dout => imem_out);--output of inst memory

    pc0 : pc PORT MAP(--mapping  for  pc 
        clk => clk, --clock 
        rst => rst, --reset
        ra => pc_out, --read  address 
        wa => pc_in, --new  pc  in 
        we => pc_we);--pc  write  enable

    rf0 : regfile PORT MAP(--regsiter  field  mapping 
        reset => rst, --reset
        clk => clk, --clock 
        addra => rs1, --rs1 
        addrb => rs2, --rs2
        rega => reg_out_rs1, --rs1's  value 
        regb => reg_out_rs2, --rs2's  value 
        addrw => rd, --rd
        dataw => rf_in, --data  to  be  written 
        we => rf_we);--writen  enable
    pc_we <= '1';--always  enable  pc  write

    pc_plus_4 <= pc_out + 4;--pc=PC+4 
    pc_plus_jal_offset <= pc_out + jimme;--PC=PC+J  type  immediate
    rs1_plus_jalr_offset <= reg_out_rs1 + iimme;--PC=rs1+i  type  immediate 
    pc_plus_branch_offset <= pc_out + bimme;--PC=PC+b  type  immediate

    inst <= imem_out;--inst  gets  the  output  from  inst  memory

    opcode <= inst(6 DOWNTO 0);--opcode filed of instruction 
    rd <= inst(11 DOWNTO 7);--rd  filed  of  instruction 
    funct3 <= inst(14 DOWNTO 12);--funct3  filed  of  instruction 
    rs1 <= inst(19 DOWNTO 15);--rs1  filed  of  instruction 
    rs2 <= inst(24 DOWNTO 20);--rs2  filed  of  instruction 
    funct7 <= inst(31 DOWNTO 25);--funct7  filed  of  instruction

    iimme <= get_signed_Iimme(inst);--gets  i  type  immediate 
    simme <= get_signed_Simme(inst);--gets  s  type  immediate 
    bimme <= get_signed_Bimme(inst);--gets  b  type  immediate 
    uimme <= get_signed_Uimme(inst);--gets  u  type  immediate 
    jimme <= get_signed_Jimme(inst);--gets  j  type  immediate

    alu_in_op1 <= uimme WHEN op1_sel = op1_uimme ELSE
        reg_out_rs1;--MUX  for  selecting  op1  of  ALU,  can  be  either  u  type  immediate  or  rs1's  value
    WITH op2_sel SELECT alu_in_op2 <= --MUX  for  selecting  op2  of  ALU,  can  be 
        pc_out WHEN op2_pc, --pc's  value
        iimme WHEN op2_iimme, --i  type  immediate 
        simme WHEN op2_simme, --s  type  immediate 
        reg_out_rs2 WHEN OTHERS;--rs2's  value

    WITH wb_sel SELECT rf_in <= --MUX  for  selecting  register  file  input,  can  be 
        pc_plus_4 WHEN wb_pc4, --PC+4
        dmem_out WHEN wb_dmem, --data  memory  output 
        alu_out WHEN OTHERS;--alu output
    WITH pc_sel SELECT pc_in <= --MUX  for  selecting  PC  input,  can  be 
        pc_plus_4 WHEN pc_pc4, --PC+4
        rs1_plus_jalr_offset WHEN pc_jalr, --rs1+I type immediate 
        pc_plus_branch_offset WHEN pc_branch, --PC+b  type  immediate 
        pc_plus_jal_offset WHEN OTHERS;--PC+j  type  immediate

END ARCHITECTURE rtl;--END