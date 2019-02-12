/*
 * Licence: GPLv3 or later
 */

`default_nettype none //

// `include "bus_commands.v"
// `include "hp48_00_bus.v"
// `include "dbg_module.v"
`include "saturn-decoder.v"
`include "saturn-alu.v"

/**************************************************************************************************
 *
 *
 *
 *
 *
 */

`ifdef SIM
module saturn_core (
	input			    clk,
	input			    reset,
	output [0:0]  halt,
	output [3:0] 	busstate,
	output [11:0] decstate
);
`else
module saturn_core (
	input			    clk_25mhz,
	input  [6:0] 	btn,
	output [7:0]	led
);
wire 		clk;
wire 		reset;
reg			clk2;

assign clk			= clk_25mhz;
assign reset		= btn[1];

`endif

// clocks
reg	 [1:0]      clk_phase;
reg				en_reset;
reg				en_debugger;	// phase 0
reg				en_bus_send;	// phase 0
reg				en_bus_recv;	// phase 1
reg				en_alu_prep;	// phase 1
reg				en_alu_calc;	// phase 2
reg				en_inst_dec;	// phase 2
reg				en_alu_save;	// phase 3
reg				en_inst_exec;	// phase 3
reg				clock_end;
reg	 [31:0]	    cycle_ctr;
reg	 [31:0]     max_cycle;

// state machine stuff
wire			halt;


// hp48_bus bus_ctrl (
// 	.strobe			(bus_strobe),
// 	.reset			(reset),
// 	.address		(bus_address),
// 	.command		(bus_command),
// 	.nibble_in		(bus_nibble_in),
// 	.nibble_out		(bus_nibble_out),
// 	.bus_error		(bus_error)
// );

saturn_decoder	m_decoder (
	.i_clk			    (clk),
	.i_reset		    (reset),
	.i_cycles		    (cycle_ctr),
	.i_en_dbg       (en_debugger),
	.i_en_dec		    (en_inst_dec),
	.i_pc			      (reg_pc),
	.i_stalled      (stalled),
	.i_nibble		    (nibble_in),

	.i_reg_p        (reg_p),

	.o_inc_pc       (inc_pc),
	.o_dec_error    (inv_opcode),
     
  .o_ins_addr     (ins_addr),
  .o_ins_decoded  (ins_decoded),

  .o_fields_table (fields_table),
  .o_field        (field),
  .o_field_start  (field_start),
  .o_field_last   (field_last),

	.o_alu_op				(alu_op),

  .o_direction    (direction),
  .o_ins_rtn      (ins_rtn),
  .o_set_xm       (set_xm),
  .o_set_carry    (set_carry),
  .o_carry_val    (carry_val),
  .o_ins_set_mode (ins_set_mode),
	.o_mode_dec     (mode_dec)
);

wire            inc_pc;
wire            inv_opcode;

wire [19:0]     ins_addr;
wire            ins_decoded;

wire [1:0]      fields_table;
wire [3:0]      field;
wire [3:0]      field_start;
wire [3:0]      field_last;

wire [4:0]			alu_op;

wire            direction;
wire            ins_rtn;
wire            set_xm;
wire            set_carry;
wire            carry_val;
wire            ins_set_mode;
wire		        mode_dec;


saturn_alu		m_alu (
	.i_clk					(clk),
	.i_reset				(reset),
	.i_en_alu_prep	(en_alu_prep),
	.i_en_alu_calc	(en_alu_calc),
	.i_en_alu_save	(en_alu_save),

  .i_field_start  (field_start),
	.i_field_last   (field_last),

	.i_alu_op				(alu_op),

	.o_reg_p				(reg_p)
);


// interconnections

wire [3:0]		reg_p;

/*
 * test rom...
 */

reg [3:0] rom [0:1024];

initial
	begin
		$readmemh( "testrom.hex", rom);
		clk_phase 		= 0;
		en_debugger 	= 0;	// phase 0
		en_bus_send 	= 0;	// phase 0
		en_bus_recv 	= 0;	// phase 1
		en_alu_prep 	= 0;	// phase 1
		en_alu_calc 	= 0;	// phase 2
		en_inst_dec 	= 0;	// phase 2
		en_alu_save 	= 0;	// phase 3
		en_inst_exec	= 0;	// phase 3
		clock_end			= 0;
		cycle_ctr			= 0;
		reg_pc				= 0;

`ifdef DEBUG_CLOCKS
		$monitor("RST %b | CLK %b | CLKP %d | CYCL %d | eRST %b | eDBG %b | eBSND %b | eBRECV %b | eAPR %b | eACALC %b | eINDC %b | eASAVE %b | eINDX %b",
				 reset, clk, clk_phase, cycle_ctr, en_reset, 
				 en_debugger, en_bus_send,
				 en_bus_recv, en_alu_prep, 
				 en_alu_calc, en_inst_dec, 
				 en_alu_save, en_inst_exec);
`endif
	end

//--------------------------------------------------------------------------------------------------
//
// clock generation
//
//--------------------------------------------------------------------------------------------------

always @(posedge clk) begin
	if (!reset) begin
		clk_phase    <= clk_phase + 1;
		en_debugger  <= clk_phase[1:0] == 0;
		en_bus_send  <= clk_phase[1:0] == 0;
		en_bus_recv  <= clk_phase[1:0] == 1;
		en_alu_prep  <= clk_phase[1:0] == 1;
		en_alu_calc  <= clk_phase[1:0] == 2;
		en_inst_dec  <= clk_phase[1:0] == 2;
		en_alu_save  <= clk_phase[1:0] == 3;
		en_inst_exec <= clk_phase[1:0] == 3;
		cycle_ctr    <= cycle_ctr + (clk_phase[1:0] == 0);
		// stop after 50 clocks
		if (cycle_ctr == (max_cycle + 1))
			clock_end <= 1;
	end else begin
		clk_phase 	  <= ~0;
		en_debugger   <= 0;
		en_bus_send   <= 0;
		en_bus_recv   <= 0;
		en_alu_prep   <= 0;
		en_alu_calc   <= 0;
		en_inst_dec   <= 0;
		en_alu_save   <= 0;
		en_inst_exec  <= 0;
		clock_end	  <= 0;
		cycle_ctr	  <= ~0;
		max_cycle <= 1024;
`ifndef SIM
		led[7:0] <= reg_pc[7:0];
`endif
	end
end

//--------------------------------------------------------------------------------------------------
//
// test cases
//
//--------------------------------------------------------------------------------------------------

reg [3:0]   nibble_in;
reg [19:0]	reg_pc;
reg			    stalled;

always @(posedge clk)
  if (reset) begin
		reg_pc  <= ~0;
		stalled <= 0;
  end else begin
	if (en_bus_send) begin
		if (inc_pc & !stalled)
			reg_pc <= reg_pc + 1;
		`ifdef SIM
		else
			$write("\nnot incrementing PC");
		`endif
	end
	if (en_bus_recv) begin
		if (!stalled) begin
	`ifdef SIM
			$write("%h", rom[reg_pc]);
	`endif
			nibble_in <= rom[reg_pc];
		end
	end
	if (en_inst_exec) begin
		if (cycle_ctr == 5) stalled <= 1;
		if (cycle_ctr == 10) stalled <= 0;
	end
  end

assign halt = clock_end || inv_opcode;


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