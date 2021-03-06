
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

`include "saturn_alu_pc.v"
`include "saturn_alu_registers.v"
`include "def-alu.v"

`ifndef _SATURN_ALU
`define _SATURN_ALU

`default_nettype none //

`ifdef SIM
// `define ALU_DEBUG_DBG
`endif

`define ALU_DEBUG       1'b1
`define ALU_DEBUG_DUMP  1'b1     
`define ALU_DEBUG_JUMP  1'b0
`define ALU_DEBUG_PC    1'b0  

module saturn_alu (
    i_clk,
    i_reset,
    i_phases,
    i_cycle_ctr,
    i_stalled,
    o_en_cycle_cnt,
    o_reg_dump,

    o_bus_address,
    i_bus_data_ptr,
    o_bus_data_nibl,
    o_bus_xfr_cnt,
    i_bus_nibble_in,
    o_bus_nibble_out,

    o_bus_pc_read,
    o_bus_dp_read,
    o_bus_dp_write,
    o_bus_load_pc,
    o_bus_load_dp,
    o_bus_config,
    i_bus_done,

    i_push,
    i_pop,
    i_alu_debug,

    o_alu_stall_dec,
    i_ins_decoded,

    i_field_start,
    i_field_last,
    i_imm_value,

    i_alu_op,
    i_alu_no_stall,
    i_reg_dest,
    i_reg_src1,
    i_reg_src2,

    i_ins_alu_op,
    i_ins_test_go,
    i_ins_set_mode,
    i_ins_rtn,
    i_ins_config,
    i_ins_mem_xfr,
    i_xfr_dir_out,
    i_ins_unconfig,

    i_mode_dec,
    i_set_xm,
    i_set_carry,
    i_test_carry,
    i_carry_val,

    o_reg_p,
    o_pc
);

input   wire [0:0]  i_clk;
input   wire [0:0]  i_reset;
input   wire [3:0]  i_phases;
input   wire [31:0] i_cycle_ctr;
input   wire [0:0]  i_stalled;
output  wire [0:0]  o_en_cycle_cnt;
output  wire [0:0]  o_reg_dump;
        wire [0:0]  i_reg_dump;
 
/*
 * I/O to the bus controller
 */

/* data to and from the bus controller */
output  wire [19:0] o_bus_address;
input   wire [3:0]  i_bus_data_ptr;
output  reg  [3:0]  o_bus_data_nibl;
output  reg  [3:0]  o_bus_xfr_cnt;
input   wire [3:0]  i_bus_nibble_in;
output  reg  [3:0]  o_bus_nibble_out;

/* control lines to the bus controller */
output  reg  [0:0]  o_bus_pc_read;
output  reg  [0:0]  o_bus_dp_read;
output  reg  [0:0]  o_bus_dp_write;
output  wire [0:0]  o_bus_load_pc;
output  reg  [0:0]  o_bus_load_dp;
output  reg  [0:0]  o_bus_config;
input   wire [0:0]  i_bus_done;

/*
 * lines from the decoder
 */
input   wire [0:0]  i_push;
input   wire [0:0]  i_pop;
input   wire [0:0]  i_alu_debug;

output  wire [0:0]  o_alu_stall_dec;
input   wire [0:0]  i_ins_decoded;

input   wire [3:0]  i_field_start;
input   wire [3:0]  i_field_last;
input   wire [3:0]  i_imm_value;

input   wire [4:0]  i_alu_op;
input   wire [0:0]  i_alu_no_stall;
input   wire [4:0]  i_reg_dest;
input   wire [4:0]  i_reg_src1;
input   wire [4:0]  i_reg_src2;

input   wire [0:0]  i_ins_alu_op;
input   wire [0:0]  i_ins_test_go;
input   wire [0:0]  i_ins_set_mode; 
input   wire [0:0]  i_ins_rtn;
input   wire [0:0]  i_ins_config;
input   wire [0:0]  i_ins_mem_xfr;
input   wire [0:0]  i_xfr_dir_out;
input   wire [0:0]  i_ins_unconfig;

input   wire [0:0]  i_mode_dec;
input   wire [0:0]  i_set_xm;
input   wire [0:0]  i_set_carry;
input   wire [0:0]  i_test_carry;
input   wire [0:0]  i_carry_val;

output  wire [3:0]  o_reg_p;
output  wire [19:0] o_pc;

assign o_reg_p = P;

/*
 * 
 * clock phases definitions
 *
 */

wire [0:0] phase_0;
wire [0:0] phase_1;
wire [0:0] phase_2;
wire [0:0] phase_3;

assign phase_0 = i_phases[0];
assign phase_1 = i_phases[1];
assign phase_2 = i_phases[2];
assign phase_3 = i_phases[3]; 

reg [1:0] phase;

always @(*) begin
  phase = 2'd0;
  case (1'b1)
  phase_0: phase = 2'd0;
  phase_1: phase = 2'd1;
  phase_2: phase = 2'd2;
  phase_3: phase = 2'd3;
  default: phase = 2'd0;
  endcase
end

wire alu_active;

assign alu_active = !i_reset && !i_stalled && !i_reg_dump;

/*
 * this module handles the PC and the RSTK
 *
 *
 */

saturn_alu_pc pc_management (
  .i_clk                (i_clk),
  .i_reset              (i_reset),
  .i_stalled            (i_stalled),
  .i_just_reset         (just_reset),
  .i_alu_active         (alu_active),
  .i_cycle_ctr          (i_cycle_ctr),
  .i_phase              (phase),
  .i_phase_0            (phase_0),
  .i_phase_2            (phase_2),
  .i_phase_3            (phase_3),

  .i_alu_initializing   (alu_initializing),
  .i_v_dest_counter_ptr (v_dest_counter_ptr),

  .o_bus_address        (o_bus_address),
  .o_bus_load_pc        (o_bus_load_pc),
  .i_bus_nibble_in      (i_bus_nibble_in),

  .i_alu_stall_dec      (o_alu_stall_dec),
  .i_ins_rtn            (i_ins_rtn),
  .i_ins_test_go        (i_ins_test_go),
  .i_push               (i_push),
  .i_pop                (i_pop),

  .i_mode_jmp           (mode_jmp),
  .i_carry              (CARRY),

  .i_op_jump            (op_jump),
  .i_op_jmp_rel_2       (op_jmp_rel_2),
  .i_op_jmp_rel_3       (op_jmp_rel_3),
  .i_op_jmp_rel_4       (op_jmp_rel_4),
  .i_op_jmp_abs_5       (op_jmp_abs_5),

  .o_do_apply_jump      (do_apply_jump),

`ifdef SIM
  .o_pc                 (o_pc),
  .o_rstk_ptr           (rstk_ptr),
  .o_rstk_0             (rstk_0),
  .o_rstk_1             (rstk_1),
  .o_rstk_2             (rstk_2),
  .o_rstk_3             (rstk_3),
  .o_rstk_4             (rstk_4),
  .o_rstk_5             (rstk_5),
  .o_rstk_6             (rstk_6),
  .o_rstk_7             (rstk_7)
`else
  .o_pc                 (o_pc)
`endif
);

wire [0:0] do_apply_jump;
`ifdef SIM
wire [2:0]  rstk_ptr;
wire [19:0] rstk_0;
wire [19:0] rstk_1;
wire [19:0] rstk_2;
wire [19:0] rstk_3;
wire [19:0] rstk_4;
wire [19:0] rstk_5;
wire [19:0] rstk_6;
wire [19:0] rstk_7;
`endif

/*
 * This module handles the data and pointer registers
 *
 *
 */

saturn_alu_registers registers (
  .i_clk              (i_clk),
  .i_reset            (i_reset),
  .i_stalled          (i_stalled),
  .i_phase            (phase),
  .i_phase_3          (phase_3),
  .i_cycle_ctr        (i_cycle_ctr),
  .i_alu_initializing (alu_initializing),
  .i_ins_decoded      (i_ins_decoded),

  .i_src_ptr          (source_counter),  
  .i_src_1            (i_reg_src1),
  .o_src_1_nbl        (rp_src_1),
  .o_src_1_valid      (rp_src_1_valid),
  .i_src_2            (i_reg_src2),
  .o_src_2_nbl        (rp_src_2),
  .o_src_2_valid      (rp_src_2_valid),

  .i_dest_ptr         (v_dest_ptr),
  .i_dest_1           (i_reg_dest),
  .i_dest_1_nbl       (rc_res_1),
  .i_dest_2           (i_reg_src2),
  .i_dest_2_nbl       (c_res_2)

`ifdef SIM
  ,
  .i_dbg_src          (alu_dbg_src),
  .i_dbg_ptr          (alu_dbg_ctr[3:0]),
  .o_dbg_nbl          (alu_dbg_nbl)
`endif
);


/*
 *
 * internal registers
 *
 */

/* copy of arguments */
reg [4:0] alu_op;
reg [4:0] reg_dest;
reg [4:0] reg_src1;
reg [4:0] reg_src2;
reg [3:0] f_first;
reg [3:0] f_cur;
reg [3:0] f_last;

/* internal pointers */

wire [3:0] rp_src_1;
wire [0:0] rp_src_1_valid;
wire [3:0] rp_src_2;
wire [0:0] rp_src_2_valid;


reg [3:0] p_src1;
reg [3:0] p_src2;
reg [0:0] p_carry;


reg [3:0] c_res_1;
reg [3:0] c_res_2;
reg [0:0] c_carry;
reg [0:0] is_zero;

reg [3:0] rc_res_1;

always @(*) begin
  rc_res_1 = c_res_1;
  if (src1_IMM) rc_res_1 = i_imm_value;
  if (src1_P)   rc_res_1 = P;
end

reg  [0:0]       CARRY;
reg  [0:0]       DEC;
reg  [3:0]       P;
reg  [3:0]       HST;
reg  [15:0]      ST;

/******************************************************************************
 *
 * ALU debug modes
 *
 *****************************************************************************/ 


wire alu_debug;
wire alu_debug_dump;
wire alu_debug_jump;
wire alu_debug_pc;
assign alu_debug      = `ALU_DEBUG      || i_alu_debug;
assign alu_debug_dump = `ALU_DEBUG_DUMP || i_alu_debug;
assign alu_debug_jump = `ALU_DEBUG_JUMP || i_alu_debug;
assign alu_debug_pc   = `ALU_DEBUG_PC   || i_alu_debug;

/******************************************************************************
 *
 * states decoding
 *
 *****************************************************************************/ 

/*
 * ALU : modes of operation
 *
 * - classical alu used for calculations 
 * - data transfer to and from memory
 * - jump calculations
 *
 */

// the ALU is in memory transfer mode
reg [0:0] f_mode_xfr;
reg [0:0] f_mode_config;
reg [0:0] f_mode_load_ptr;
reg [0:0] f_mode_ldreg;
reg [0:0] f_mode_jmp;
reg [0:0] f_mode_alu;

wire mode_xfr;
wire mode_config;
wire mode_load_ptr;
wire mode_ldreg;
wire mode_p;
wire mode_st_bit;
wire mode_hst_clrmask;
wire mode_jmp;
wire mode_alu;

assign mode_xfr         = start_in_xfr_mode      || f_mode_xfr;
assign mode_config      = start_in_config_mode   || f_mode_config;
assign mode_load_ptr    = start_in_load_ptr_mode || f_mode_load_ptr;
assign mode_ldreg       = start_in_ldreg_mode    || f_mode_ldreg;
assign mode_p           = start_in_p_mode;
assign mode_st_bit      = start_in_st_bit_mode;
assign mode_hst_clrmask = start_in_hst_clrmask_mode;
assign mode_jmp         = start_in_jmp_mode      || f_mode_jmp;
assign mode_alu         = start_in_alu_mode      || f_mode_alu;

wire [0:0] mode_set;
wire [0:0] mode_not_alu;
wire [0:0] stall_modes;
wire [0:0] alu_start_ev;

wire [0:0] start_in_xfr_mode;
wire [0:0] start_in_config_mode;
wire [0:0] start_in_load_ptr_mode;
wire [0:0] start_in_ldreg_mode;
wire [0:0] start_in_p_mode;
wire [0:0] start_in_st_bit_mode;
wire [0:0] start_in_hst_clrmask_mode;
wire [0:0] start_in_jmp_mode;
wire [0:0] start_in_alu_mode;

assign mode_not_alu              = mode_xfr || mode_config || mode_load_ptr || mode_ldreg || mode_p || mode_st_bit || mode_hst_clrmask || mode_jmp;
assign mode_set                  = f_mode_xfr || f_mode_config || f_mode_load_ptr || f_mode_ldreg || f_mode_jmp || f_mode_alu;
assign stall_modes               = mode_xfr || f_mode_config || mode_alu;

assign alu_start_ev              = alu_active && phase_3;

assign start_in_xfr_mode         = alu_start_ev && i_ins_mem_xfr && !mode_set;
assign start_in_config_mode      = alu_start_ev && i_ins_config && !mode_set;
assign start_in_load_ptr_mode    = alu_start_ev && i_ins_alu_op && op_copy && dest_ptr && src1_IMM && !mode_set;
assign start_in_ldreg_mode       = alu_start_ev && i_ins_alu_op && op_copy && dest_A_C && src1_IMM && !mode_set;
assign start_in_p_mode           = alu_start_ev && i_ins_alu_op && op_1_cycle_p && !mode_set; 
assign start_in_st_bit_mode      = alu_start_ev && i_ins_alu_op && op_st_bit && !mode_set;
assign start_in_hst_clrmask_mode = alu_start_ev && i_ins_alu_op && op_hst_clrmask && !mode_set;
assign start_in_jmp_mode         = alu_start_ev && i_ins_alu_op && op_jump && src1_IMM && !mode_set;
assign start_in_alu_mode         = alu_start_ev && i_ins_alu_op && !mode_not_alu && !f_mode_alu;

assign o_alu_stall_dec = alu_initializing || i_stalled || stall_modes || i_reg_dump;


/*
 * wires for all modes
 */

/* operation */

wire [0:0] op_copy;
wire [0:0] op_rst_bit;
wire [0:0] op_set_bit;
wire [0:0] op_inc;
wire [0:0] op_dec;
wire [0:0] op_jmp_rel_2;
wire [0:0] op_jmp_rel_3;
wire [0:0] op_jmp_rel_4;
wire [0:0] op_jmp_abs_5;
wire [0:0] op_clr_mask;

wire [0:0] op_inc_p;
wire [0:0] op_dec_p;
wire [0:0] op_set_p;
wire [0:0] op_copy_p_to_c;
wire [0:0] op_copy_c_to_p;

wire [0:0] op_st_rst_bit;
wire [0:0] op_st_set_bit;
wire [0:0] op_st_bit;

wire [0:0] op_hst_clrmask;

wire [0:0] op_1_cycle_p;
wire [0:0] op_jump;

assign op_copy        = (i_alu_op == `ALU_OP_COPY);
assign op_rst_bit     = (i_alu_op == `ALU_OP_RST_BIT);
assign op_set_bit     = (i_alu_op == `ALU_OP_SET_BIT);
assign op_inc         = (i_alu_op == `ALU_OP_INC);
assign op_dec         = (i_alu_op == `ALU_OP_DEC); 
assign op_jmp_rel_2   = (i_alu_op == `ALU_OP_JMP_REL2);
assign op_jmp_rel_3   = (i_alu_op == `ALU_OP_JMP_REL3);
assign op_jmp_rel_4   = (i_alu_op == `ALU_OP_JMP_REL4);
assign op_jmp_abs_5   = (i_alu_op == `ALU_OP_JMP_ABS5);
assign op_clr_mask    = (i_alu_op == `ALU_OP_CLR_MASK);

assign op_inc_p       = op_inc && src1_P && dest_P;
assign op_dec_p       = op_dec && src1_P && dest_P;
assign op_set_p       = op_copy && src1_IMM && dest_P;
assign op_copy_p_to_c = op_copy && src1_P && dest_C;
assign op_copy_c_to_p = op_copy && src1_C && dest_P;

assign op_st_rst_bit  = op_rst_bit && dest_ST && src1_IMM;
assign op_st_set_bit  = op_set_bit && dest_ST && src1_IMM;
assign op_st_bit      = op_st_rst_bit || op_st_set_bit;

assign op_hst_clrmask = op_clr_mask && dest_HST && src1_IMM;

assign op_1_cycle_p   = op_inc_p || op_dec_p || op_set_p || op_copy_p_to_c || op_copy_c_to_p;
assign op_jump        = op_jmp_rel_2 || op_jmp_rel_3 || op_jmp_rel_4 || op_jmp_abs_5;

/* source 1 */
wire [0:0] src1_A;
wire [0:0] src1_C;
wire [0:0] src1_DAT0;
wire [0:0] src1_DAT1;
wire [0:0] src1_P;
wire [0:0] src1_IMM;

assign src1_A    = (i_reg_src1 == `ALU_REG_A);
assign src1_C    = (i_reg_src1 == `ALU_REG_C);
assign src1_DAT0 = (i_reg_src1 == `ALU_REG_DAT0);
assign src1_DAT1 = (i_reg_src1 == `ALU_REG_DAT1); 
assign src1_P    = (i_reg_src1 == `ALU_REG_P);
assign src1_IMM  = (i_reg_src1 == `ALU_REG_IMM);

/* destination */
wire [0:0] dest_A;
wire [0:0] dest_C;
wire [0:0] dest_D0;
wire [0:0] dest_D1;
wire [0:0] dest_DAT0;
wire [0:0] dest_DAT1;
wire [0:0] dest_HST;
wire [0:0] dest_ST;
wire [0:0] dest_P;

assign dest_A    = (i_reg_dest == `ALU_REG_A);
assign dest_C    = (i_reg_dest == `ALU_REG_C);
assign dest_D0   = (i_reg_dest == `ALU_REG_D0);
assign dest_D1   = (i_reg_dest == `ALU_REG_D1);
assign dest_DAT0 = (i_reg_dest == `ALU_REG_DAT0);
assign dest_DAT1 = (i_reg_dest == `ALU_REG_DAT1);
assign dest_HST  = (i_reg_dest == `ALU_REG_HST);
assign dest_ST   = (i_reg_dest == `ALU_REG_ST);
assign dest_P    = (i_reg_dest == `ALU_REG_P);

wire [0:0] dest_A_C;
wire [0:0] dest_ptr;

assign dest_A_C  = dest_A || dest_C;
assign dest_ptr  = dest_D0 || dest_D1;


/******************************************************************************
 *
 * stuff that doesn't need to access registers
 *
 *****************************************************************************/

reg  [0:0]  just_reset;

always @(posedge i_clk) begin

  if (just_reset && !i_reset)
    $display("ALU_INIT %0d: [%d] CLEARING JUST_RESET", phase, i_cycle_ctr);

  /* register to memory transfer
   */
  if (start_in_xfr_mode) begin
    $display("ALU      %0d: [%d] memory transfer started (i_ins_decoded %b)", phase, i_cycle_ctr, i_ins_decoded);
    $display("ALU      %0d: [%d] addr_src A %b | C %b | D0 %b | D1 %b | src %2b", phase, i_cycle_ctr, 
             addr_src_A, addr_src_C, addr_src_D0, addr_src_D1, addr_src);
    $display("ALU      %0d: [%d] stall the decoder",phase, i_cycle_ctr);
    f_mode_xfr <= 1'b1;
  end

  if (start_in_config_mode) begin
    $display("ALU      %0d: [%d] config command", phase, i_cycle_ctr);
    $display("ALU      %0d: [%d] addr_src A %b | C %b | D0 %b | D1 %b | src %2b", phase, i_cycle_ctr, 
             addr_src_A, addr_src_C, addr_src_D0, addr_src_D1, addr_src);
    $display("ALU      %0d: [%d] stall the decoder",phase, i_cycle_ctr);
    f_mode_config <= 1'b1;
  end

  if (alu_active && f_mode_xfr && i_bus_done)
    $display("ALU      %0d: [%d] resetting variables after data transfer", phase, i_cycle_ctr);

  /* load pointer register with value
   */
  if (start_in_load_ptr_mode) begin
    $display("ALU      %0d: [%d] load_ptr mode started (i_ins_decoded %b)", phase, i_cycle_ctr, i_ins_decoded);
    f_mode_load_ptr <= 1'b1;
  end

  /* load register immediate with 1-16 nibbles
   */
  if (start_in_ldreg_mode) begin
    $display("ALU      %0d: [%d] load register mode started (loading reg %c with %0d nibbles)",
      phase, i_cycle_ctr, dest_A?"A":"C", i_field_last - i_field_start + 1);
    f_mode_ldreg   <= 1'b1;
  end

  if (do_load_register_done)
    $display("ALU      %0d: [%d] resetting variables after loading register", phase, i_cycle_ctr);

  /* a jump instruction just appeared !
   */
  if (start_in_jmp_mode) begin
    $display("ALU      %0d: [%d] jmp mode started (i_ins_decoded %b)", phase, i_cycle_ctr, i_ins_decoded);
    f_mode_jmp <= 1'b1;
  end

  if (do_apply_jump)
      $display("ALU      %0d: [%d] end of jmp mode", phase, i_cycle_ctr);

  /* general ALU mode (when there is no optimization)
   */
  if (start_in_alu_mode) begin
    $display("ALU      %0d: [%d] alu mode started (i_ins_decoded %b)", phase, i_cycle_ctr, i_ins_decoded);
    $display("ALU      %0d: [%d] stall the decoder",phase, i_cycle_ctr);
    f_mode_alu <= 1'b1;
  end



  if (i_reset || 
      alu_active && f_mode_xfr && i_bus_done ||
      alu_active && f_mode_config && !o_bus_config ||
      do_load_pointer_done ||
      do_load_register_done ||
      do_apply_jump) 
  begin
    $display("ALU      %0d: [%d] cleanup of all modes", phase, i_cycle_ctr);
    f_mode_xfr      <= 1'b0;
    f_mode_config   <= 1'b0;
    f_mode_load_ptr <= 1'b0;
    f_mode_ldreg    <= 1'b0;
    f_mode_jmp      <= 1'b0;
    f_mode_alu      <= 1'b0;
  end

  just_reset <= i_reset;

end

/* module 1:
 * handles all alu mode timing
 *
 *
 */

always @(posedge i_clk) begin

  
end

/* module 2:
 * src1 and src2 can only be written here
 * address can only be written here
 * registers can only be read here
 *
 * wires specific to the XFR mode
 * 
 * sources of address data used for XFR mode:
 * - A  [ PC=(A) ]
 * - C  [ CONFIG, UNCNFG, PC=(C) ]
 * - D0 [ DAT0=reg, reg=DAT0 ]
 * - D1 [ DAT1=reg, reg=DAT1 ]
 */
reg  [3:0] xfr_data[0:15];
reg  [3:0] data_counter;

// copy the address into the transfer buffer

wire [0:0] addr_src_A;
wire [0:0] addr_src_C;
wire [0:0] addr_src_D0;
wire [0:0] addr_src_D1;
reg  [1:0] addr_src;

wire [0:0] copy_done;
wire [0:0] copy_address;
wire [0:0] start_load_dp;

assign addr_src_A        = (!mode_xfr) && src1_A;
assign addr_src_C        = (!mode_xfr) && src1_C;
assign addr_src_D0       = ( mode_xfr) && (src1_DAT0 || dest_DAT0);
assign addr_src_D1       = ( mode_xfr) && (src1_DAT1 || dest_DAT1);

always @(*) begin
  addr_src = 0;
  if (mode_config) begin
    if (addr_src_C) addr_src = 2'b01;
  end
  if (mode_xfr) begin
    // assert(!addr_src_A && !addr_src_C) $display("we got address source A or C where we shouldn't");
    if (addr_src_D0) addr_src = 2'b10;
    if (addr_src_D1) addr_src = 2'b11;
  end
end

assign copy_done         = data_counter == 5;
assign copy_address      = alu_active && (mode_xfr || mode_config) && !copy_done && !(xfr_init_done || config_init_done);
assign start_load_dp     = start_in_xfr_mode;

// now copy the data aligning the first nibble with index 0 of the buffer
// copy nibbles 0-4 at the end so as not to clobber the address set previously
// while the bus controller is sending it

reg  [0:0] xfr_init_done;
reg  [0:0] xfr_data_done;
wire [0:0] xfr_data_init;
wire [3:0] xfr_data_ctr;
wire [0:0] xfr_data_copy;
wire [0:0] xfr_copy_done;

assign xfr_data_init     = alu_active && mode_xfr && copy_done && !xfr_init_done && !xfr_data_done && phase_3;
assign xfr_data_ctr      = data_counter + i_field_start;
assign xfr_copy_done     = alu_active && xfr_init_done && copy_done && !xfr_data_init && !xfr_data_done;
assign xfr_data_copy     = alu_active && (xfr_data_init || xfr_init_done && !xfr_data_done && !copy_done && !xfr_copy_done);

// config

reg  [0:0] config_init_done;
wire [0:0] start_configure;
wire [0:0] config_wait;
assign start_configure   = start_in_config_mode;

assign config_wait       = !i_reset && mode_config && copy_done && !config_init_done;

/*
 * the same counter is used for both sources when two sources are used
 */
reg  [3:0] source_counter;
wire [2:0] source_counter_ptr;

always @(*) begin
  source_counter = 0;
  if (copy_address) source_counter = data_counter;
  if (xfr_data_copy) source_counter = xfr_data_ctr;
end

reg [0:0] bus_is_done;

assign source_counter_ptr = source_counter[2:0];

always @(posedge i_clk) begin

  // initializes modes
  if (i_reset) begin
    data_counter  <= 0;
    xfr_init_done <= 0;
    xfr_data_done <= 0;
    config_init_done <= 0;
  end

  // always update the data out to the controller
  if (alu_active)
    o_bus_data_nibl <= xfr_data[i_bus_data_ptr];

  /****************************************************************************
   *
   * register to memory transfer.
   *
   ***************************************************************************/

  if (start_load_dp) begin
    o_bus_load_dp <= 1;
  end

  if (start_configure) begin
    o_bus_config <= 1;
  end


  if (copy_address) begin
    // we get the address source from src2

`ifdef SIM
    $write("ALU      %0d: [%d] xfr_data[%0d] = ", phase, i_cycle_ctr, data_counter);
    case (i_reg_src2)
    `ALU_REG_A:  $write("A");
    `ALU_REG_C:  $write("C");
    `ALU_REG_D0: $write("D0");
    `ALU_REG_D1: $write("D1");
    default: $write("[invalid register %0d]", i_reg_src2);
    endcase
    $display("[%0d] %h", source_counter, rp_src_2);
`endif
    xfr_data[data_counter] <= rp_src_2;
    data_counter <= data_counter + 1;
  end

  // do not need to update the data counter, which is already at 5
  if (xfr_data_init) begin
    $display("ALU      %0d: [%d] initialize copy data | s %h | l %h | xdc %h",phase, i_cycle_ctr, i_field_start, i_field_last, xfr_data_ctr);
    xfr_init_done <= 1;
  end

  // need to copy actual data
  // two sources are possible, A and C, a conditional will suffice
  if (xfr_data_copy) begin
    $display("ALU      %0d: [%d] copy data DAT[%b][%2d] <= %c[%2d] %h",
             phase, i_cycle_ctr, dest_DAT1, data_counter, src1_A?"A":"C", source_counter, rp_src_1);
    xfr_data[data_counter] <= rp_src_1;
    data_counter           <= data_counter + 1;
  end

  if (xfr_copy_done) begin
    $display("ALU      %0d: [%d] xfr_copy_done %h %b %b",phase, i_cycle_ctr, data_counter, xfr_init_done, xfr_data_done);
    xfr_init_done <= 0;
    xfr_data_done <= 1;
    o_bus_load_dp <= 0;
    // right on time to start the actual transfer
    o_bus_dp_write <= i_xfr_dir_out;
    o_bus_dp_read  <= !i_xfr_dir_out;
    o_bus_xfr_cnt  <= (i_field_last - i_field_start);
  end

  /* config
   */
    // do not need to update the data counter, which is already at 5
  if (config_wait) begin
    $display("ALU      %0d: [%d] wait for the end of the config command",phase, i_cycle_ctr, i_field_start, i_field_last, xfr_data_ctr);
    config_init_done <= 1;
  end


  /****************************************************************************
   *
   * reset all things that were changed
   *
   ***************************************************************************/

  if (alu_active && i_bus_done) begin
    $display("ALU      %0d: [%d] bus controller is done, cleaning all variables used",phase, i_cycle_ctr);    
    /* variables for the XFR mode */
    data_counter  <= 0;
    xfr_init_done <= 0;
    xfr_data_done <= 0;
    config_init_done <= 0;

    /* bus controller control lines */
    o_bus_dp_write <= 0;
    o_bus_config   <= 0;
    o_bus_dp_read  <= 0;
    o_bus_xfr_cnt  <= 0;
  end

end


/*
 * module 3: calculations
 * 
 * this is a combinatorial stage
 *
 */

always @(posedge i_clk) begin
  if (i_reset) begin
    c_res_1 <= 4'b0;
  end

end

/*
 * moduls 4:
 * registers can only be written to here
 *
 *
 *
 *
 *
 */

reg [0:0]  alu_initializing;

reg  [3:0] v_dest_counter;
reg  [3:0] v_max_counter;
wire [2:0] v_dest_counter_ptr;
wire [1:0] v_dest_counter_hst;
reg  [3:0] v_dest_ptr;
assign v_dest_counter_ptr = v_dest_counter[2:0];
assign v_dest_counter_hst = v_dest_counter[1:0];

always @(*) begin
  v_dest_ptr = v_dest_counter;
  if (op_copy_p_to_c) v_dest_ptr = i_field_start;
end                    

wire [0:0] do_load_pointer;
wire [0:0] do_load_pointer_done;
wire [0:0] do_load_register;
wire [0:0] do_load_register_done;

assign do_load_pointer       = alu_active && phase_2 && f_mode_load_ptr && (v_dest_counter != 5);
assign do_load_pointer_done  = alu_active && phase_3 && f_mode_load_ptr && (v_dest_counter == 5);
assign do_load_register      = alu_active && phase_2 && f_mode_ldreg && (v_dest_counter != v_max_counter);
assign do_load_register_done = alu_active && phase_3 && f_mode_ldreg && (v_dest_counter == v_max_counter);



always @(posedge i_clk) begin

  if (i_reset) begin
    /* initialization procedure */
    alu_initializing <= 1;
    CARRY            <= 0;
    P                <= 0;

    /* counters and flags */
    v_dest_counter   <= 0;
    v_max_counter    <= 0;
  end

  /*
   * Initialization of all registers
   * This happens at the same time the first LOAD_PC command goes out
   *
   */
  if (!i_reset && alu_initializing) begin
    $display("ALU_INIT %0d: [%d] init %0d", phase, i_cycle_ctr, v_dest_counter);
    ST[v_dest_counter]      <= 0;
    HST[v_dest_counter_hst] <= 0;
    alu_initializing        <= (v_dest_counter != 15);
    v_dest_counter          <= v_dest_counter + 1;
  end

  /*
   * 
   * ptr mode
   *
   */
  if (start_in_load_ptr_mode) begin
    v_dest_counter  <= 0;
  end

  if (do_load_pointer) begin
    $display("ALU      %0d: [%d] loading pointer D%b[%0d] <= %h", phase, i_cycle_ctr, dest_D1, v_dest_counter, i_bus_nibble_in);
    // case (dest_D1)
    //   0: D0[v_dest_counter_ptr] <= i_bus_nibble_in;
    //   1: D0[v_dest_counter_ptr] <= i_bus_nibble_in;
    //   default: begin end
    // endcase
   v_dest_counter <= v_dest_counter + 1;
  end

  if (do_load_pointer_done) begin
    $display("ALU      %0d: [%d] resetting variables after loading pointer", phase, i_cycle_ctr);
    v_dest_counter  <= 0;
  end

  /*
   *
   * load register mode
   *
   * LAHEX / LCHEX
   *
   */

  if (start_in_ldreg_mode) begin
    v_dest_counter <= 0;
    v_max_counter  <= i_field_last - i_field_start + 1;
  end

  if (do_load_register) begin
    $display("ALU      %0d: [%d] loading register %c[%0d] <= %h", phase, i_cycle_ctr, dest_A?"A":"C", v_dest_counter, i_bus_nibble_in);
    // case (dest_C)
    //   0: A[v_dest_counter] <= i_bus_nibble_in;
    //   1: C[v_dest_counter] <= i_bus_nibble_in;
    //   default: begin end
    // endcase
    v_dest_counter <= v_dest_counter + 1;
  end

  if (do_load_register_done) begin
    v_dest_counter <= 0;
    v_max_counter  <= 0;
  end

  /*
   * P-mode
   * 
   */
   
  if (start_in_p_mode && op_set_p) begin
    $display("ALU      %0d: [%d] loading P= %h", phase, i_cycle_ctr, i_imm_value);
    P <= i_imm_value;
  end

  if (start_in_p_mode && op_copy_p_to_c) begin
    $display("ALU      %0d: [%d] C=P %h", phase, i_cycle_ctr, i_field_start);
     v_dest_counter <= i_field_start;
    //  C[i_field_start] <= P;
  end

  /* ST=[01] <bit>
   */
  if (start_in_st_bit_mode) begin
    $display("ALU      %0d: [%d] ST[%0d] = %b", phase, i_cycle_ctr, i_imm_value, op_set_bit);
    ST[i_imm_value] <= op_set_bit;
  end

  /* XM=0
   * SB=0
   * ST=0
   * MP=0
   * CLRHST
   * CLRHST <mask>
   */
  if (start_in_hst_clrmask_mode) begin
    $display("ALU      %0d: [%d] HST = %h & ~%h", phase, i_cycle_ctr, HST, i_imm_value);
    HST <= HST & ~i_imm_value;
  end

  /*
   * set or clear the carry in case of RTNCC / RTNSC
   */
  if (alu_active && phase_3 && i_ins_rtn && i_set_carry) begin
     $display("ALU      %0d: [%d] %s CARRY", phase, i_cycle_ctr, i_carry_val?"SET":"RST");
    CARRY <= i_carry_val;
  end


end

/*****************************************************************************
 *
 * execute SETHEX and SETDEC 
 *
 ****************************************************************************/

always @(posedge i_clk) begin
  if (i_reset) 
    DEC <= 0;

  // changing calculation modes
  if (alu_active && phase_3 && i_ins_set_mode) begin
    $display("ALU      %0d: [%d] setting calulation mode to %s", phase, i_cycle_ctr, i_mode_dec?"DEC":"HEX");
    DEC <= i_mode_dec;
  end
end


























/*****************************************************************************
 *
 * Dump all registers at the end of each instruction's execution cycle
 *
 ****************************************************************************/

`ifndef SIM
assign i_reg_dump = 1'b0;
assign o_reg_dump = 1'b0;
`endif

`ifdef SIM
wire do_reg_dump;
wire do_alu_shpc;
assign do_reg_dump = alu_active && phase_0 && !o_bus_load_pc &&
                     i_ins_decoded && !o_alu_stall_dec && !reg_dump;
assign do_alu_shpc = alu_active && phase_0;

reg  [4:0] alu_dbg_src;
wire [3:0] alu_dbg_nbl;
reg  [4:0] alu_dbg_ctr;
reg  [0:0] reg_dump; 
reg  [0:0] reg_dump_done;

assign i_reg_dump     = reg_dump;
assign o_en_cycle_cnt = !(do_reg_dump || reg_dump) || (do_reg_dump && !reg_dump && reg_dump_done);
assign o_reg_dump     = reg_dump;

always @(posedge i_clk) begin
  if (i_reset) begin
    reg_dump      <= 1'b0;
    reg_dump_done <= 1'b0;
    alu_dbg_ctr   <= 5'b0;
    alu_dbg_src   <= 5'b0;
  end


  // $display("do_reg_dump %b | !reg_dump %b | !reg_dump_done %b", do_reg_dump, !reg_dump, !reg_dump_done);
  if (do_reg_dump && alu_debug_dump && !reg_dump && !reg_dump_done) begin
    reg_dump <= 1;

    // display registers
    $display("PC: %05h               Carry: %b h: %s rp: %h   RSTK7: %05h", 
             o_pc, CARRY, DEC?"DEC":"HEX", rstk_ptr, rstk_7);
    $display("P:  %h  HST: %b        ST:  %b   RSTK6: %5h", 
             P, HST, ST, rstk_6);

    $write("A:  ");
    alu_dbg_ctr = 15;
    alu_dbg_src = `ALU_REG_A;
  end

  if (do_reg_dump && alu_debug_dump && !reg_dump && reg_dump_done) begin
    // $display("ALU      %0d: [%d] register dump done", phase, i_cycle_ctr);
    reg_dump_done <= 1'b0;
  end

  if (reg_dump && (alu_dbg_src==`ALU_REG_A)) begin
    $write("%h", alu_dbg_nbl);
    alu_dbg_ctr <= alu_dbg_ctr - 5'b1;
    if (alu_dbg_ctr == 0) begin 
      $write("    R0:  ");
      alu_dbg_src <= `ALU_REG_R0;
      alu_dbg_ctr <= 15;
    end
  end

  if (reg_dump && (alu_dbg_src==`ALU_REG_R0)) begin
    $write("%h", alu_dbg_nbl);
    alu_dbg_ctr <= alu_dbg_ctr - 5'b1;
    if (alu_dbg_ctr == 0) begin 
      $write("   RSTK5: %5h\n", rstk_5);
      $write("B:  ");
      alu_dbg_src <= `ALU_REG_B;
      alu_dbg_ctr <= 15;
    end
  end

  if (reg_dump && (alu_dbg_src==`ALU_REG_B)) begin
    $write("%h", alu_dbg_nbl);
    alu_dbg_ctr <= alu_dbg_ctr - 5'b1;
    if (alu_dbg_ctr == 0) begin 
      $write("    R1:  ");
      alu_dbg_src <= `ALU_REG_R1;
      alu_dbg_ctr <= 15;
    end
  end

  if (reg_dump && (alu_dbg_src==`ALU_REG_R1)) begin
    $write("%h", alu_dbg_nbl);
    alu_dbg_ctr <= alu_dbg_ctr - 5'b1;
    if (alu_dbg_ctr == 0) begin 
      $write("   RSTK4: %5h\n", rstk_4);
      $write("C:  ");
      alu_dbg_src <= `ALU_REG_C;
      alu_dbg_ctr <= 15;
    end
  end

  if (reg_dump && (alu_dbg_src==`ALU_REG_C)) begin
    $write("%h", alu_dbg_nbl);
    alu_dbg_ctr <= alu_dbg_ctr - 5'b1;
    if (alu_dbg_ctr == 0) begin 
      $write("    R2:  ");
      alu_dbg_src <= `ALU_REG_R2;
      alu_dbg_ctr <= 15;
    end
  end

  if (reg_dump && (alu_dbg_src==`ALU_REG_R2)) begin
    $write("%h", alu_dbg_nbl);
    alu_dbg_ctr <= alu_dbg_ctr - 5'b1;
    if (alu_dbg_ctr == 0) begin 
      $write("   RSTK3: %5h\n", rstk_3);
      $write("D:  ");
      alu_dbg_src <= `ALU_REG_D;
      alu_dbg_ctr <= 15;
    end
  end

  if (reg_dump && (alu_dbg_src==`ALU_REG_D)) begin
    $write("%h", alu_dbg_nbl);
    alu_dbg_ctr <= alu_dbg_ctr - 5'b1;
    if (alu_dbg_ctr == 0) begin 
      $write("    R3:  ");
      alu_dbg_src <= `ALU_REG_R3;
      alu_dbg_ctr <= 15;
    end
  end

  if (reg_dump && (alu_dbg_src==`ALU_REG_R3)) begin
    $write("%h", alu_dbg_nbl);
    alu_dbg_ctr <= alu_dbg_ctr - 5'b1;
    if (alu_dbg_ctr == 0) begin 
      $write("   RSTK2: %5h\n", rstk_2);
      $write("D0: ");
      alu_dbg_src <= `ALU_REG_D0;
      alu_dbg_ctr <= 4;
    end
  end

  if (reg_dump && (alu_dbg_src==`ALU_REG_D0)) begin
    $write("%h", alu_dbg_nbl);
    alu_dbg_ctr <= alu_dbg_ctr - 5'b1;
    if (alu_dbg_ctr == 0) begin 
      $write("  D1: "); 
      alu_dbg_src <= `ALU_REG_D1;
      alu_dbg_ctr <= 4;
    end
  end

  if (reg_dump && (alu_dbg_src==`ALU_REG_D1)) begin
    $write("%h", alu_dbg_nbl);
    alu_dbg_ctr <= alu_dbg_ctr - 5'b1;
    if (alu_dbg_ctr == 0) begin 
      $write("    R4:  ");
      alu_dbg_src <= `ALU_REG_R4;
      alu_dbg_ctr <= 15;
    end
  end

  if (reg_dump && (alu_dbg_src==`ALU_REG_R4)) begin
    $write("%h", alu_dbg_nbl);
    alu_dbg_ctr <= alu_dbg_ctr - 5'b1;
    if (alu_dbg_ctr == 0) begin 
      $write("   RSTK1: %5h\n", rstk_1);
      $display("         ADDR: %5h                            RSTK0: %5h", 
               o_bus_address, rstk_0);
      alu_dbg_src = `ALU_REG_NOPE;
      reg_dump_done  <= 1'b1;
    end
  end

  if (reg_dump && reg_dump_done && phase_3) begin
    // $display("ALU      %0d: [%d] end register dump", phase, i_cycle_ctr);
    reg_dump      <= 1'b0;
  end

end

`endif


// always @(posedge i_clk) begin

//   if (i_reset) begin
//     p_src1   <= 0;
//     p_src2   <= 0;
//     p_carry  <= 0;
//     jump_bse <= 0;
//   end

//   if (do_alu_prep) begin
//     if (alu_debug) begin
//       `ifdef SIM
//       $display("ALU_PREP 1: run %b | done %b | stall %b | op %d | f %h | c %h | l %h | imm %h", 
//                alu_run, alu_done, o_alu_stall_dec, alu_op, f_first, f_cur, f_last, i_imm_value);
//       `endif
//     end

//     /*
//      * source 1
//      */
//     case (alu_op)
//       `ALU_OP_ZERO: begin end // no source required
//       `ALU_OP_COPY,
//       `ALU_OP_EXCH,
//       `ALU_OP_RST_BIT,
//       `ALU_OP_SET_BIT,
//       `ALU_OP_2CMPL,
//       `ALU_OP_DEC,
//       `ALU_OP_ADD,
//       `ALU_OP_TEST_EQ,
//       `ALU_OP_TEST_NEQ,
//       `ALU_OP_JMP_REL2,
//       `ALU_OP_JMP_REL3,
//       `ALU_OP_JMP_REL4,
//       `ALU_OP_JMP_ABS5,
//       `ALU_OP_CLR_MASK:
//         case (reg_src1)
//         `ALU_REG_A:    p_src1 <= A[f_cur];
//         `ALU_REG_B:    p_src1 <= B[f_cur];
//         `ALU_REG_C:    p_src1 <= C[f_cur];
//         `ALU_REG_D:    p_src1 <= D[f_cur];
//         `ALU_REG_R0:   p_src1 <= R0[f_cur];
//         `ALU_REG_R1:   p_src1 <= R1[f_cur];
//         `ALU_REG_R2:   p_src1 <= R2[f_cur];
//         `ALU_REG_R3:   p_src1 <= R3[f_cur];
//         `ALU_REG_R4:   p_src1 <= R4[f_cur];
//         `ALU_REG_D0:   p_src1 <= D0[f_cur[2:0]];
//         `ALU_REG_D1:   p_src1 <= D1[f_cur[2:0]];
//         `ALU_REG_P:    p_src1 <= P;
//         `ALU_REG_DAT0,
//         `ALU_REG_DAT1: p_src1 <= i_bus_nibble_in;
//         `ALU_REG_HST:  p_src1 <= HST;
//         `ALU_REG_IMM:  p_src1 <= i_imm_value;
//         `ALU_REG_ZERO: p_src1 <= 0;
//         default: $display("#### SRC_1 UNHANDLED REGISTER %0d", reg_src1);
//         endcase
//       default: $display("#### SRC_1 UNHANDLED OPERATION %0d", alu_op);
//     endcase


//     /*
//      * source 2
//      */
//     case (alu_op)
//       `ALU_OP_ZERO,
//       `ALU_OP_COPY,
//       `ALU_OP_RST_BIT,
//       `ALU_OP_SET_BIT,
//       `ALU_OP_2CMPL,
//       `ALU_OP_DEC,
//       `ALU_OP_JMP_REL2,
//       `ALU_OP_JMP_REL3,
//       `ALU_OP_JMP_REL4,
//       `ALU_OP_JMP_ABS5: begin end // no need for a 2nd operand
//       `ALU_OP_EXCH, 
//       `ALU_OP_ADD,
//       `ALU_OP_TEST_EQ,
//       `ALU_OP_TEST_NEQ,
//       `ALU_OP_CLR_MASK: begin
//         case (reg_src2)
//         `ALU_REG_A:    p_src2 <= A[f_cur];
//         `ALU_REG_B:    p_src2 <= B[f_cur];
//         `ALU_REG_C:    p_src2 <= C[f_cur];
//         `ALU_REG_D:    p_src2 <= D[f_cur];
//         `ALU_REG_R0:   p_src2 <= R0[f_cur];
//         `ALU_REG_R1:   p_src2 <= R1[f_cur];
//         `ALU_REG_R2:   p_src2 <= R2[f_cur];
//         `ALU_REG_R3:   p_src2 <= R3[f_cur];
//         `ALU_REG_R4:   p_src2 <= R4[f_cur];
//         `ALU_REG_D0:   p_src2 <= D0[f_cur[2:0]];
//         `ALU_REG_D1:   p_src2 <= D1[f_cur[2:0]];
//         `ALU_REG_P:    p_src2 <= P;
//         `ALU_REG_HST:  p_src2 <= HST;
//         `ALU_REG_IMM:  p_src2 <= i_imm_value;
//         `ALU_REG_ZERO: p_src2 <= 0;
//         default: $display("#### SRC_2 UNHANDLED REGISTER %0d", reg_src2);
//         endcase
//       end
//       default: $display("#### SRC_2 UNHANDLED OPERATION %0d", alu_op);
//     endcase

//     // setup p_carry
//     // $display("fs %h | fs=0 %b | cc %b | npc %b", f_start, (f_start == 0), c_carry, (f_start == 0)?1'b1:c_carry);
//     case (alu_op)
//     `ALU_OP_2CMPL:    p_carry <= alu_start?1'b1:c_carry;
//     `ALU_OP_DEC:      p_carry <= alu_start?1'b0:c_carry;
//     `ALU_OP_ADD:      p_carry <= alu_start?1'b0:c_carry;
//     `ALU_OP_TEST_NEQ: p_carry <= alu_start?1'b0:c_carry;
//     endcase

//     // prepare jump base
//     case (alu_op)
//     `ALU_OP_JMP_REL2,
//     `ALU_OP_JMP_REL3,
//     `ALU_OP_JMP_REL4:
//       begin
//         // the address of the first digit of the offset
//         if (!i_push && alu_start)
//           jump_bse <= PC - 1;
//         // doc says address of the next instruction, but appears to be off by 1
//         if (i_push)
//           jump_bse <= PC;
//       end
//     endcase

//   end
// end

// always @(posedge i_clk) begin
  
//   if (i_reset) begin
//     c_res1   <= 0;
//     c_res2   <= 0;
//     c_carry  <= 0;
//     is_zero  <= 0;
//     jump_off <= 0;
//   end

//   if (do_alu_calc) begin
//     `ifdef SIM
//     if (alu_debug)
//       $display("ALU_CALC 2: run %b | done %b | stall %b | op %d | f %h | c %h | l %h | dest %d | psrc1 %h | psrc2 %h | p_carry %b", 
//                alu_run, alu_done, o_alu_stall_dec, alu_op, f_first, f_cur, f_last, reg_dest, p_src1, p_src2, p_carry);
//     if (alu_debug_jump)
//       $display("ALU_JUMP 2: run %b | done %b | stall %b | op %d | f %h | c %h | l %h | jbs %5h | jof %5h | jpc %5h | fin %b",
//                alu_run, alu_done, o_alu_stall_dec, alu_op, f_first, f_cur, f_last, jump_bse, jump_off, jump_pc, alu_finish);
//     `endif

//     if(alu_start)
//       case (alu_op)
//         `ALU_OP_JMP_REL2,
//         `ALU_OP_JMP_REL3,
//         `ALU_OP_JMP_REL4,
//         `ALU_OP_JMP_ABS5: jump_off <= { 16'b0, p_src1 };
//       endcase

//     // main case
//     case (alu_op)
//       `ALU_OP_ZERO: c_res1 <= 0;
//       `ALU_OP_EXCH: 
//         begin
//             c_res1 <= p_src2;
//             c_res2 <= p_src1;
//           end
//       `ALU_OP_COPY,
//       `ALU_OP_RST_BIT,
//       `ALU_OP_SET_BIT:  c_res1 <= p_src1;
//       `ALU_OP_2CMPL: begin 
//           c_carry <= (~p_src1 == 4'hf) && p_carry ;
//           c_res1  <= ~p_src1 + {3'b000, p_carry};
//           is_zero <= ((~p_src1 + {3'b000, p_carry}) == 0) && alu_start?1:is_zero;
//         end
//       `ALU_OP_DEC: 
//         {c_carry, c_res1} <= p_src1 + 4'b1111 + {4'b0000, p_carry};
//       `ALU_OP_ADD:
//         {c_carry, c_res1} <= p_src1 + p_src2 + {4'b0000, p_carry};
//       `ALU_OP_TEST_NEQ: 
//         c_carry <= !(p_src1 == p_src2) || p_carry;
//       `ALU_OP_JMP_REL2: begin end // there is no middle part
//       `ALU_OP_JMP_REL3,
//       `ALU_OP_JMP_REL4,
//       `ALU_OP_JMP_ABS5: jump_off[f_cur*4+:4] <= p_src1;
//       `ALU_OP_CLR_MASK: c_res1 <= p_src1 & ~p_src2;
//       default: $display("#### CALC 2 UNHANDLED OPERATION %0d", alu_op); 
//     endcase

//     if (alu_finish) 
//       case (alu_op)
//         `ALU_OP_JMP_REL2: jump_off <= { {12{p_src1[3]}}, p_src1, jump_off[3:0]  };
//         `ALU_OP_JMP_REL3: jump_off <= { {8{p_src1[3]}},  p_src1, jump_off[7:0]  };
//         `ALU_OP_JMP_REL4: jump_off <= { {4{p_src1[3]}},  p_src1, jump_off[11:0] };
//       endcase

//     // $display("-------C- SRC1 %b %h | ~SRC1 %b %h | PC %b | RES1 %b %h | CC %b", 
//     //          p_src1, p_src1, ~p_src1, ~p_src1, p_carry, 
//     //          (~p_src1) + p_carry, (~p_src1) + p_carry, 
//     //          (~p_src1) == 4'hf );
//   end

//   if (do_go_init) begin
//     // $display("GO_INIT  3: imm %h", i_imm_value);
//     jump_off <= { {16{1'b0}}, i_imm_value};
//   end
// end


  /*
   * 
   * Debug for some JUMP condition testing
   *
   */

  // if (do_alu_save || do_go_prep) begin
  //   if (alu_debug_jump) begin
  //   `ifdef SIM
  //     $display({"ALU_JUMP 3: run %b | done %b | stall %b | op %d | f %h | ",
  //               "c %h | l %h | bse %5h | jof %5h | jpc %5h | fin %b"},
  //               alu_run, alu_done, o_alu_stall_dec, alu_op, f_first, f_cur, 
  //               f_last, jump_bse, jump_off, jump_pc, alu_finish);
  //   `endif
  //   end
  // end


  /*
   * normal way for the ALU to save results. 
   *
   *
   */

  // if (do_alu_save) begin
  //   `ifdef SIM
  //   if (alu_debug) begin
  //     $display({"ALU_SAVE 3: run %b | done %b | stall %b | op %d | f %h | c %h | l %h |",
  //               " dest %d | cres1 %h | cres2 %h | psrc1 %h | psrc2 %h | c_carry %b"}, 
  //               alu_run, alu_done, o_alu_stall_dec, alu_op, 
  //               f_first, f_cur, f_last, reg_dest, c_res1, c_res2, p_src1, p_src2, c_carry);

  //   end
  //   `endif

  //   case (alu_op)
  //     `ALU_OP_ZERO,
  //     `ALU_OP_COPY,
  //     `ALU_OP_EXCH, // does the first assign
  //     `ALU_OP_2CMPL,
  //     `ALU_OP_DEC,
  //     `ALU_OP_ADD,
  //     `ALU_OP_CLR_MASK:
  //       case (reg_dest)
  //       `ALU_REG_A:    A[f_cur] <= c_res1;
  //       `ALU_REG_B:    B[f_cur] <= c_res1;
  //       `ALU_REG_C:    C[f_cur] <= c_res1;
  //       `ALU_REG_D:    D[f_cur] <= c_res1;
  //       `ALU_REG_R0:   R0[f_cur] <= c_res1;
  //       `ALU_REG_R1:   R1[f_cur] <= c_res1;
  //       `ALU_REG_R2:   R2[f_cur] <= c_res1;
  //       `ALU_REG_R3:   R3[f_cur] <= c_res1;
  //       `ALU_REG_R4:   R4[f_cur] <= c_res1;
  //       `ALU_REG_D0:   D0[f_cur[2:0]] <= c_res1;
  //       `ALU_REG_D1:   D1[f_cur[2:0]] <= c_res1;
  //       `ALU_REG_ST:   ST[f_cur*4+:4] <= c_res1;
  //       `ALU_REG_P:    P <= c_res1;
  //       `ALU_REG_DAT0,
  //       `ALU_REG_DAT1: o_bus_nibble_out <= c_res1;
  //       `ALU_REG_HST:  HST <= c_res1;
  //       `ALU_REG_ADDR: begin end // done down below where o_bus_addr is accessible
  //       default: $display("#### ALU_SAVE invalid register %0d for op %0d", reg_dest, alu_op);
  //       endcase
  //     `ALU_OP_RST_BIT,
  //     `ALU_OP_SET_BIT:
  //       case (reg_dest)
  //       `ALU_REG_ST: ST[c_res1] <= alu_op==`ALU_OP_SET_BIT?1:0;
  //       default: $display("#### ALU_SAVE invalid register %0d for op %0d", reg_dest, alu_op);
  //       endcase
  //     `ALU_OP_TEST_EQ,
  //     `ALU_OP_TEST_NEQ,
  //     `ALU_OP_JMP_REL2,
  //     `ALU_OP_JMP_REL3,
  //     `ALU_OP_JMP_REL4,
  //     `ALU_OP_JMP_ABS5: begin end // nothing to save, handled by PC management below      
  //     default: $display("#### ALU_SAVE UNHANDLED OP %0d", alu_op);
  //   endcase 

  //   /*
  //    * in case of exch, we need to update src2 to finish the exchange
  //    */
  //   case (alu_op)
  //     `ALU_OP_EXCH: // 2nd assign, with src2
  //         case (reg_src2)
  //         `ALU_REG_A:   A[f_cur] <= c_res2;
  //         `ALU_REG_B:   B[f_cur] <= c_res2;
  //         `ALU_REG_C:   C[f_cur] <= c_res2;
  //         `ALU_REG_D:   D[f_cur] <= c_res2;
  //         `ALU_REG_D0:  D0[f_cur[2:0]] <= c_res2;
  //         `ALU_REG_D1:  D1[f_cur[2:0]] <= c_res2;
  //         `ALU_REG_R0:  R0[f_cur] <= c_res2;
  //         `ALU_REG_R1:  R1[f_cur] <= c_res2;
  //         `ALU_REG_R2:  R2[f_cur] <= c_res2;
  //         `ALU_REG_R3:  R3[f_cur] <= c_res2;
  //         `ALU_REG_R4:  R4[f_cur] <= c_res2;
  //         // `ALU_REG_ST:  ST[f_start*4+:4] <= c_res2;
  //         // `ALU_REG_P:   P <=                c_res2;
  //         // `ALU_REG_HST: HST <=              c_res2;
  //       endcase    
  //   endcase
  // end

  /*
   * update carry
   */
  // if (do_alu_save) begin
  //   case (alu_op)
  //   `ALU_OP_2CMPL: CARRY <= !is_zero;
  //   `ALU_OP_DEC,
  //   `ALU_OP_ADD,
  //   `ALU_OP_TEST_EQ,
  //   `ALU_OP_TEST_NEQ: CARRY <= c_carry;
  //   endcase
  // end

  // do whatever is requested by the RTN instruction
//   if (alu_active && i_ins_rtn) begin

//     if (i_set_xm)
//       HST[`ALU_HST_XM] <= 1;

//     if (i_set_carry)
//       CARRY <= i_carry_val;

//   end

// end


// wire [0:0]  read_done;
// wire [0:0]  setup_load_dp_read;
// wire [0:0]  setup_load_dp_write;

// assign read_done_t          = is_mem_read && do_alu_save && ((f_cur +1) == f_last);
// assign read_done           = (phase == 3) && i_stalled && is_mem_read && !do_alu_save && (f_cur == f_last);
// assign setup_load_dp_read  = do_alu_init && is_mem_read && !read_done;
// assign setup_load_dp_write = do_alu_init && is_mem_write && !write_done;
// assign setup_load_dp       = setup_load_dp_read || setup_load_dp_write;
// assign no_extra_cycles     = (extra_cycles == 0);
// assign cycles_to_go        = extra_cycles - 1;

/*****************************************************************************
 *
 * config and unconfig
 *
 ****************************************************************************/

// wire is_bus_config;
// assign is_bus_config = (alu_op == `ALU_OP_COPY) && (reg_dest == `ALU_REG_ADDR);
// wire send_config;
// assign send_config =  alu_active && (phase == 1) && i_ins_alu_op && alu_run && alu_finish;
// wire clean_after_config;
// assign clean_after_config = alu_active && (phase == 3) && o_bus_config && !alu_run;

// always @(posedge i_clk) begin
//   if (i_reset) 
//     o_bus_config <= 0;

//   // $display("send_config %b | is_bus_cfg %b | i_ins_cfg %b", send_config, is_bus_config, i_ins_config);
//   if (send_config && is_bus_config && i_ins_config) begin
//     $display("ALU %0d - =========================== ALU start configure mode", phase);
//     o_bus_config <= 1;
//   end


//   if (clean_after_config) begin
//     $display("ALU %0d - --------------------------- ALU end configure mode %b", phase, i_stalled);
//     o_bus_config <= 0;
//   end

// end


endmodule

`endif