/*
 * Licence: GPLv3 or later
 */

`default_nettype none //

`include "bus_commands.v"
`include "hp48_00_bus.v"
`include "dbg_module.v"

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

// clocks
reg		[1:0]	clk_phase;
reg				en_debugger;	// phase 0
reg				en_bus_send;	// phase 0
reg				en_bus_recv;	// phase 1
reg				en_alu_prep;	// phase 1
reg				en_alu_calc;	// phase 2
reg				en_inst_dec;	// phase 2
reg				en_qlu_save;	// phase 3
reg				en_inst_exec;	// phase 3

// state machine stuff
wire			halt;
reg				cycle_ctr_ready;
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

reg [4:0]	alu_op;
reg [3:0]	alu_first;
reg [3:0]	alu_last;
reg [3:0]	alu_const;
reg [3:0]	alu_reg_src1;
reg [3:0]	alu_reg_src2;
reg [3:0]	alu_reg_dest;

reg [3:0]	alu_src1;
reg [3:0]	alu_src2;
reg [3:0]	alu_res1;
reg [3:0]	alu_res2;
reg			alu_res_carry;
reg [3:0]	alu_tmp;
reg			alu_carry;
reg			alu_debug;
reg			alu_p1_halt;
reg			alu_p2_halt;
reg			alu_halt;
reg			alu_requested_halt;
reg	[11:0]	alu_return;
reg	[3:0]	alu_next_cycle;

// debugger registers
reg [19:0]	dbg_op_addr;
reg [15:0]	dbg_op_code;
reg [3:0]	dbg_reg_dest;
reg [3:0]	dbg_reg_src1;
reg [3:0]	dbg_reg_src2;
reg [3:0]	dbg_field;
reg [3:0]	dbg_first;
reg [3:0]	dbg_last;
reg [63:0]	dbg_data;

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
		clk_phase 				= 0;
		$display("initialize cycle counter");
		cycle_ctr_ready			= 0;
		cycle_ctr				= 0;
		instr_ctr				= 0;
		$display("initializing debugger");
		dbg_op_code				= 0;
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
		alu_p1_halt				= 0;
		alu_p2_halt             = 0;
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

always @(posedge clk) begin
	if (!reset) begin
		clk_phase <= clk_phase + 1;
		en_debugger  <= clk_phase == 0;
		en_bus_send  <= clk_phase == 0;
		en_bus_recv  <= clk_phase == 1;
		en_alu_prep  <= clk_phase == 1;
		en_alu_calc  <= clk_phase == 2;
		en_inst_dec  <= clk_phase == 2;
		en_alu_save  <= clk_phase == 3;
		en_inst_exec <= clk_phase == 3;
	end
end

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
			if (cycle_ctr_ready)
				cycle_ctr <= cycle_ctr + 1;
			else cycle_ctr_ready <= 1;
			case (next_cycle)
			`BUSCMD_NOP: begin
				bus_command <= `BUSCMD_NOP;
				// $display("BUS NOT READING, STILL CLOCKING");
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
				// $display("CYCLE %d | INSTR %d -> BUSCMD_LOAD_PC %5h", cycle_ctr, instr_ctr, new_PC);
				en_dec_clk <= 1;
			end
			`BUSCMD_LOAD_DP: begin
				// $display("CYCLE %d | INSTR %d -> BUSCMD_LOAD_DP %s %5h", 
				// 		 cycle_ctr, instr_ctr, t_ptr?"D1":"D0", add_out);
				en_dec_clk <= 1;
			end
			`BUSCMD_CONFIGURE: begin
				// $display("CYCLE %d | INSTR %d -> BUSCMD_CONFIGURE %5h", cycle_ctr, instr_ctr, add_out); 
				en_dec_clk <= 1;
			end
			`BUSCMD_RESET: begin
				// $display("CYCLE %d | INSTR %d -> BUSCMD_RESET", cycle_ctr, instr_ctr); 
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

// always @(posedge ph0) begin
// 	if (dbg_op_code)
// 		case (dbg_op_code)
// 		default: begin
// `ifdef SIM
// 			$display("DEBUGGER - UNKNOWN OPCODE: %4h", dbg_op_code);
// `endif
// 		end
// 		endcase
// `ifdef SIM
// 	else $display("DEBUGGER - NOTHING TO DO");
// `endif
// end

// always @(posedge ph1) begin
// `include "opcodes/z_alu_phase_1.v"
// end

// always @(posedge ph2) begin
// `include "opcodes/z_alu_phase_2.v"
// end

// always @(posedge ph3) begin
// 	if (cycle_ctr == 890)
// 		debug_stop <= 1;
// end


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