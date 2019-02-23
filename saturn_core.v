/*
    (c) Raphaël Jacquot 2019
    
		This file is part of hp_saturn.

    hp_saturn is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    any later version.

    hp_saturn is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar.  If not, see <https://www.gnu.org/licenses/>.

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
	i_clk,
	i_reset,
	o_halt,
	
	o_bus_reset,
  i_bus_data_in,
  o_bus_data_out,
  o_bus_strobe,
  o_bus_cmd_data,

	o_phase
);

input  wire [0:0] i_clk;
input  wire [0:0] i_reset;
output wire [0:0] o_halt;

`else
module saturn_core (
	clk_25mhz,
	btn,
	led,

	o_bus_reset,
  i_bus_data_in,
  o_bus_data_out,
  o_bus_strobe,
  o_bus_cmd_data,

	o_phase
);

input wire [0:0] clk_25mhz;
input wire [6:0] btn;
output reg [7:0] led;

wire [0:0] i_clk;
wire [0:0] i_reset;

assign i_clk	 = clk_25mhz;
assign i_reset = btn[1];

`endif

output wire [1:0] o_phase;

assign o_phase = clk_phase + 3;

output wire [0:0] o_bus_reset;
input  wire [3:0] i_bus_data_in;
output wire [3:0] o_bus_data_out;
output wire [0:0] o_bus_strobe;
output wire [0:0] o_bus_cmd_data;


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
	.i_clk			    (i_clk),
	.i_reset		    (i_reset),
	.i_cycles		    (cycle_ctr),
	.i_en_dbg       (phase_0),
	.i_en_dec		    (phase_2),
	.i_pc			      (reg_pc),
	.i_bus_load_pc  (alu_bus_load_pc),
	.i_stalled      (dec_stalled),
	.i_nibble		    (ctrl_bus_nibble_in),

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
	.o_test_carry   (test_carry),
  .o_carry_val    (carry_val),
  .o_ins_set_mode (ins_set_mode),
	.o_mode_dec     (mode_dec),
  .o_ins_alu_op		(ins_alu_op),
	.o_ins_test_go  (ins_test_go),
	.o_ins_reset		(ins_reset),
	.o_ins_config   (ins_config),
  .o_ins_mem_xfr  (ins_mem_xfr),
	.o_xfr_dir_out  (xfr_dir_out)
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
wire [0:0]      test_carry;
wire [0:0]      carry_val;
wire [0:0]      ins_set_mode;
wire [0:0]      mode_dec;
wire [0:0]      ins_alu_op;
wire [0:0]      ins_test_go;
wire [0:0]      ins_reset;
wire [0:0]      ins_config;
wire [0:0]      ins_mem_xfr;
wire [0:0]      xfr_dir_out;
wire [0:0]      ins_unconfig;


saturn_alu		m_alu (
	.i_clk					 (i_clk),
	.i_reset				 (i_reset),
	.i_phases        (clk_phases),
	.i_cycle_ctr     (cycle_ctr),
	.i_stalled			 (alu_stalled),

	.o_bus_address    (alu_bus_address),
	.i_bus_data_ptr		(ctrl_bus_data_ptr),
	.o_bus_data_nibl  (alu_bus_data_nibl),
	.o_bus_xfr_cnt		(alu_bus_xfr_cnt),
	.i_bus_nibble_in  (ctrl_bus_nibble_in),
	.o_bus_nibble_out (alu_bus_nibble_out),

	.o_bus_load_pc    (alu_bus_load_pc),
	.o_bus_load_dp    (alu_bus_load_dp),
	.o_bus_pc_read    (alu_bus_pc_read),
	.o_bus_dp_read    (alu_bus_dp_read),
	.o_bus_dp_write   (alu_bus_dp_write),
	.o_bus_config			(alu_bus_config),
	.i_bus_done				(ctrl_bus_done),

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
	.i_ins_mem_xfr   (ins_mem_xfr),
	.i_xfr_dir_out   (xfr_dir_out),
	.i_ins_unconfig  (ins_unconfig),

  .i_mode_dec			 (mode_dec),
  .i_set_xm        (set_xm),
  .i_set_carry     (set_carry),
	.i_test_carry		 (test_carry),
  .i_carry_val     (carry_val),
	
	.o_reg_p				 (reg_p),
	.o_pc			       (reg_pc)
);


// interconnections
wire [19:0]   alu_bus_address;
wire [3:0]    alu_bus_data_nibl;
wire [3:0]    alu_bus_xfr_cnt;
wire [0:0]    alu_bus_pc_read;
wire [0:0]    alu_bus_dp_read;
wire [0:0]    alu_bus_dp_write;
wire [0:0]    alu_bus_load_pc;
wire [0:0]    alu_bus_load_dp;
wire [0:0]    alu_bus_config;

wire [3:0]    alu_bus_nibble_out;

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
	.i_clk              (i_clk),
  .i_reset            (i_reset),
	.i_phases           (clk_phases),
	.i_cycle_ctr        (cycle_ctr),
  .i_stalled          (mem_ctrl_stall),
	.i_alu_busy         (dec_stalled),

  .o_stall_alu        (bus_stalls_core),
	.o_bus_done					(ctrl_bus_done),

  //bus i/o
	.o_bus_reset        (o_bus_reset),
  .i_bus_data         (i_bus_data_in), 
  .o_bus_data         (o_bus_data_out),
  .o_bus_strobe       (o_bus_strobe),
  .o_bus_cmd_data     (o_bus_cmd_data),

  // interface to the rest of the machine
	.i_alu_pc           (reg_pc),
  .i_address          (alu_bus_address),
	.i_data_nibl				(alu_bus_data_nibl),
	.o_data_ptr					(ctrl_bus_data_ptr),
  .i_cmd_load_pc      (alu_bus_load_pc),
  .i_cmd_load_dp      (alu_bus_load_dp),
	.i_read_pc					(alu_bus_pc_read),
	.i_cmd_dp_read      (alu_bus_dp_read),
	.i_cmd_dp_write		  (alu_bus_dp_write),
	.i_cmd_reset        (ins_reset),
	.i_cmd_config			  (alu_bus_config),
	.i_mem_xfr				  (ins_mem_xfr),
	.i_xfr_out					(xfr_dir_out),
	.i_xfr_cnt				 	(alu_bus_xfr_cnt),
  .i_nibble           (alu_bus_nibble_out),
  .o_nibble           (ctrl_bus_nibble_in)
);

reg  [0:0] mem_ctrl_stall;
wire [0:0] bus_stalls_core;
wire [0:0] ctrl_bus_done;
wire [3:0] ctrl_bus_data_ptr;
wire [3:0] ctrl_bus_nibble_in;

// `define DEBUG_CLOCKS

initial	begin
		clk_phases 		 = 0;

		clock_end			 = 0;
		cycle_ctr		 	 = 0;

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

reg [3:0] clk_phases;

wire phase_0;
wire phase_1;
wire phase_2;
wire phase_3;

assign phase_0 = clk_phases[0];
assign phase_1 = clk_phases[1];
assign phase_2 = clk_phases[2];
assign phase_3 = clk_phases[3];
 
always @(posedge i_clk) begin

	clk_phases <= {clk_phases[2:0], clk_phases[3]};

	cycle_ctr    <= cycle_ctr + { {31{1'b0}}, phase_0 };
	if (cycle_ctr == (max_cycle + 1)) begin
		$display(".-----------------------------.");
		$display("|   OUT OF CYCLES %d  |", cycle_ctr);
		$display("`-----------------------------´");
		clock_end <= 1;
	end

	if (i_reset) begin

		clk_phases 	  <= 4'b0001;

		clock_end	    <= 0;
		cycle_ctr	    <= ~0;
		max_cycle     <= 125;

		mem_ctrl_stall <= 0;
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
`ifdef SIM
assign o_halt = clock_end || inv_opcode;
`endif

// Verilator lint_off UNUSED
//wire [N-1:0] unused;
//assign unused = { }; 
// Verilator lint_on UNUSED
endmodule

`ifdef SIM

`include "def-buscmd.v"
`include "saturn_test_rom.v"

/******************************************************************************
 *
 * test harness
 *
 ****************************************************************************/

module saturn_tb;

saturn_core saturn (
	.i_clk						(clk),
	.i_reset          (reset),
	.o_halt           (halt),
	.o_bus_reset      (core_bus_reset),
  .i_bus_data_in    (core_bus_data_in),
  .o_bus_data_out   (core_bus_data_out),
  .o_bus_strobe     (core_bus_strobe),
  .o_bus_cmd_data   (core_bus_cmd_data),

	.o_phase          (core_phase)
);

saturn_test_rom rom (
	.i_reset        (core_bus_reset),
	.i_bus_data_in  (core_bus_data_out),
	.o_bus_data_out (core_bus_data_in),
	.i_bus_strobe   (core_bus_strobe),
	.i_bus_cmd_data (core_bus_cmd_data)
);

reg	 [0:0] clk;
reg	 [0:0] reset;
wire [0:0] halt;

wire [0:0] core_bus_reset;
wire [3:0] core_bus_data_in;
wire [3:0] core_bus_data_out;
wire [0:0] core_bus_strobe;
wire [0:0] core_bus_cmd_data;

wire [1:0] core_phase;

always 
    #10 clk = (clk === 1'b0);

initial begin
	// $monitor ("c %b | r %b | in %h | out %h | str %b | cd %b", 
	// 				  clk, reset, core_bus_data_in, core_bus_data_out, core_bus_strobe, core_bus_cmd_data);
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
