/*
 * Licence: GPLv3 or later
 */

`default_nettype none //

// `include "bus_commands.v"
// `include "hp48_00_bus.v"
// `include "dbg_module.v"
`include "saturn-decoder.v"

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
	output [7:0]	led
);
wire 		clk;
wire 		reset;
reg			clk2;

assign clk			= clk_25mhz;
assign reset		= btn[1];

`endif

// clocks
reg		[1:0]	clk_phase;
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
reg		[31:0]	cycle_ctr;
reg	    [31:0]	max_cycle;

// state machine stuff
wire			halt;
wire [19:0]		reg_pc;
wire			dec_error;

// hp48_bus bus_ctrl (
// 	.strobe			(bus_strobe),
// 	.reset			(reset),
// 	.address		(bus_address),
// 	.command		(bus_command),
// 	.nibble_in		(bus_nibble_in),
// 	.nibble_out		(bus_nibble_out),
// 	.bus_error		(bus_error)
// );

saturn_decoder i_decoder (
	.i_clk			(clk),
	.i_reset		(reset),
	.i_cycles		(cycle_ctr),
	.i_en_dbg   	(en_debugger),
	.i_en_dec		(en_inst_dec),
	.i_en_exec  	(en_inst_exec),
	// .i_stalled	(stalled),
	.i_nibble		(nibble_in),
	.o_pc			(reg_pc),
	.o_dec_error	(dec_error)
);

initial
	begin
		clk_phase 				= 0;
		en_debugger 			= 0;	// phase 0
		en_bus_send 			= 0;	// phase 0
		en_bus_recv 			= 0;	// phase 1
		en_alu_prep 			= 0;	// phase 1
		en_alu_calc 			= 0;	// phase 2
		en_inst_dec 			= 0;	// phase 2
		en_alu_save 			= 0;	// phase 3
		en_inst_exec			= 0;	// phase 3
		clock_end				= 0;
		cycle_ctr				= 0;

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
		max_cycle <= 50;
`ifndef SIM
		led[7:0] <= reg_pc[7:0];
`endif
	end
end

// always @(posedge clk) 
// 	if (en_debugger)
// 		$display(cycle_ctr);

reg [3:0] nibble_in;

always @(posedge clk)
	if (en_bus_recv)
		case (cycle_ctr)
		// RTNSXM
		0:	nibble_in <= 0;
		1:  nibble_in <= 0;
		// RTN
		2:  nibble_in <= 0;
		3:  nibble_in <= 1;
		// RTNSC
		4:  nibble_in <= 0;
		5:  nibble_in <= 2;
		// RTNCC
		6:  nibble_in <= 0;
		7:  nibble_in <= 3;
		// SETHEX
		8:  nibble_in <= 0;
		9:  nibble_in <= 4;
		// END
		50:  clock_end <= 1;
		endcase

assign halt = clock_end || dec_error;


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