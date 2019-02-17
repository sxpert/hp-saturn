/*
 * Licence: GPLv3 or later
 */

`default_nettype none //

`include "def-clocks.v"
// `include "bus_commands.v"
// `include "hp48_00_bus.v"
// `include "dbg_module.v"
`include "saturn_decoder.v"
`include "saturn_alu.v"
`include "saturn_bus_ctrl.v"

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

assign clk			= clk_25mhz;
assign reset		= btn[1];

`endif

// clocks
reg	[1:0]  clk_phase;
reg	[0:0]  en_reset;

reg	[0:0]	 ck_debugger;	 // phase 0

reg	[0:0]	 ck_bus_send;	 // phase 0
reg	[0:0]	 ck_bus_recv;	 // phase 1
reg [0:0]  ck_bus_ecmd;  // phase 3

reg	[0:0]	 ck_inst_dec;	 // phase 2
reg [0:0]  ck_inst_exe;  // phase 3

reg	[0:0]	 ck_alu_dump;	 // phase 0
reg	[0:0]	 ck_alu_init;	 // phase 3
reg	[0:0]	 ck_alu_prep;	 // phase 1
reg	[0:0]	 ck_alu_calc;	 // phase 2
reg	[0:0]	 ck_alu_save;	 // phase 3

reg	[0:0]	 clock_end;
reg	[31:0] cycle_ctr;
reg	[31:0] max_cycle;

// state machine stuff
wire [0:0] halt;


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
	.i_en_dbg       (ck_debugger),
	.i_en_dec		    (ck_inst_dec),
	.i_pc			      (reg_pc),
	.i_bus_load_pc  (bus_load_pc),
	.i_stalled      (dec_stalled),
	.i_nibble		    (bus_nibble_in),

	.i_reg_p        (reg_p),

	.o_inc_pc       (inc_pc),
  .o_push					(push),
  .o_pop					(pop),
	.o_dec_error    (inv_opcode),
	.o_alu_debug		(alu_debug),
     
  .o_ins_addr     (ins_addr),
  .o_ins_decoded  (ins_decoded),

  .o_fields_table (fields_table),
  .o_field        (field),
  .o_field_start  (field_start),
  .o_field_last   (field_last),
	.o_imm_value    (imm_value),

	.o_alu_op				(alu_op),
	.o_alu_no_stall (alu_no_stall),
	.o_reg_dest			(reg_dest),
	.o_reg_src1			(reg_src1),
	.o_reg_src2			(reg_src2),

  .o_ins_rtn      (ins_rtn),
  .o_set_xm       (set_xm),
  .o_set_carry    (set_carry),
  .o_carry_val    (carry_val),
  .o_ins_set_mode (ins_set_mode),
	.o_mode_dec     (mode_dec),
  .o_ins_alu_op		(ins_alu_op),
	.o_ins_test_go  (ins_test_go),
	.o_ins_reset		(ins_reset),
	.o_ins_config   (ins_config)
);

wire [0:0]      inc_pc;
wire [0:0]			push;
wire [0:0]			pop;
wire [0:0]      inv_opcode;
wire [0:0]		  alu_debug;

wire [19:0]     ins_addr;
wire [0:0]      ins_decoded;

wire [1:0]      fields_table;
wire [3:0]      field;
wire [3:0]      field_start;
wire [3:0]      field_last;
wire [3:0]			imm_value;

wire [4:0]			alu_op;
wire [0:0]			alu_no_stall;
wire [4:0]			reg_dest;
wire [4:0]			reg_src1;
wire [4:0]			reg_src2;

wire [0:0]      ins_rtn;
wire [0:0]      set_xm;
wire [0:0]      set_carry;
wire [0:0]      carry_val;
wire [0:0]      ins_set_mode;
wire [0:0]      mode_dec;
wire [0:0]      ins_alu_op;
wire [0:0]      ins_test_go;
wire [0:0]      ins_reset;
wire [0:0]      ins_config;
wire [0:0]      ins_unconfig;


saturn_alu		m_alu (
	.i_clk					 (clk),
	.i_reset				 (reset),
	.i_cycle_ctr     (cycle_ctr),
	.i_en_alu_dump   (ck_alu_dump),
	.i_en_alu_prep	 (ck_alu_prep),
	.i_en_alu_calc	 (ck_alu_calc),
	.i_en_alu_init   (ck_alu_init),
	.i_en_alu_save 	 (ck_alu_save),
	.i_stalled			 (alu_stalled),

	.o_bus_address    (bus_address),
	.o_bus_load_pc    (bus_load_pc),
	.o_bus_load_dp    (bus_load_dp),
	.o_bus_pc_read    (bus_pc_read),
	.o_bus_dp_write   (bus_dp_write),
	.o_bus_config			(bus_config),
	.o_bus_nibble_out (bus_nibble_out),

	.i_push					 (push),
	.i_pop					 (pop),
	.i_alu_debug		 (alu_debug),

  .o_alu_stall_dec (alu_stalls_dec),
	.i_ins_decoded   (ins_decoded),

  .i_field_start   (field_start),
	.i_field_last    (field_last),
	.i_imm_value     (imm_value),

	.i_alu_op			 	 (alu_op),
	.i_alu_no_stall  (alu_no_stall),
	.i_reg_dest			 (reg_dest),
	.i_reg_src1			 (reg_src1),
	.i_reg_src2			 (reg_src2),

  .i_ins_alu_op		 (ins_alu_op),
	.i_ins_test_go	 (ins_test_go),
	.i_ins_set_mode	 (ins_set_mode),
	.i_ins_rtn			 (ins_rtn),
	.i_ins_config    (ins_config),
	.i_ins_unconfig  (ins_unconfig),

  .i_mode_dec			 (mode_dec),
  .i_set_xm        (set_xm),
  .i_set_carry     (set_carry),
  .i_carry_val     (carry_val),
	
	.o_reg_p				 (reg_p),
	.o_pc			       (reg_pc)
);


// interconnections
wire [19:0]   bus_address;
wire [0:0]    bus_load_pc;
wire [0:0]    bus_load_dp;
wire [0:0]    bus_pc_read;
wire [0:0]    bus_dp_write;
wire [0:0]    bus_config;

wire [3:0]    bus_nibble_in;
wire [3:0]    bus_nibble_out;

wire [0:0]    alu_stalls_dec;
wire [3:0]		reg_p;
wire [19:0]		reg_pc;

/*
 *
 * Bus controller module
 *
 */

saturn_bus_ctrl m_bus_ctrl (
  // basic stuff
	.i_clk              (clk),
  .i_reset            (reset),
	.i_cycle_ctr        (cycle_ctr),
  .i_en_bus_send      (ck_bus_send),
  .i_en_bus_recv      (ck_bus_recv),
	.i_en_bus_ecmd		  (ck_bus_ecmd),
  .i_stalled          (mem_ctrl_stall),
	.i_read_stall       (dec_stalled),
  .o_stalled_by_bus   (bus_stalls_core),

  //bus i/o
  .i_bus_data         (bus_data_in),
  .o_bus_data         (bus_data_out),
  .o_bus_strobe       (bus_strobe),
  .o_bus_cmd_data     (bus_cmd_data),

  // interface to the rest of the machine
	.i_alu_pc           (reg_pc),
  .i_address          (bus_address),
  .i_load_pc          (bus_load_pc),
  .i_cmd_load_dp      (bus_load_dp),
	.i_read_pc					(bus_pc_read),
	.i_cmd_dp_write		  (bus_dp_write),
	.i_cmd_reset        (ins_reset),
	.i_cmd_config			  (bus_config),
  .i_nibble           (bus_nibble_out),
  .o_nibble           (bus_nibble_in)
);

reg  [0:0] mem_ctrl_stall;
wire [0:0] bus_stalls_core;

reg  [3:0] bus_data_in;
wire [3:0] bus_data_out;
wire [0:0] bus_strobe;
wire [0:0] bus_cmd_data;

// `define DEBUG_CLOCKS

initial	begin
		clk_phase 		= 0;

		ck_debugger 	= 0;	// phase 0

		ck_bus_send 	= 0;	// phase 0
		ck_bus_recv 	= 0;	// phase 1
		ck_bus_ecmd   = 0;  // phase 3

		ck_inst_dec 	= 0;	// phase 2
		ck_inst_exe   = 0;  // phase 3

		ck_alu_dump   = 0;
		ck_alu_prep 	= 0;	// phase 1
		ck_alu_calc 	= 0;	// phase 2
		ck_alu_init   = 0;  // phase 0
		ck_alu_save 	= 0;	// phase 3

		clock_end			= 0;
		cycle_ctr			= 0;

		mem_ctrl_stall = 0;

`ifdef DEBUG_CLOCKS
		$monitor("RST %b | CLK %b | CLKP %d | CYCL %d | PC %5h | eRST %b | eDBG %b | eBSND %b | eBRECV %b | eAPR %b | eACALC %b | eINDC %b | eASAVE %b | eINDX %b",
				 reset, clk, clk_phase, cycle_ctr, reg_pc, en_reset, 
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
		ck_debugger  <= clk_phase[1:0] == `PH_DEBUGGER;

		ck_bus_send  <= clk_phase[1:0] == `PH_BUS_SEND;
		ck_bus_recv  <= clk_phase[1:0] == `PH_BUS_RECV;
		ck_bus_ecmd  <= clk_phase[1:0] == `PH_BUS_ECMD;

		ck_inst_dec  <= clk_phase[1:0] == `PH_INST_DEC;
		ck_inst_exe  <= clk_phase[1:0] == `PH_INST_EXE;

		ck_alu_dump  <= clk_phase[1:0] == `PH_ALU_DUMP;
		ck_alu_init  <= clk_phase[1:0] == `PH_ALU_INIT;
		ck_alu_prep  <= clk_phase[1:0] == `PH_ALU_PREP;
		ck_alu_calc  <= clk_phase[1:0] == `PH_ALU_CALC;
		ck_alu_save  <= clk_phase[1:0] == `PH_ALU_SAVE;

		cycle_ctr    <= cycle_ctr + { {31{1'b0}}, (clk_phase[1:0] == `PH_BUS_SEND) };
		if (cycle_ctr == (max_cycle + 1)) begin
		  $display(".-----------------------------.");
			$display("|   OUT OF CYCLES %d  |", cycle_ctr);
			$display("`-----------------------------´");
			clock_end <= 1;
		end
	end else begin
		clk_phase 	  <= ~0;

		ck_debugger   <= 0;

		ck_bus_send   <= 0;
		ck_bus_recv   <= 0;
		ck_bus_ecmd   <= 0;

		ck_inst_dec   <= 0;
		ck_inst_exe   <= 0;

		ck_alu_dump   <= 0;
		ck_alu_init   <= 0;
		ck_alu_prep   <= 0;
		ck_alu_calc   <= 0;
		ck_alu_save   <= 0;

		clock_end	    <= 0;
		cycle_ctr	    <= ~0;
		max_cycle     <= 170;

		mem_ctrl_stall <= 0;
`ifndef SIM
		led[7:0]      <= reg_pc[7:0];
`endif
	end
end

//--------------------------------------------------------------------------------------------------
//
// test cases
//
//--------------------------------------------------------------------------------------------------

wire	 dec_stalled;
wire	 alu_stalled;
assign dec_stalled = alu_stalls_dec || bus_stalls_core;
assign alu_stalled = bus_stalls_core;

wire   read_nibble_to_dec;
assign read_nibble_to_dec = ck_bus_recv && !dec_stalled;
wire   dec_stalled_no_read;
assign dec_stalled_no_read = ck_bus_recv && !bus_stalls_core && dec_stalled;
wire   bus_is_stalled;
assign bus_is_stalled = ck_bus_recv && bus_stalls_core;

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

`endif
