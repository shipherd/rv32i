LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.numeric_std.ALL;
LIBRARY work;
USE work.common.ALL;

ENTITY rv32ip2 IS--rv32i  with  2  pipeline  stages 
	PORT (
		clk : IN std_logic;--clock
		rst : IN std_logic;--reset
		outputs : OUT word);--debug  output 
END ENTITY rv32ip2;--end

ARCHITECTURE rtl OF rv32ip2 IS--implement  rs32i  with  2  stage  pipeline

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

	COMPONENT reg32 IS--general  purpose  32bit  register 
		PORT (
			clk : IN std_logic;--clock
			rst : IN std_logic;--reset 
			din : IN word;--new  data  in
			we : IN std_logic;--write  enable 
			dout : OUT word);--data  out
	END COMPONENT reg32;--end

	COMPONENT pplcontrol IS--pipeline  control  signal  generator 
		PORT (
			inst_s1 : IN word;--stage  one  instruction  input
			inst_s2 : IN word;--stage  two  instruction  input 
			stall_disen : OUT std_logic;--output  of  stall  signal
			fwd_op1_sel : OUT std_logic_vector(1 DOWNTO 0);--forwarding  to  op1  selection 
			fwd_op2_sel : OUT std_logic_vector(1 DOWNTO 0);--forwarding  to  op2  selection 
			fwd_rs2_en : OUT std_logic);--for  resolving  store  RAW  hazard
	END COMPONENT pplcontrol;--end

	---Signals
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

	--Pipline  Signals
	--outputs
	SIGNAL rEIR_out : word;--Execute  stage  IR  Output 
	SIGNAL rEop1_out : word;--Execute  stage  Op1  Buffer  OUT 
	SIGNAL rEop2_out : word;--Execute  stage  Op2  Buffer  OUT 
	SIGNAL rErs1_out : word;--Execute  stage  rs1  Buffer  OUT 
	SIGNAL rErs2_out : word;--Execute  stage  rs1  Buffer  OUT
	--inputs
	SIGNAL rEIR_in : word;----Execute  stage  IR  input 
	SIGNAL rEop1_in : word;--Execute  stage  Op1  Buffer  input 
	SIGNAL rEop2_in : word;--Execute  stage  Op2  Buffer  input 
	SIGNAL rErs2_in : word;--Execute  stage  rs2  Buffer  input
	--Control  Signals
	SIGNAL op1_sel : Op1Sel; --Select  for  RS1 
	SIGNAL op2_sel : Op2Sel;--Select  for  RS2
	SIGNAL func_sel : FuncSel;--Select  for  ALU  Function 
	SIGNAL mem_we : MemWr;--Select  for  Mem  Write  Enable 
	SIGNAL rf_we : RFWen;--Select  for  RF  Write  Enable 
	SIGNAL wb_sel : WBSel;--Select  for  RF  Write  Back  Data 
	SIGNAL pc_sel : PCSel;--Select  for  PC  Write  Back  Data
	--Stall  Control  Signal
	SIGNAL stall_disen : std_logic;--'1'  =>disabled,  '0'=>enabled
	--Forwarding Signal
	SIGNAL fwd_op1_sel : std_logic_vector(1 DOWNTO 0);--Forwarding  to  op1,  00=>tmp_fwd_mux_op1,01=>alu_out,10=>dmem_out 
	SIGNAL fwd_op2_sel : std_logic_vector(1 DOWNTO 0);--Forwarding  to  op2,  00=>tmp_fwd_mux_op2,01=>alu_out,10=>dmem_out
	SIGNAL fwd_rs2_en : std_logic;--Forwarding  to  rs2  Buffer,  1=enable,  0=disable

	SIGNAL tmp_fwd_mux_op1 : word;--temp  signal  for  holding  the  value  comes  from  op1  MUX 
	SIGNAL tmp_fwd_mux_op2 : word;--temp  signal  for  holding  the  value  comes  from  op2  MUX 
	SIGNAL tmp_imem_out : word;--holds  the  output  from  instruction  memory

	SIGNAL stage2_iimme : word;--stage  2  i  type  immediate 
	SIGNAL stage2_bimme : word;--stage  2  b  type  immediate 
	SIGNAL stage2_jimme : word;--stage  2  j  type  immediate

BEGIN--START of process

	alu0 : alu PORT MAP(--mapping  for  alu  in  stage  two 
		alu_func => func_sel, --chose  alu  function   
		op1 => alu_in_op1, --chose alu op1 input 
		op2 => alu_in_op2, --chose alu op2 input 
		result => alu_out);--output of alu

	dec_stage1 : decoder PORT MAP(--For  Stage  one  decoder,  it  only  chooeses  for  op1_sel  and  op2_sel. 
		inst => imem_out, --stage  one  instruction  in 
		rs1_val => reg_out_rs1, --actually  not  in  use 
		rs2_val => reg_out_rs2, --actually  not  in  use
		op1_sel => op1_sel, --Select  for  RS1 
		op2_sel => op2_sel);--Select  for  RS2

	dec_stage2 : decoder PORT MAP(--For  stage  two  decoder,  there  is  no  need  for  selecting  op1/op2_sel 
		inst => rEIR_out, --input  stage  2  instruction 
		rs1_val => rErs1_out, --input  stage  2  rs1's  value 
		rs2_val => rErs2_out, --input  stage  2  rs2's  value
		func_sel => func_sel, --Select  for  ALU  Function 
		mem_we => mem_we, --Select  for  Mem  Write  Enable 
		rf_we => rf_we, --Select  for  RF  Write  Enable 
		wb_sel => wb_sel, --Select  for  RF  Write  Back  Data 
		pc_sel => pc_sel);--Select  for  PC  Write  Back  Data
	dmem0 : dmem PORT MAP(--Stage  2  data  memory 
		reset => rst, --reset
		clk => clk, --clock
		raddr => alu_out, --32  bits  address 
		dout => dmem_out, --OUTPUT  a  WORD 
		dsize => rEIR_out(14 DOWNTO 12), --Data  size,  if  we  =  '0'  then  read  size,  else  write  size 
		waddr => alu_out, --32  bits  address
		din => rErs2_out, --INPUT  a  WORD 
		we => mem_we, --write  enable
		debug_output => outputs);--output  regbank0(0)

	imem0 : imem PORT MAP(--Stage  1  instruction  memory 
		addr => pc_out, --reads  input  from  PC
		dout => tmp_imem_out);--output  the  instruction

	pc_stage1 : pc PORT MAP(--Stage one program counter 
		clk => clk, --clock
		rst => rst, --reset
		ra => pc_out, --read  address  input 
		wa => pc_in, --write  address  input 
		we => pc_we);--write  enable

	rf0 : regfile PORT MAP(--Stage  one  register  field 
		reset => rst, --reset
		clk => clk, --clock 
		addra => rs1, --rs1 
		addrb => rs2, --rs2
		rega => reg_out_rs1, --rs1's  value 
		regb => reg_out_rs2, --rs2's  value
		addrw => rEIR_out(11 DOWNTO 7), --address  write  from  stage  2  instruction 
		dataw => rf_in, --new  data  write
		we => rf_we);--write  enable 
	--Pipeline 
	reg_E_IR : reg32 PORT MAP(--Execute  Stage  Inst  Register
		clk => clk, --clock 
		rst => rst, --reset
		din => rEIR_in, --input  can  be  bubble  or  stage  1  instruction 
		we => enable, --always  enable
		dout => rEIR_out);--output  to  stage  2 
	reg_E_op1 : reg32 PORT MAP(--Execute  Stage  op1  buffer
		clk => clk, --clock 
		rst => rst, --reset
		din => rEop1_in, --input  is  multiplexed  due  to  forwarding 
		we => enable, --write  enable
		dout => rEop1_out);--output  to  second  stage 
	reg_E_op2 : reg32 PORT MAP(--Execute  Stage  op2  buffer
		clk => clk, --clock 
		rst => rst, --reset
		din => rEop2_in, --input  is  multiplexed  due  to  forwarding 
		we => enable, --write  enable
		dout => rEop2_out--output  to  second  stage
	);
	reg_E_rs1 : reg32 PORT MAP(--Execute  Stage  rs1  buffer 
		clk => clk, --clock
		rst => rst, --reset
		din => reg_out_rs1, --buffer  stage  1  rs1's  value 
		we => enable, --write  enable
		dout => rErs1_out);--output  to  second  stage 
	reg_E_rs2 : reg32 PORT MAP(--Execute  Stage  rs2  buffer
		clk => clk, --clock 
		rst => rst, --reset
		din => rErs2_in, --input  is  multiplexed  due  to  forwarding 
		we => enable, --write  enable
		dout => rErs2_out);--output  to  second  stage

	pcl : pplcontrol PORT MAP(--pipeline  control  signal  gennerator 
		inst_s1 => imem_out, --stage  1  instruction  input 
		inst_s2 => rEIR_out, --stage  2  instruction  input 
		stall_disen => stall_disen, --stall  signal 
		fwd_op1_sel => fwd_op1_sel, --forwarding  to  op1 
		fwd_op2_sel => fwd_op2_sel, --forwarding  to  op2 
		fwd_rs2_en => fwd_rs2_en);--forwarding  to  reg_E_rs2

	--END Pipeline

	--Pipeline--
	--Stall MUX
	rEIR_in <= imem_out; --stage  1  instruction  goes  to  buffer
	imem_out <= tmp_imem_out WHEN stall_disen = '1' ELSE
		NOP;--when  stall_disen='1'  else  NOP;

	--Forwarding MUX for op1
	WITH fwd_op1_sel SELECT rEop1_in <=
		tmp_fwd_mux_op1 WHEN "00", --when  chosen  00,  it  reads  from  normal  op1  mux 
		alu_out WHEN "01", --when  01,  forwarding  alu  output  to  op1
		dmem_out WHEN OTHERS;--forwarding  data  memory  output  to  op1

	--Forwarding MUX for op2
	WITH fwd_op2_sel SELECT rEop2_in <= --when  chosen  00,  it  reads  from  normal  op2  mux 
		tmp_fwd_mux_op2 WHEN "00", --when  01,  forwarding  alu  output  to  op2
		alu_out WHEN "01", --when  01,  forwarding  alu  output  to  op2 
		dmem_out WHEN OTHERS;--forwarding  data  memory  output  to  op2

	alu_in_op1 <= rEop1_out;--op1  buffer  outputs  value  to  alu  op1  input 
	alu_in_op2 <= rEop2_out;--op2  buffer  outputs  value  to  alu  op2  input

	--rs2 buffer MUX
	rErs2_in <= reg_out_rs2 WHEN fwd_rs2_en = '0' ELSE
		alu_out;-- if  0  normal  rs2's  value,  else  buffer  alu  output

	stage2_iimme <= get_signed_Iimme(rEIR_out);--gets stage 2 i type immediate 
	stage2_bimme <= get_signed_Bimme(rEIR_out);--gets stage 2 b type immediate 
	stage2_jimme <= get_signed_Jimme(rEIR_out);--gets stage 2 j type immediate

	pc_we <= '1';--always  enable  pc  write

	pc_plus_4 <= pc_out + 4;--stage  1  PC=PC+4
	pc_plus_jal_offset <= pc_out + stage2_jimme - 4;--stage  1  PC=PC+stage  2  j  type  immediate  -4 
	rs1_plus_jalr_offset <= rErs1_out + stage2_iimme;--PC  =  stage  two  rs2's  value  +  stage  2  i  type  immediate 
	pc_plus_branch_offset <= pc_out + stage2_bimme - 4;--PC  =  PC  +  stage  2  b  type  immediate  -  4
	inst <= imem_out;--  instruction  signal

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

	--MUX  for  selecting  normal  op1  of  ALU,  can  be  either  u  type  immediate  or  rs1's  value 
	tmp_fwd_mux_op1 <= uimme WHEN op1_sel = op1_uimme ELSE
		reg_out_rs1;

	WITH op2_sel SELECT tmp_fwd_mux_op2 <= --MUX  for  selecting  normal  op2  of  ALU,  can  be 
		pc_out WHEN op2_pc, --pc's  value
		iimme WHEN op2_iimme, --i  type  immediate simme  when  op2_simme,--s  type  immediate 
		reg_out_rs2 WHEN OTHERS;--rs2's  value

	WITH wb_sel SELECT rf_in <= --MUX  for  selecting  register  file  input,  can  be 
		pc_out WHEN wb_pc4, --PC
		dmem_out WHEN wb_dmem, --data  memory  output 
		alu_out WHEN OTHERS;--alu output
	WITH pc_sel SELECT pc_in <= --MUX  for  selecting  PC  input,  can  be 
		pc_plus_4 WHEN pc_pc4, --stage  1  PC+4
		rs1_plus_jalr_offset WHEN pc_jalr, --stage  2  rs1's  value  +  stage2  I  type  immediate 
		pc_plus_branch_offset WHEN pc_branch, --stage  1  PC+stage  2  b  type  
		immediate - 4 pc_plus_jal_offset WHEN OTHERS;--PC+  stage2  j  type  immediate-4

END ARCHITECTURE rtl;--END