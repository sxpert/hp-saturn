/*
 * Licence: GPLv3 or later
 */

`default_nettype none //

`include "bus_commands.v"
`include "hp48_bus.v"

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
	output [7:0] 	decstate
);
`else
module saturn_core (
	input			clk_25mhz,
	input [6:0] 	btn,
	output 			wifi_gpio0,
	output [7:0]	led
);
wire 		clk;
wire 		reset;
reg			clk2;

assign wifi_gpio0	= 1'b1;
assign clk			= clk_25mhz;
assign reset		= btn[1];

`endif

// data transfer constants

localparam T_DIR_OUT	= 0;
localparam T_DIR_IN		= 1;
localparam T_PTR_0		= 0;
localparam T_PTR_1		= 1;
localparam T_REG_A		= 0;
localparam T_REG_C		= 1;
localparam T_FIELD_P	= 0;
localparam T_FIELD_WP	= 1;
localparam T_FIELD_XS	= 2;
localparam T_FIELD_X	= 3;
localparam T_FIELD_S	= 4;
localparam T_FIELD_M	= 5;
localparam T_FIELD_B	= 6;
localparam T_FIELD_W	= 7;
localparam T_FIELD_LEN	= 13;
localparam T_FIELD_A	= 15;

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
reg				decode_error;
reg				debug_stop;
reg		[3:0]	busstate;

reg 			read_next_pc;
reg				execute_cycle;
reg				inc_pc;
reg 			read_nibble;
reg				first_nibble;

reg		[7:0]	decstate;
reg		[3:0]	regdump;

// bus access
reg		[19:0]	bus_address;
reg		[3:0]	bus_command;
reg		[3:0]	bus_nibble_in;
wire	[3:0]	bus_nibble_out;
wire			bus_error;
reg				bus_load_pc;

// should go away, the rom should work like any other bus module
reg				rom_enable;

// internal registers
reg	[3:0]	nibble;
reg [19:0]	new_PC;
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
reg	[3:0]	t_field;

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
		$display("initializing bus_command");
		bus_command				= `BUSCMD_NOP;
		$display("initializing busstate");
		busstate				= 0;
		$display("Initializing decstate");
		decstate				= 0;
		$display("initializing control bits");
		decode_error			= 0;
		debug_stop				= 0;
		bus_load_pc				= 1;
		read_next_pc			= 1;
		execute_cycle			= 0;
		inc_pc					= 0;
		$display("should be initializing registers");
		hex_dec 				= `MODE_HEX;
		PC 						= 0;
		new_PC					= 0;
		inst_start_PC			= 0;
		rstk_ptr				= 7;

		// $monitor("rst %b | CLK %b | CLK2 %b | CLK3 %b | PH0 %b | PH1 %b | PH2 %b | PH3 %b | CTR %d | EBCLK %b| STRB %b  | BLPC %b | bnbi %b | bnbo %b | nb %b ",
		// 		 reset, clk, clk2, clk3, ph0, ph1, ph2, ph3, cycle_ctr, en_bus_clk, strobe, bus_load_pc, bus_nibble_in, bus_nibble_out, nibble);
		// $monitor("CTR %d | EBCLK %b| B_STRB %b  | EDCLK %b | D_STRB %b | BLPC %b | bnbi %b | bnbo %b | nb %b ",
		// 		 cycle_ctr, en_bus_clk, bus_strobe, en_dec_clk, dec_strobe, bus_load_pc, bus_nibble_in, bus_nibble_out, nibble);
	end

//--------------------------------------------------------------------------------------------------
//
// clock generation
//
//--------------------------------------------------------------------------------------------------

always @(posedge clk)
	if (~reset) clk2 <= ~clk2;

always @(negedge clk)
	clk3 <= ~clk3 | reset;

assign bus_ctrl_clk = clk & ~reset;
assign ph0 =  clk &  clk3 & ~reset;
assign ph1 = ~clk & ~clk2 & ~reset;
assign ph2 =  clk & ~clk3 & ~reset;
assign ph3 = ~clk &  clk2 & ~reset; 
assign bus_strobe = ph1 & en_bus_clk;
assign dec_strobe = ph3 & en_dec_clk;

//--------------------------------------------------------------------------------------------------
//
// bus control
//
//--------------------------------------------------------------------------------------------------

`define INSTR_LOAD_PC	0
`define INSTR_READ_NBL 	1

always @(posedge bus_ctrl_clk)
begin
	if (~reset) begin
		if (clk3) begin
			en_dec_clk <= 0;
			cycle_ctr <= cycle_ctr + 1;
			if (bus_load_pc) begin
				bus_command <= `BUSCMD_LOAD_PC;
				bus_address <= new_PC;
				bus_load_pc <= 0;
				en_bus_clk <= 1;
				//$display(">>>> PC load newPC %5h", new_PC);
			end else begin
				if (read_next_pc&~execute_cycle) begin
					//$display("sending BUSCMD_PC_READ");
					bus_command <= `BUSCMD_PC_READ;
					read_nibble <= 1;
					en_bus_clk <= 1;
					PC <= new_PC;
					inc_pc <= 1;
				end else begin
					//$display(">>>> PC no change  %5h", PC);
					$display("BUS NOT READING, STILL CLOCKING");
				end
			end
		end
		else begin
			if (bus_command == `BUSCMD_LOAD_PC)
				$display("CYCLE %d -> BUSCMD_LOAD_PC %h", cycle_ctr, new_PC);
			if (read_next_pc&read_nibble) begin
				nibble <= bus_nibble_out;
				en_dec_clk <= 1;
				//$display("reading nibble %h", bus_nibble_out);
			end
			if (execute_cycle) begin
				en_dec_clk <= 1;	// PC does not change
			end 
			if (inc_pc) begin
				new_PC <= PC + 1;
				inc_pc <= 0;
				//$display(">>>> PC inc to     %5h", PC + 20'h1);
			end
			read_nibble <= 0;
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

always @(posedge ph2)
	begin
	end

always @(posedge ph3) begin
	if (cycle_ctr == 90)
		debug_stop <= 1;
end

//--------------------------------------------------------------------------------------------------
//
// instruction decoder
//
//--------------------------------------------------------------------------------------------------

`include "decstates.v"

always @(posedge dec_strobe) begin
`ifdef SIM
	if (decstate == `DEC_START) begin
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
	$display("CYCLE %d | PC %h | DECSTATE %d | NIBBLE %h", cycle_ctr, PC, decstate, nibble);
	case (decstate)
	`DEC_START:	begin
		inst_start_PC <= PC;
		case (nibble)
		4'h0: decstate <= `DEC_0X;
		4'h2: decstate <= `DEC_P_EQ_N;
		4'h3: decstate <= `DEC_LC_LEN;
		4'h6: decstate <= `DEC_GOTO;
		4'h8: decstate <= `DEC_8X;
		4'hB: decstate <= `DEC_BX; 
		default: begin 
		    $display("ERROR : DEC_START");
        	decode_error <= 1;
		end
		endcase
	end
`include "opcodes/0x.v"
// `include "opcodes/03_RTNCC.v"
//`include "opcodes/04_SETHEX.v"
`include "opcodes/05_SETDEC.v"
`include "opcodes/2n_P_EQ_n.v"
`include "opcodes/3n[x...]_LC.v"
`include "opcodes/6xxx_GOTO.v"
`include "opcodes/8x.v"
`include "opcodes/80x.v"
`include "opcodes/805_CONFIG.v"
`include "opcodes/80A_RESET.v"
`include "opcodes/80Cn_C_EQ_P_n.v"
`include "opcodes/82x_CLRHST.v"
`include "opcodes/8[45]n_ST_EQ_[01]_n.v"
`include "opcodes/8[DF]xxxxx_GO.v"
`include "opcodes/Bx_math_ops_shift.v"
	default: begin
        $display("ERROR : GENERAL");
        decode_error <= 1;
	end
	endcase
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
wire [7:0]	decstate;

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