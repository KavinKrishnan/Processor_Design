module Project(
	input        CLOCK_50,
	input        RESET_N,
	input  [3:0] KEY,
	input  [9:0] SW,
	output [6:0] HEX0,
	output [6:0] HEX1,
	output [6:0] HEX2,
	output [6:0] HEX3,
	output [6:0] HEX4,
	output [6:0] HEX5,
	output [9:0] LEDR
);

  parameter DBITS    =32;
  parameter INSTSIZE =32'd4;
  parameter INSTBITS =32;
  parameter REGNOBITS=4;
  parameter IMMBITS  =16;

  parameter STARTPC  =32'h100;
  parameter ADDRHEX  =32'hFFFFF000;
  parameter ADDRLEDR =32'hFFFFF020;
  parameter ADDRKEY  =32'hFFFFF080;
  parameter ADDRSW   =32'hFFFFF090;
  // Change this to fmedian.mif before submitting
  parameter IMEMINITFILE="fmedian.mif";

  parameter IMEMADDRBITS=16;
  parameter IMEMWORDBITS=2;
  parameter IMEMWORDS=(1<<(IMEMADDRBITS-IMEMWORDBITS));
  parameter DMEMADDRBITS=16;
  parameter DMEMWORDBITS=2;
  parameter DMEMWORDIDXBITS = DMEMADDRBITS-DMEMWORDBITS;
  parameter DMEMWORDS=(1<<(DMEMADDRBITS-DMEMWORDBITS));

  parameter OP1BITS  =6;
  parameter OP1_ALUR =6'b000000;
  parameter OP1_EXT  =6'b000000;
  parameter OP1_BEQ  =6'b001000;
  parameter OP1_BLT  =6'b001001;
  parameter OP1_BLE  =6'b001010;
  parameter OP1_BNE  =6'b001011;
  parameter OP1_JAL  =6'b001100;
  parameter OP1_LW   =6'b010010;
  parameter OP1_SW   =6'b011010;
  parameter OP1_ADDI =6'b100000;
  parameter OP1_ANDI =6'b100100;
  parameter OP1_ORI  =6'b100101;
  parameter OP1_XORI =6'b100110;


  // Add parameters for secondary opcode values

  /* OP2 */
  parameter OP2BITS  = 8;
  parameter OP2_EQ   = 8'b00001000;
  parameter OP2_LT   = 8'b00001001;
  parameter OP2_LE   = 8'b00001010;
  parameter OP2_NE   = 8'b00001011;

  parameter OP2_ADD  = 8'b00100000;
  parameter OP2_AND  = 8'b00100100;
  parameter OP2_OR   = 8'b00100101;
  parameter OP2_XOR  = 8'b00100110;
  parameter OP2_SUB  = 8'b00101000;
  parameter OP2_NAND = 8'b00101100;
  parameter OP2_NOR  = 8'b00101101;
  parameter OP2_NXOR = 8'b00101110;
  parameter OP2_RSHF = 8'b00110000;
  parameter OP2_LSHF = 8'b00110001;

  parameter HEXBITS  = 24;
  parameter LEDRBITS = 10;

	parameter ALU_EQ   = 6'b000000;
	parameter ALU_LT   = 6'b000001;
	parameter ALU_LE   = 6'b000010;
	parameter ALU_NE   = 6'b000011;
	parameter ALU_ADD  = 6'b000100;
	parameter ALU_AND  = 6'b000101;
	parameter ALU_OR   = 6'b000110;
	parameter ALU_XOR  = 6'b000111;
	parameter ALU_SUB  = 6'b001000;
	parameter ALU_NAND = 6'b001001;
	parameter ALU_NOR  = 6'b001010;
	parameter ALU_NXOR = 6'b001011;
	parameter ALU_RSHF = 6'b001100;
	parameter ALU_LSHF = 6'b001101;

  // The reset signal comes from the reset button on the DE0-CV board
  // RESET_N is active-low, so we flip its value ("reset" is active-high)
  wire clk,locked;
  // The PLL is wired to produce clk and locked signals for our logic

  Pll myPll(

    .refclk(CLOCK_50),
	 .rst      (!RESET_N),
	 .outclk_0 (clk),
    .locked   (locked)
  );

  wire reset=!locked;


  /*************** BUS *****************/
  // Create the processor's bus
  tri [(DBITS-1):0] thebus;

  parameter BUSZ={DBITS{1'bZ}};

  /*************** PC *****************/
  // Create PC and connect it to the bus
  reg [(DBITS-1):0] PC;
  initial begin
    PC <= STARTPC;
  end
  reg LdPC, DrPC, IncPC;

  //Data path
  always @(posedge clk or posedge reset) begin
    if(reset)
	   PC<=STARTPC;
	 else if(LdPC)
      PC<=thebus;
    else if(IncPC)
      PC<=PC+INSTSIZE;
    else
	   PC<=PC;
  end
  assign thebus=DrPC?PC:BUSZ;

  /*************** Fetch - Instruction memory *****************/
  (* ram_init_file = IMEMINITFILE *)
  reg [(DBITS-1):0] imem[(IMEMWORDS-1):0];


	(* ram_init_file = IMEMINITFILE *)
  reg [(DBITS-1):0] dmem[(DMEMWORDS-1):0];


  wire [(DBITS-1):0] iMemOut;

  assign iMemOut=imem[PC[(IMEMADDRBITS-1):IMEMWORDBITS]];

  /*************** Fetch - Instruction Register *****************/
  // Create the IR (feeds directly from memory, not from bus)
  reg [(INSTBITS-1):0] IR;
  reg LdIR;

  //Data path
  always @(posedge clk or posedge reset)
  begin
    if(reset)
	   IR<=32'hDEADDEAD;
	 else if(LdIR)
      IR <= iMemOut;
  end

  /*************** Decode *****************/
  // Put the code for getting op1, rd, rs, rt, imm, etc. here
  wire [(OP1BITS-1)    : 0] op1;
  wire [(OP2BITS-1)    : 0] op2;
	wire [(IMMBITS-1)    : 0] imm;
	wire [(REGNOBITS-1)  : 0] rd;
  wire [(REGNOBITS-1)  : 0] rs;
  wire [(REGNOBITS-1)  : 0] rt;

  //TODO: Implement instruction decomposition logic
  assign op1 = IR[31:26];
  assign op2 = IR[25:18];
	assign imm = IR[23:8];
	assign rd =  IR[11:8];
	assign rs =  IR[7:4];
  assign rt =  IR[3:0];

  /*************** sxtimm *****************/
  wire [(DBITS-1)  : 0] sxtimm;
  reg DrOff;
  assign thebus = DrOff? sxtimm:BUSZ;

	wire[(DBITS - 1) : 0] sxt4imm;
 	reg Dr4xoff;
 	assign thebus = Dr4xoff? sxt4imm:BUSZ;
  /*************** Register file *****************/
  // Create the registers and connect them to the bus
  reg [(DBITS-1):0] regs[15:0];

  //Control signals
  reg WrReg,DrReg;

  //Data signals
  reg  [(REGNOBITS-1):0] regno;
  wire [(DBITS-1)    :0] regOut;

  always @(posedge clk)
  begin: REG_WRITE
    if(WrReg)
      regs[regno]<=thebus;
  end

  assign regOut =WrReg?{DBITS{1'bX}}:(regno == 4'd0) ? 0 : regs[regno];
  assign thebus= DrReg?regOut:BUSZ;

  /******************** ALU **********************/
  // Create ALU unit and connect to the bus
  //Data signals
  reg signed [(DBITS-1):0] A,B;
  reg signed [(DBITS-1):0] ALUout;
  //Control signals
  reg [5:0] ALUfunc;
  reg LdA, LdB, DrALU;

  //Data path
  // Receive data from bus
  always @(posedge clk) begin
    if(LdA)
      A <= thebus;
    if(LdB)
      B <= thebus;
  end

  //TODO: Implement ALU functionality
	//ALU results
  always @ (ALUfunc or A or B)
  	begin: ALU_OPERATION
      case(ALUfunc)
        ALU_EQ: begin
        	ALUout = (A == B);
        end
        ALU_LT: begin
        	ALUout = (A < B);
        end
        ALU_LE: begin
        	ALUout = (A <= B);
        end
        ALU_NE: begin
        	ALUout = (A != B);
        end
        ALU_ADD: begin
        	ALUout = A + B;
        end
        ALU_AND: begin
        	ALUout = A & B;
        end
        ALU_OR: begin
          ALUout = A | B;
        end
        ALU_XOR: begin
          ALUout = A ^ B;
        end
        ALU_SUB: begin
        	ALUout = A - B;
        end
        ALU_NAND: begin
        	ALUout = ~(A & B);
        end
        ALU_NOR: begin
        	ALUout = ~(A | B);
        end
        ALU_NXOR: begin
        	ALUout = ~(A ^ B);
        end
        ALU_RSHF: begin
          ALUout = $signed(A) >>> $unsigned(B);
        end
        ALU_LSHF: begin
        	ALUout = $signed(A) << $unsigned(B);
        end
      	default: ALUout = 0;
      endcase
		end

  assign thebus=DrALU?ALUout:BUSZ;

  /*************** Data Memory *****************/
  // TODO: Put the code for data memory and I/O here

  //Data memory
  reg [(DBITS-1):0] MAR;


  //Data signals
  wire [(DBITS-1):0] memin, MemVal;
  wire [(DMEMWORDIDXBITS-1):0] dmemAddr;

  //Control singals
  reg DrMem, WrMem, LdMAR;
  wire MemEnable, MemWE;

  assign MemEnable = !(MAR[(DBITS-1):DMEMADDRBITS]);
  assign MemWE     = WrMem & MemEnable & !reset;

  always @(posedge clk or posedge reset)
  begin: LOAD_MAR
    if(reset) begin
      MAR<=32'b0;
    end
    else if(LdMAR) begin
      MAR<=thebus;
    end
  end

  reg [31: 0]iomem;
	//memmapped input
  always @( *) begin
    if(MAR == ADDRSW) begin
		iomem = {22'd0, SW};
		end
		if(MAR == ADDRKEY) begin
		iomem = {28'd0, KEY};
		end
  end

  //Data path
  assign dmemAddr = MAR[(DMEMADDRBITS-1):DMEMWORDBITS];
  assign MemVal  = MemEnable? dmem[dmemAddr] : iomem;
  assign memin   = thebus;   //Snoop the bus
	reg[23:0] HEX_OUT;
  reg[9:0] LEDR_OUT;


  always @(posedge clk)
  begin: DMEM_STORE
    if(MemWE) begin
      dmem[dmemAddr] <= memin;
    end
		//memmapped output
	 else if((MAR == ADDRHEX) && WrMem == 1'b1) begin
		HEX_OUT<=memin[23:0];
	 end
	 else if((MAR == ADDRLEDR) && WrMem == 1'b1) begin
	 	LEDR_OUT <= memin[9:0];
	 end
	end
  assign thebus=DrMem? MemVal:BUSZ;

  /******************** Processor state **********************/
  parameter S_BITS=5;
  parameter [(S_BITS-1):0]
    S_ZERO        = {(S_BITS){1'b0}},
    S_ONE         = {{(S_BITS-1){1'b0}},1'b1},
    S_FETCH1      = S_ZERO,
    S_FETCH2      = S_FETCH1 + S_ONE,
    S_ALUR1       = S_FETCH2 + S_ONE,
    S_ALUR2       = S_ALUR1 + S_ONE,
    S_ALUR3       = S_ALUR2 + S_ONE,
    S_ALUI1       = S_ALUR3 + S_ONE,
    S_MEM1        = S_ALUI1 + S_ONE,
    S_MEM2        = S_MEM1 + S_ONE,
    S_MEM3        = S_MEM2 + S_ONE,
    S_MEM4        = S_MEM3 + S_ONE,
    S_LW          = S_MEM4 + S_ONE,
    S_JAL1        = S_LW + S_ONE,
    S_JAL2        = S_JAL1 + S_ONE,
    S_JAL3        = S_JAL2 + S_ONE,
    S_JAL4        = S_JAL3+ S_ONE,
		S_BR1         = S_JAL4 + S_ONE,
    S_BR2         = S_BR1 + S_ONE,
    S_BR3         = S_BR2 + S_ONE,
    S_BR4         = S_BR3 + S_ONE,
    S_BR5         = S_BR4 + S_ONE,
    S_BR6         = S_BR5 + S_ONE,
    S_ERROR       = S_BR6 + S_ONE;

    reg [(S_BITS-1):0] state,next_state;
    initial begin
        state <= S_FETCH1;
    end
    always @(state or op1 or rs or rt or rd or op2 or ALUout[0]) begin
      {LdPC, DrPC, IncPC, LdMAR, WrMem, DrMem, LdIR, DrOff, LdA,  LdB,  DrALU, regno, DrReg, WrReg, Dr4xoff}=
      {1'b0, 1'b0, 1'b0,  1'b0,  1'b0,  1'b0,  1'b0, 1'b0,  1'b0, 1'b0, 1'b0,  4'bX,  1'b0,  1'b0, 1'b0};
        case(state)
            S_FETCH1: {LdIR,IncPC, next_state}={1'b1,1'b1, S_FETCH2};
            S_FETCH2: begin
            	case(op1)
              	OP1_ALUR: begin
                	case(op2)
										OP2_ADD:  {ALUfunc, next_state} = {ALU_ADD,  S_ALUR1};
	                  OP2_SUB:  {ALUfunc, next_state} = {ALU_SUB,  S_ALUR1};
										OP2_AND:  {ALUfunc, next_state} = {ALU_AND,  S_ALUR1};
	                  OP2_OR:   {ALUfunc, next_state} = {ALU_OR,  S_ALUR1};
	                  OP2_XOR:  {ALUfunc, next_state} = {ALU_XOR,  S_ALUR1};
	                  OP2_NAND: {ALUfunc, next_state} = {ALU_NAND, S_ALUR1};
	                  OP2_NOR:  {ALUfunc, next_state} = {ALU_NOR, S_ALUR1};
	                  OP2_NXOR: {ALUfunc, next_state} = {ALU_NXOR, S_ALUR1};
	                  OP2_RSHF: {ALUfunc, next_state} = {ALU_RSHF, S_ALUR1};
	                  OP2_LSHF: {ALUfunc, next_state} = {ALU_LSHF, S_ALUR1};
	                  OP2_EQ:   {ALUfunc, next_state} = {ALU_EQ,  S_ALUR1};
	                  OP2_LT:   {ALUfunc, next_state} = {ALU_LT,  S_ALUR1};
	                  OP2_LE:   {ALUfunc, next_state} = {ALU_LE,  S_ALUR1};
	                  OP2_NE:   {ALUfunc, next_state} = {ALU_NE,  S_ALUR1};
                    default: next_state=S_ERROR;
                endcase
              end
              OP1_ADDI:  {ALUfunc, next_state} = {ALU_ADD,  S_ALUR1};
              OP1_ANDI:  {ALUfunc, next_state} = {ALU_AND,  S_ALUR1};
              OP1_ORI:   {ALUfunc, next_state} = {ALU_OR,  S_ALUR1};
              OP1_XORI:  {ALUfunc, next_state} = {ALU_XOR,  S_ALUR1};

							OP1_JAL: next_state = S_JAL1;
	            OP1_LW, OP1_SW: next_state = S_MEM1;

	            OP1_BEQ: next_state = S_BR1;
							OP1_BLT: next_state = S_BR1;
							OP1_BLE: next_state = S_BR1;
							OP1_BNE: next_state = S_BR1;

              default: next_state = S_ERROR;
            endcase
          end
          S_ALUR1: begin
	          case(op1)
							OP1_ADDI: {LdA, DrReg, regno, next_state} = {1'b1, 1'b1, rs, S_ALUI1};
							OP1_ANDI: {LdA, DrReg, regno, next_state} = {1'b1, 1'b1, rs, S_ALUI1};
							OP1_ORI: {LdA, DrReg, regno, next_state} = {1'b1, 1'b1, rs, S_ALUI1};
							OP1_XORI: {LdA, DrReg, regno, next_state} = {1'b1, 1'b1, rs, S_ALUI1};
	            OP1_ALUR: {LdA, DrReg, regno, next_state} = { 1'b1, 1'b1, rs, S_ALUR2};
	            default: next_state = S_ERROR;
	          endcase
	        end
	        S_ALUI1: {LdB, DrOff, next_state} = {1'b1, 1'b1, S_ALUR3};
					S_ALUR2: {LdB, DrReg, regno , next_state} = {1'b1, 1'b1, rt, S_ALUR3};
	        S_ALUR3: begin
          	case(op1)
	            OP1_ALUR: begin
	              case(op2)
									OP2_ADD:  {ALUfunc} = {ALU_ADD};
									OP2_AND:  {ALUfunc} = {ALU_AND};
	                OP2_SUB:  {ALUfunc} = {ALU_SUB};
									OP2_OR:   {ALUfunc} = {ALU_OR};
									OP2_XOR:  {ALUfunc} = {ALU_XOR};
	                OP2_NAND: {ALUfunc} = {ALU_NAND};
	                OP2_NOR:  {ALUfunc} = {ALU_NOR};
	                OP2_NXOR: {ALUfunc} = {ALU_NXOR};
	                OP2_RSHF: {ALUfunc} = {ALU_RSHF};
	                OP2_LSHF: {ALUfunc} = {ALU_LSHF};
	                OP2_EQ:   {ALUfunc} = {ALU_EQ};
	                OP2_LT:   {ALUfunc} = {ALU_LT};
	                OP2_LE:   {ALUfunc} = {ALU_LE};
	                OP2_NE:   {ALUfunc} = {ALU_NE};
									default: next_state=S_ERROR;
                endcase
              end
              OP1_ADDI:  {ALUfunc} = {ALU_ADD};
              OP1_ANDI:  {ALUfunc} = {ALU_AND};
              OP1_ORI:   {ALUfunc} = {ALU_OR};
              OP1_XORI:  {ALUfunc} = {ALU_XOR};
            endcase
            	case(op1)
	              OP1_ALUR: {DrALU, WrReg, regno, next_state} = {1'b1, 1'b1, rd, S_FETCH1};
	              OP1_ADDI: {DrALU, WrReg,regno, next_state} = {1'b1,  1'b1, rt, S_FETCH1};
								OP1_ANDI: {DrALU, WrReg,regno, next_state} = {1'b1,  1'b1, rt, S_FETCH1};
								OP1_ORI: {DrALU, WrReg,regno, next_state} = {1'b1,  1'b1, rt, S_FETCH1};
								OP1_XORI: {DrALU, WrReg,regno, next_state} = {1'b1,  1'b1, rt, S_FETCH1};
                default: next_state = S_ERROR;
              endcase
          end

        S_MEM1: {LdA, DrReg, regno , next_state} = {1'b1, 1'b1, rs, S_MEM2};
        S_MEM2: {LdB, DrOff, next_state} = {1'b1, 1'b1, S_MEM3};
        S_MEM3: begin
        	case(op1)
            OP1_LW: {DrALU, LdMAR, ALUfunc, next_state} = { 1'b1, 1'b1, ALU_ADD, S_LW};
            OP1_SW: {DrALU, LdMAR, ALUfunc, next_state} = { 1'b1, 1'b1, ALU_ADD, S_MEM4};
            default: next_state = S_ERROR;
          endcase
        end
        S_LW: {DrMem, WrReg, regno, next_state} = {1'b1, 1'b1, rt, S_FETCH1};
        S_MEM4:  {DrReg, WrMem, regno, next_state} = {1'b1, 1'b1, rt, S_FETCH1};

        S_BR1: {LdA, DrReg, regno,  next_state} = { 1'b1, 1'b1, rs, S_BR2};
        S_BR2: {LdB, DrReg, regno,  next_state} = { 1'b1, 1'b1, rt, S_BR3};
        S_BR3: begin
				case(op1)
					OP1_BEQ: ALUfunc = ALU_EQ;
					OP1_BLT: ALUfunc = ALU_LT;
					OP1_BLE: ALUfunc = ALU_LE;
					OP1_BNE: ALUfunc = ALU_NE;
				endcase
					DrALU = 1'b1;
					if(ALUout == 1) begin
						next_state =S_BR4;
					end
					else begin
						next_state = S_FETCH1;
					end
				end
        S_BR4: {LdA, Dr4xoff, next_state} = {1'b1, 1'b1, S_BR5};
        S_BR5: {LdB, DrPC, next_state} = {1'b1, 1'd1, S_BR6};
        S_BR6: {LdPC, DrALU, ALUfunc, next_state} = { 1'b1, 1'b1, ALU_ADD, S_FETCH1};

				S_JAL1: {WrReg, DrPC, regno, next_state} = {1'b1, 1'b1, rt, S_JAL2};
			 	S_JAL2: {LdA, DrReg, regno, next_state} = {1'b1, 1'b1, rs, S_JAL3};
			 	S_JAL3: {LdB, Dr4xoff, next_state} = {1'b1, 1'b1, S_JAL4};
			 	S_JAL4: {LdPC, DrALU, ALUfunc, next_state} = {1'b1, 1'b1, ALU_ADD, S_FETCH1};

      endcase
		end

  //TODO: Implement your processor state transition machine
  always @(posedge clk or posedge reset)
    if(reset) state<=S_FETCH1;
    else state<=next_state;


  /*************** sign-extend (SXT) *****************/
  //TODO: Instantiate SXT module

  SXT #(16, 32) sxt0(.IN(imm), .OUT(sxtimm));
	SXT #(16,32) sxt1(.IN(imm << 2), .OUT(sxt4imm));

  /*************** HEX/LEDR Output *****************/
  //TODO: Implement output logic
  //      store to HEXADDR or LEDR addr should display given values to HEX or LEDR

  assign LEDR = LEDR_OUT;

  //TODO: Utilize seven segment display decoders to convert hex to actual seven-segment display control signal
	SevenSeg ss0(.IN(HEX_OUT[3:0]),.OFF(1'b0),.OUT(HEX0));
  SevenSeg ss1(.IN(HEX_OUT[7:4]),.OFF(1'b0),.OUT(HEX1));
  SevenSeg ss2(.IN(HEX_OUT[11:8]),.OFF(1'b0),.OUT(HEX2));
  SevenSeg ss3(.IN(HEX_OUT[15:12]),.OFF(1'b0),.OUT(HEX3));
  SevenSeg ss4(.IN(HEX_OUT[19:16]),.OFF(1'b0),.OUT(HEX4));
  SevenSeg ss5(.IN(HEX_OUT[23:20]),.OFF(1'b0),.OUT(HEX5));

endmodule

module SXT(IN,OUT);
  parameter IBITS;
  parameter OBITS;
  input  [(IBITS-1):0] IN;
  output [(OBITS-1):0] OUT;
  assign OUT={{(OBITS-IBITS){IN[IBITS-1]}},IN};
endmodule
