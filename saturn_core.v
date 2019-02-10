/*
 * Licence: GPLv3 or later
 */

`default_nettype none //

`include "bus_commands.v"
`include "hp48_00_bus.v"

/**************************************************************************************************
 *
 *
 *
 *
 *
 */

`ifdef SIM
module saturn_core (
	input			clk,
	input			reset,
	output			halt,
	output [3:0] 	busstate,
	output [11:0] 	decstate
);
`else
module saturn_core (
	input			clk_25mhz,
	input [	6:0] 	btn,
	// output 			wifi_gpio0,
	output [7:0]	led
);
wire 		clk;
wire 		reset;
reg			clk2;

// assign wifi_gpio0	= 1'b1;
assign clk			= clk_25mhz;
assign reset		= btn[1];

`endif

// data transfer constants



// clocks
reg				clk2;
reg				clk3;
wire			bus_ctrl_clk;
wire			ph0;
wire			ph1;
wire			ph2;
wire			ph3;
reg				en_bus_clk;
wire			bus_strobe;
reg				en_dec_clk;
wire			dec_strobe;

// state machine stuff
wire			halt;
reg		[31:0]	cycle_ctr;
reg		[31:0]	instr_ctr;
reg				decode_error;
reg				debug_stop;
reg		[3:0]	cycle_type;
reg		[3:0]	next_cycle;

reg 			read_next_pc;
reg				execute_cycle;
reg				inc_pc;
reg 			read_nibble;
reg				first_nibble;

reg		[11:0]	decstate;
reg		[11:0]	fields_return;
reg		[3:0]	regdump;

// bus access
reg		[19:0]	bus_address;
reg		[3:0]	bus_command;
reg		[3:0]	bus_nibble_in;
wire	[3:0]	bus_nibble_out;
wire			bus_error;
reg				bus_load_pc;
reg				en_bus_load_pc;

// should go away, the rom should work like any other bus module
reg		[7:0]   display_counter;

// internal registers
reg [19:0]	new_PC;
reg [19:0]	next_PC;
reg	[19:0]  inst_start_PC;

reg	[2:0]	rstk_ptr;

reg	[19:0]  jump_base;
reg	[19:0]	jump_offset;

reg			hex_dec;
`define	MODE_HEX	0;
`define MODE_DEC	1;

// data transfer registers
reg [3:0]	t_offset;
reg	[3:0]	t_cnt;
reg	[3:0]	t_ctr;
reg 		t_dir;
reg			t_ptr;
reg			t_reg;
reg			t_ftype;
reg	[3:0]	t_field;

reg	[3:0]	nb_in;
reg [3:0]	nb_out;
reg	[19:0]	add_out;

// temporary stuff
reg			t_set_test;
reg			t_set_test_val;
reg			t_add_sub;
reg	[3:0]	t_first;
reg [3:0]	t_last;

// alu control

reg	[3:0]	field;
reg [1:0]	field_table;

reg [3:0]	alu_op;
reg [3:0]	alu_first;
reg [3:0]	alu_last;
reg [3:0]	alu_reg_src1;
reg [3:0]	alu_reg_src2;
reg [3:0]	alu_reg_dest;

reg [3:0]	alu_src1;
reg [3:0]	alu_src2;
reg [3:0]	alu_tmp;
reg			alu_carry;
reg			alu_debug;
reg			alu_halt;
reg			alu_requested_halt;
reg	[11:0]	alu_return;
reg	[3:0]	alu_next_cycle;

// processor registers
reg	[19:0]	PC;
reg	[3:0]	P;
reg	[15:0]  ST;
reg	[3:0]	HST;
reg			Carry;
reg	[19:0]	RSTK[0:7];
reg	[19:0]	D0;
reg	[19:0]	D1;

reg	[63:0]	A;
reg	[63:0]	B;
reg	[63:0]	C;
reg	[63:0]	D;

reg	[63:0]	R0;
reg	[63:0]	R1;
reg	[63:0]	R2;
reg	[63:0]	R3;
reg	[63:0]	R4;

hp48_bus bus_ctrl (
	.strobe			(bus_strobe),
	.reset			(reset),
	.address		(bus_address),
	.command		(bus_command),
	.nibble_in		(bus_nibble_in),
	.nibble_out		(bus_nibble_out),
	.bus_error		(bus_error)
);

initial
	begin
		$display("initializing clocks");
		clk2					= 0;
		clk3					= 0;
		en_bus_clk				= 0;
		$display("initialize cycle counter");
		cycle_ctr				= -1;
		instr_ctr				= 0;
		$display("initializing bus_command");
		bus_command				= `BUSCMD_NOP;
		$display("initializing busstate");
		next_cycle				= `BUSCMD_LOAD_PC;
		$display("Initializing decstate");
		decstate				= 0;
		$display("initializing control bits");
		decode_error			= 0;
		debug_stop				= 0;
		bus_load_pc				= 1;
		en_bus_load_pc			= 1;
		read_next_pc			= 1;
		execute_cycle			= 0;
		inc_pc					= 0;
		alu_halt				= 0;
		alu_requested_halt		= 0;
		$display("should be initializing registers");
		hex_dec 				= `MODE_HEX;
		PC 						= 0;
		new_PC					= 0;
		next_PC					= 0;
		inst_start_PC			= 0;
		rstk_ptr				= 7;

		// $monitor("rst %b | CLK %b | CLK2 %b | CLK3 %b | PH0 %b | PH1 %b | PH2 %b | PH3 %b | CTR %d | EBCLK %b| STRB %b  | BLPC %b | bnbi %b | bnbo %b | nb %b ",
		// 		 reset, clk, clk2, clk3, ph0, ph1, ph2, ph3, cycle_ctr, en_bus_clk, strobe, bus_load_pc, bus_nibble_in, bus_nibble_out, nibble);
		// $monitor("CTR %d | EBCLK %b| B_STRB %b  | EDCLK %b | D_STRB %b | BLPC %b | bnbi %b | bnbo %b | nb %b ",
		// 		 cycle_ctr, en_bus_clk, bus_strobe, en_dec_clk, dec_strobe, bus_load_pc, bus_nibble_in, bus_nibble_out, nibble);
		// $monitor("BLPC %b | EBLPC %b",
		// 		 bus_load_pc, en_bus_load_pc);
		//$monitor("NC %h", next_cycle);
	end

//--------------------------------------------------------------------------------------------------
//
// clock generation
//
//--------------------------------------------------------------------------------------------------

always @(posedge clk)
	if (!reset) clk2 <= !clk2;

always @(negedge clk)
	clk3 <= !clk3 | reset;

assign bus_ctrl_clk = clk & !reset;
assign ph0 =  clk &  clk3 & !reset;
assign ph1 = !clk & !clk2 & !reset;
assign ph2 =  clk & !clk3 & !reset;
assign ph3 = !clk &  clk2 & !reset; 
assign bus_strobe = ph1 & en_bus_clk;
assign dec_strobe = ph3 & en_dec_clk;

//--------------------------------------------------------------------------------------------------
//
// bus control
//
//--------------------------------------------------------------------------------------------------

`include "fields.v"
// `include "bus_commands.v"

always @(posedge bus_ctrl_clk)
begin
	if (!reset) begin
		if (clk3) begin
			en_dec_clk <= 0;
			cycle_ctr <= cycle_ctr + 1;
			case (next_cycle)
			`BUSCMD_NOP: begin
				bus_command <= `BUSCMD_NOP;
				$display("BUS NOT READING, STILL CLOCKING");
			end
			`BUSCMD_PC_READ: begin
				bus_command <= `BUSCMD_PC_READ;
				en_bus_clk <= 1;
				PC <= next_PC;
				inc_pc <= 1;
			end
			`BUSCMD_DP_READ: begin
				bus_command <= `BUSCMD_DP_READ;
				en_bus_clk <= 1;
			end
			`BUSCMD_DP_WRITE: begin
				bus_command <= `BUSCMD_DP_WRITE;
				bus_nibble_in <= nb_out;
				en_bus_clk <= 1;
			end
			`BUSCMD_LOAD_PC: begin
				bus_command <= `BUSCMD_LOAD_PC;
				bus_address <= new_PC;
				next_PC <= new_PC;
				PC <= new_PC;
				en_bus_clk <= 1;
			end
			`BUSCMD_LOAD_DP: begin
				bus_command <= `BUSCMD_LOAD_DP;
				bus_address <= add_out;
				en_bus_clk <= 1;
			end
			`BUSCMD_CONFIGURE: begin
				bus_command <= `BUSCMD_CONFIGURE;
				bus_address <= add_out;
				en_bus_clk <= 1;
			end
			`BUSCMD_RESET: begin
				bus_command <= `BUSCMD_RESET;
				en_bus_clk <= 1;
			end
			default: begin
				$display("BUS PHASE 1: %h UNIMPLEMENTED", next_cycle);
			end
			endcase
		end
		else begin
			case (next_cycle)
			`BUSCMD_NOP: begin
				en_dec_clk <= 1;
			end
			`BUSCMD_PC_READ: begin
				nb_in <= bus_nibble_out;
				en_dec_clk <= 1;
				if (inc_pc) begin
					next_PC <= PC + 1;
					inc_pc <= 0;
				end
				// $display("reading nibble %h", bus_nibble_out);
			end
			`BUSCMD_DP_READ: begin
				nb_in <= bus_nibble_out;
				en_dec_clk <= 1;
			end
			`BUSCMD_DP_WRITE: begin
				// $display("BUS PHASE 2: DP_WRITE cnt %h | ctr %h", t_cnt, t_ctr);
				en_dec_clk <= 1;
			end
			`BUSCMD_LOAD_PC: begin
				$display("CYCLE %d | INSTR %d -> BUSCMD_LOAD_PC %5h", cycle_ctr, instr_ctr, new_PC);
				en_dec_clk <= 1;
			end
			`BUSCMD_LOAD_DP: begin
				$display("CYCLE %d | INSTR %d -> BUSCMD_LOAD_DP %s %5h", 
						 cycle_ctr, instr_ctr, t_ptr?"D1":"D0", add_out);
				en_dec_clk <= 1;
			end
			`BUSCMD_CONFIGURE: begin
				$display("CYCLE %d | INSTR %d -> BUSCMD_CONFIGURE %5h", cycle_ctr, instr_ctr, add_out); 
				en_dec_clk <= 1;
			end
			`BUSCMD_RESET: begin
				$display("CYCLE %d | INSTR %d -> BUSCMD_RESET", cycle_ctr, instr_ctr); 
				en_dec_clk <= 1;
			end
			default: begin
				$display("BUS PHASE 2: %h UNIMPLEMENTED", next_cycle);
			end
			endcase
			en_bus_clk <= 0;
		end
	end
	else begin
		$display("RESET");
	end
end

always @(posedge ph1)
	begin
	end

always @(posedge ph2) begin
`include "decstates.v"
`include "opcodes/z_alu_phase_2.v"
end

always @(posedge ph3) begin
	if (cycle_ctr == 260)
		debug_stop <= 1;
end

//--------------------------------------------------------------------------------------------------
//
// instruction decoder
//
//--------------------------------------------------------------------------------------------------

`include "decstates.v"

always @(posedge dec_strobe) begin
	if (alu_requested_halt) decode_error <= 1;
	if ((next_cycle == `BUSCMD_LOAD_PC)|
		(next_cycle == `BUSCMD_CONFIGURE)|
		(next_cycle == `BUSCMD_RESET)|
		((next_cycle == `BUSCMD_NOP)&
		 (decstate == `DEC_START))) begin
		$display("SETTING next_cycle to BUSCMD_PC_READ");
		next_cycle <= `BUSCMD_PC_READ;
	end else begin
`ifdef SIM
		if ((decstate == `DEC_START)|(decstate == `DEC_TEST_GO)) begin
			// display registers
			$display("PC: %05h               Carry: %b h: %s rp: %h   RSTK7: %05h", PC, Carry, hex_dec?"DEC":"HEX", rstk_ptr, RSTK[7]);
			$display("P:  %h  HST: %b        ST:  %b   RSTK6: %5h", P, HST, ST, RSTK[6]);
			$display("A:  %h    R0:  %h   RSTK5: %5h", A, R0, RSTK[5]);
			$display("B:  %h    R1:  %h   RSTK4: %5h", B, R1, RSTK[4]);
			$display("C:  %h    R2:  %h   RSTK3: %5h", C, R2, RSTK[3]);
			$display("D:  %h    R3:  %h   RSTK2: %5h", D, R3, RSTK[2]);
			$display("D0: %h  D1: %h    R4:  %h   RSTK1: %5h", D0, D1, R4, RSTK[1]);
			$display("                                                RSTK0: %5h", RSTK[0]);
		end
`endif
		$display("CYCLE %d | NEXTC %h | INSTR %d | PC %h | DECSTATE %3h | NIBBLE %h", 
				cycle_ctr, next_cycle,
				(decstate == `DEC_START)?instr_ctr+1:instr_ctr, 
				PC, decstate, nb_in);
		case (decstate)
		`DEC_START:	begin
			instr_ctr <= instr_ctr + 1;
			inst_start_PC <= PC;
			case (nb_in)
			4'h0: decstate <= `DEC_0X;
			4'h1: decstate <= `DEC_1X;
			4'h2: decstate <= `DEC_P_EQ_N;
			4'h3: decstate <= `DEC_LC_LEN;
			4'h6: decstate <= `DEC_GOTO;
			4'h7: decstate <= `DEC_GOSUB;
			4'h8: decstate <= `DEC_8X;
			4'hA: begin
				fields_return <= `DEC_Axx_EXEC;
				decstate <= `DEC_ab_FIELDS;
			end
			4'hB: begin
				fields_return <= `DEC_Bxx_EXEC;
				decstate <= `DEC_ab_FIELDS;
			end
			4'hC: decstate <= `DEC_CX;
			4'hD: decstate <= `DEC_DX;
			4'hF: decstate <= `DEC_FX;
			default: begin 
				$display("ERROR : DEC_START");
				decode_error <= 1;
			end
			endcase
		end
`include "opcodes/0x.v"
`include "opcodes/1x.v"
`include "opcodes/13x_ptr_and_AC.v"
`include "opcodes/1[45]_memaccess.v"
`include "opcodes/1[678C]n_D[01]_math_n.v"
`include "opcodes/1[ABEF]nnnnn_D[01]_EQ_5n.v"
`include "opcodes/2n_P_EQ_n.v"
`include "opcodes/3n[x...]_LC.v"
`include "opcodes/6xxx_GOTO.v"
`include "opcodes/7xxx_GOSUB.v"
`include "opcodes/8x.v"
`include "opcodes/80x.v"
`include "opcodes/808x.v"
`include "opcodes/808[4-B]_[AC]BIT_set_test.v"
`include "opcodes/80[CD]n_C_and_P_n.v"
`include "opcodes/82x_CLRHST.v"
`include "opcodes/8[4567]n_work_test_ST.v"
`include "opcodes/8[89]n_test_P.v"
`include "opcodes/8Ax_test_[n]eq_A.v"
`include "opcodes/8[DF]xxxxx_GO.v"
`include "opcodes/A[ab]x.v"
`include "opcodes/B[ab]x.v"
`include "opcodes/Cx.v"
`include "opcodes/Dx_regs_field_A.v"
`include "opcodes/Fx.v"
`include "opcodes/xx_RTNYES_GOYES.v"

`include "opcodes/z_alu_phase_3.v"
`include "opcodes/z_fields.v"
		default: begin
			$display("ERROR : GENERAL");
			decode_error <= 1;
		end
		endcase
	end
end

//--------------------------------------------------------------------------------------------------
//
// dump all registers on leds
//
//--------------------------------------------------------------------------------------------------

`ifndef SIM

`define REGDMP_HEX	0


always @(negedge clk)
begin
	case (regdump)
		`REGDMP_HEX:	led <= {7'b0000000, hex_dec};
		default: led <= 8'b11111111;
	endcase
	regdump <= regdump + 1;

	if (reset)
		regdump <= `REGDMP_HEX;
end	
`endif

assign halt = bus_error | decode_error | debug_stop;


// Verilator lint_off UNUSED
//wire [N-1:0] unused;
//assign unused = { }; 
// Verilator lint_on UNUSED
endmodule

`ifdef SIM

module saturn_tb;
reg			clk;
reg			reset;
wire		halt;
wire [3:0]	busstate;
wire [11:0]	decstate;

saturn_core saturn (
	.clk		(clk),
	.reset		(reset),
	.halt		(halt),
	.busstate	(busstate),
	.decstate	(decstate)
);

always 
    #10 clk = (clk === 1'b0);

initial begin
	//$monitor ("c %b | r %b | run %h | dec %h", clk, reset, runstate, decstate);
end 

initial begin
	$display("starting the simulation");
	clk <= 0;
	reset <= 1;
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	reset <= 0;
	@(posedge halt);
	$finish;
end		


endmodule

`else


`endif