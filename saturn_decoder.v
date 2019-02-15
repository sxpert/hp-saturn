/******************************************************************************
 *
 * Instruction decoder module
 *
 *****************************************************************************/

`include "def-fields.v"
`include "def-alu.v"

module saturn_decoder(
  i_clk, i_reset, i_cycles, i_en_dbg, i_en_dec, i_stalled,
  i_pc, i_nibble,

  i_reg_p,

  o_inc_pc, o_push, o_pop,
  o_dec_error,
`ifdef SIM
  o_unimplemented,
`endif
  o_alu_debug,

  o_ins_addr, o_ins_decoded,

  o_fields_table, o_field, o_field_valid, o_field_start, o_field_last,
  o_imm_value,

  o_alu_op, o_alu_no_stall, o_reg_dest, o_reg_src1, o_reg_src2,

  o_ins_rtn, o_set_xm, o_en_intr, 
  o_set_carry, o_test_carry, o_carry_val,
  o_ins_set_mode, o_mode_dec,
  o_ins_alu_op,

  o_dbg_nibbles, o_dbg_nb_nbls, o_mem_load, o_mem_pos
);

/*
 * module input / output ports
 */
input   wire [0:0]  i_clk;
input   wire [0:0]  i_reset;
input   wire [31:0] i_cycles;
input   wire        i_en_dbg;
input   wire        i_en_dec;
input   wire        i_stalled;
input   wire [19:0] i_pc;
input   wire [3:0]  i_nibble;

input   wire [3:0]  i_reg_p;

output  reg         o_inc_pc;
output  reg         o_push;
output  reg         o_pop;
output  reg         o_dec_error;
`ifdef SIM
output  reg  [0:0]  o_unimplemented;
`endif
output  reg         o_alu_debug;

// instructions related outputs
output  reg [19:0]  o_ins_addr;
output  reg         o_ins_decoded;

output  reg [1:0]   o_fields_table;
output  reg [3:0]   o_field;
output  reg         o_field_valid;
output  reg [3:0]   o_field_start;
output  reg [3:0]   o_field_last;
output  reg [3:0]   o_imm_value;

output  reg [4:0]   o_alu_op;
output  reg [0:0]   o_alu_no_stall;
output  reg [4:0]   o_reg_dest;
output  reg [4:0]   o_reg_src1;
output  reg [4:0]   o_reg_src2;

// rtn specific
output  reg         o_ins_rtn;
output  reg         o_set_xm;
output  reg         o_set_carry;
output  reg         o_test_carry;
output  reg         o_carry_val;
output  reg         o_en_intr;

// setdec/hex
output  reg         o_ins_set_mode;
output  reg         o_mode_dec;

// alu_operations
output  reg         o_ins_alu_op;

/* data used by the debugger
 *
 */
output  reg [(21*4-1):0] o_dbg_nibbles;
output  reg [4:0]        o_dbg_nb_nbls;
output  reg [63:0]       o_mem_load;
output  reg [4:0]        o_mem_pos;


/*
 * state registers
 */

reg [31:0]  inst_counter;
reg [0:0]   next_nibble;
reg [4:0]   inst_cycles;

reg         inval_opcode_regs;


initial begin
`ifdef SIM
  // $monitor({"i_clk %b | i_reset %b | i_cycles %d | i_en_dec %b | i_en_exec %b |",
  //          " next_nibble %b | instr_start %b | i_nibble %h"}, 
  //          i_clk, i_reset, i_cycles, i_en_dec, i_en_exec, next_nibble, 
  //          instr_start, i_nibble);
  // $monitor("i_en_dec %b | i_cycles %d | nb %h | cont %b | b0x %b | rtn %b | sxm %b | sc %b | cv %b",
  //          i_en_dec, i_cycles, i_nibble, next_nibble, block_0x, ins_rtn, set_xm, set_carry, carry_val);
`endif  
end

`include "saturn_decoder_debugger.v"

/******************************************************************************
 *
 * handles part of the instruction decoding,  
 * acts as the main FSM
 *
 *****************************************************************************/

// general variables
reg   use_fields_tbl;

wire  count_cycles;
wire  decoder_active;
wire  decoder_stalled;
wire  do_on_first_nibble;
wire  do_on_other_nibbles;

assign count_cycles        = !i_reset && i_en_dec && (next_nibble || i_stalled);
assign decoder_active      = !i_reset && i_en_dec && !i_stalled;
assign decoder_stalled     = !i_reset && i_en_dec &&  i_stalled;
assign do_on_first_nibble  = decoder_active && !next_nibble;
assign do_on_other_nibbles = decoder_active && next_nibble;

// all regs and wires for the decoder states
`include "saturn_decoder_block_vars.v"

/*
 * variables specific to a particular use
 */

reg [4:0]   mem_load_max;

/* most instructions are groupped by sets of 4 with
 * varrying series of registers that are common
 * this generates all the required series from i_nibble
 */

wire [4:0]   dbg_write_pos;
assign dbg_write_pos = (!next_nibble?0:o_dbg_nb_nbls);

always @(posedge i_clk) begin

  if (i_reset) begin
    inst_cycles     <= 0;
    inst_counter    <= 0;
    next_nibble     <= 0;
    use_fields_tbl  <= 0;
    o_inc_pc        <= 1;
    o_dec_error     <= 0;
`ifdef SIM
    o_unimplemented <= 0;
`endif
    o_alu_debug     <= 0;
    o_ins_decoded   <= 0;
    o_alu_op        <= 0;
    o_ins_rtn       <= 0;
    o_push          <= 0;
    o_pop           <= 0;
  end
  
  if (decoder_active) begin
    /* 
      * stuff that is always done
      */
    `ifdef SIM
    // $display("DEC_RUN  2: nibble %h", i_nibble);
    `endif
    o_inc_pc                          <= 1; // may be set to 0 later
    o_dbg_nibbles[dbg_write_pos*4+:4] <= i_nibble;
    o_dbg_nb_nbls                     <= o_dbg_nb_nbls + 1;
  end

  // if (decoder_stalled) begin
  //   $display("DEC_STAL 2:");
  // end

  if (count_cycles) begin
    inst_cycles <= inst_cycles + 1;
  end

    /*
      * cleanup
      */ 
  if (do_on_first_nibble) begin
    inst_counter    <= inst_counter + 1;
    inst_cycles     <= 1;
    next_nibble     <= 1;
    use_fields_tbl  <= 0;
    o_alu_debug     <= 0;

    o_push          <= 0;
    o_pop           <= 0;

    o_ins_decoded   <= 0;
    `ifdef SIM
    o_unimplemented <= 1;
    `endif
    // store the address where the instruction starts
    o_ins_addr      <= i_pc;

    // decoder block states

    // complain if blocks are not clean
`ifdef SIM
    if (block_0x)   $display("block_0x NOT CLEAN");
    if (block_0Efx) $display("block_0Efx NOT CLEAN");
    if (block_1x)   $display("block_1x NOT CLEAN");
    if (block_save_to_R_W)         $display("block_save_to_R_W NOT CLEAN");
    if (block_rest_from_R_W)       $display("block_rest_from_R_W NOT CLEAN");
    if (block_exch_with_R_W)       $display("block_exch_with_R_W NOT CLEAN");
    if (block_pointer_assign_exch) $display("block_pointer_assign_exch NOT CLEAN");
    if (block_mem_transfer)        $display("block_mem_transfer NOT CLEAN");
    if (block_pointer_arith_const) $display("block_pointer_arith_const NOT CLEAN");
    if (block_2x)   $display("block_2x NOT CLEAN");
    if (block_3x)   $display("block_load_c_hex NOT CLEAN");

    if (block_8x)   $display("block_8x   NOT CLEAN");
    if (block_80x)  $display("block_80x  NOT CLEAN");
    if (block_80Cx) $display("block_80Cx NOT CLEAN");
    if (block_82x)  $display("block_82x  NOT CLEAN");

    if (block_Ax)   $display("block_Ax   NOT CLEAN");

    if (block_Dx)   $display("block_Dx   NOT CLEAN");

    if (block_Fx)   

    if (block_load_reg_imm) $display("block_load_reg_imm   NOT CLEAN");
    if (block_jmp) $display("block_jmp   NOT CLEAN");
    if (block_sr_bit) $display("block_sr_bit   NOT CLEAN");

    if (o_ins_rtn) $display("o_ins_rtn   STILL ASSERTED");
`endif
    // decoder subroutine states

    block_load_reg_imm         <= 0;
    block_jmp                  <= 0;
    block_sr_bit               <= 0;

    // cleanup fields table variables
    go_fields_table <= 0;
    o_fields_table  <= 3;

    o_alu_op        <= 0;
    o_alu_no_stall  <= 0;

    o_ins_rtn       <= 0;
    o_set_xm        <= 0;
    o_set_carry     <= 0;
    o_carry_val     <= 0;
    
    o_ins_set_mode  <= 0;
    o_mode_dec      <= 0;

    o_ins_alu_op    <= 0;

    o_dbg_nb_nbls   <= 1;
    o_mem_pos       <= 0;

    /*
      * x first nibble
      */

    // assign block regs
    case (i_nibble) 
    4'h0: block_0x <= 1;
    4'h1: block_1x <= 1;
    4'h2: block_2x <= 1;
    4'h3: block_3x <= 1;
    4'h4, 4'h5: begin 
      // 400 RTNC
      // 420 NOP3
      // 4xy GOC
      // 500 RTNNC
      // 5xy GONC
      o_alu_no_stall <= 1;
      o_alu_op       <= `ALU_OP_JMP_REL2;
      mem_load_max   <= 1;
      o_mem_pos      <= 0;
      o_test_carry   <= 1;
      o_carry_val    <= !i_nibble[0];
      block_jmp      <= 1;
    end
    4'h6, 4'h7: begin
      // 6xxx GOTO
      // 7xxx GOSUB
      o_alu_no_stall  <= 1;
      o_alu_op        <= `ALU_OP_JMP_REL3;
      mem_load_max    <= 2;
      o_mem_pos       <= 0;
      o_push          <= i_nibble[0];  
      block_jmp       <= 1;
      `ifdef SIM
      o_unimplemented <= 0;
      `endif
    end
    4'h8: block_8x   <= 1;
    4'hA: begin
      go_fields_table <= 1;
      // we don't know, safe bet is table a, but could be table b, 
      // works either way, table is fixed on the next nibble
      o_fields_table  <= `FT_TABLE_a;
      block_Ax        <= 1;
    end
    4'hD: block_Dx   <= 1;
    4'hF: block_Fx   <= 1;
    default: begin
      `ifdef SIM
      $display("DEC_INIT 2: nibble %h not handled", i_nibble);
      `endif
      o_dec_error <= 1;
    end
    endcase
  end


  /******************************************************************************
  *
  * 0x
  *
  * 00   RTNSXM        08   CLRST
  * 01   RTN           09   C=ST
  * 02   RTNSC         0A   ST=C
  * 03   RTNCC         0B   CSTEX
  * 04   SETHEX        0C   P=P+1
  * 05   SETDEC        0D   P=P-1
  * 06   RSTK=C
  * 07   C=RSTK        0F   RTI
  *
  *****************************************************************************/

  if (do_block_0x) begin
    case (i_nibble)
      4'h0, 4'h1, 4'h2, 4'h3, 4'hF: begin
        o_ins_rtn      <= 1;
        o_pop          <= 1;
        o_set_xm       <=  i_nibble == 4'h0;
        o_set_carry    <= !i_nibble[3] &&  i_nibble[1];
        o_carry_val    <=  i_nibble[1] && !i_nibble[0];
        o_en_intr      <=  i_nibble[3];
`ifdef SIM
        o_unimplemented <= i_nibble[3];
`endif
      end
      4'h4, 4'h5: begin
        // 04 SETHEX
        // 05 SETDEC
        o_ins_set_mode  <= 1;
        o_mode_dec      <= (i_nibble[0]);
`ifdef SIM
        o_unimplemented <= 0;
`endif
      end
      4'h6, 4'h7: begin 
        // 06 RSTK=C
        // 07 C=RSTK
        // those 2 are alu copy ops between RSTK and C
        o_ins_alu_op   <= 1;
        o_alu_op       <= `ALU_OP_COPY;
        o_push         <= !i_nibble[0];
        o_pop          <=  i_nibble[0];
      end
      4'h8: begin
        o_ins_alu_op <= 1;
        o_alu_op     <= `ALU_OP_ZERO;
      end
      4'h9, 4'hA: begin
        o_ins_alu_op <= 1;
        o_alu_op     <= `ALU_OP_COPY;
      end
      4'hB: begin
        o_ins_alu_op <= 1;
        o_alu_op     <= `ALU_OP_EXCH;
      end
      4'hC, 4'hD: begin
        o_ins_alu_op <= 1;
        o_alu_op     <= i_nibble[0]?`ALU_OP_DEC:`ALU_OP_INC;
      end
      4'hE: o_fields_table <= `FT_TABLE_f;
      default: begin
        `ifdef SIM
        $display("block_0x: nibble %h not handled", i_nibble);
        `endif
        o_dec_error <= 1;
      end
    endcase
    next_nibble     <= (i_nibble == 4'hE);
    block_0Efx      <= (i_nibble == 4'hE);
    go_fields_table <= (i_nibble == 4'hE);
    o_ins_decoded   <= (i_nibble != 4'hE);
    block_0x        <= 0;
  end 

  /******************************************************************************
  *
  * 0Ex   R1=R1[&!]R2    table_f
  *
  *****************************************************************************/

  if (do_block_0Efx && !in_fields_table) begin
    o_ins_alu_op  <= 1;
    o_alu_op      <= (!i_nibble[3])?`ALU_OP_AND:`ALU_OP_OR;
    next_nibble   <= 0;
    o_ins_decoded <= 1;
  end

  /******************************************************************************
  *
  * 1x   jump table to other things
  *
  *****************************************************************************/

  if (do_block_1x) begin
    case (i_nibble)
      4'h0:       // save     A/C to   Rn W
        block_save_to_R_W         <= 1;
      4'h1:       // restore  A/C from Rn W 
        block_rest_from_R_W       <= 1;
      4'h2:       // exchange A/C with Rn W
        block_exch_with_R_W       <= 1;
      4'h3:       // move/exch A/C with Dn A/[0:3]
        block_pointer_assign_exch <= 1;
      4'h4, 4'h5: // DAT[01]=[AC] <field>
      begin
        $display("block_1x %h", i_nibble);
        block_mem_transfer        <= 1;
        o_fields_table            <= i_nibble[0]?`FT_TABLE_value:`FT_TABLE_f;
        use_fields_tbl            <= i_nibble[0];
      end
      4'h6, 4'h7, 
      4'h8, 4'hC: // D[01]=D[01][+-]  n+1;
      begin
        block_pointer_arith_const <= 1;
        o_ins_alu_op              <= 1;
        o_alu_op                  <= i_nibble[1]?`ALU_OP_ADD:`ALU_OP_SUB;
      end
      4'h9, 4'hA, 
      4'hB, 4'hD, 
      4'hE, 4'hF: // D[0]=([245]) <stuff>    
      begin
        mem_load_max              <= {2'b00, i_nibble[1], !i_nibble[1], i_nibble[1] && i_nibble[0]};
        o_mem_pos                 <= 0;
        block_load_reg_imm        <= 1;
        o_alu_no_stall            <= 1;
        o_alu_op                  <= `ALU_OP_COPY;
`ifdef SIM
        o_unimplemented           <= 0;
`endif
      end
    endcase
    block_1x <= 0;
  end

  if (do_block_save_to_R_W || do_block_rest_from_R_W) begin
    o_ins_alu_op        <= 1;
    o_alu_op            <= `ALU_OP_COPY;
    next_nibble         <= 0;
    o_ins_decoded       <= 1;
    block_save_to_R_W   <= 0;
    block_rest_from_R_W <= 0;
  end

  if (do_block_exch_with_R_W) begin
    o_ins_alu_op  <= 1;
    o_alu_op      <= `ALU_OP_EXCH;
    next_nibble      <= 0;
    o_ins_decoded <= 1;
  end

  if (do_block_pointer_assign_exch) begin
    o_ins_alu_op  <= 1;
    o_alu_op      <= i_nibble[1]?`ALU_OP_EXCH:`ALU_OP_COPY;
    next_nibble      <= 0;
    o_ins_decoded <= 1;
  end

  if (do_block_mem_transfer) begin
    $display("block_mem_transfer nibble %h | use_tbl %b", i_nibble, use_fields_tbl);
    o_ins_alu_op    <= 1;
    o_alu_debug     <= 1;
    o_alu_op        <= `ALU_OP_COPY;
    // we next_nibble if we need the fields table (nibble2 was 5)
    go_fields_table <= use_fields_tbl;
    next_nibble     <= use_fields_tbl;
    use_fields_tbl  <= 0;
    o_ins_decoded   <= !(use_fields_tbl);
    block_mem_transfer <= use_fields_tbl;
  end

  if (do_block_pointer_arith_const) begin
    next_nibble     <= 0;
    o_imm_value     <= i_nibble;
    o_ins_decoded   <= 1;
  end

  if (do_block_2x) begin
    o_ins_alu_op    <= 1;
    o_alu_op        <= `ALU_OP_COPY;
    o_imm_value     <= i_nibble;
    next_nibble     <= 0;
    o_ins_decoded   <= 1;
    `ifdef SIM
    o_unimplemented <= 0;
    `endif
    block_2x        <= 0;
  end

  if (do_block_3x) begin
    // $write("block load C hex %h\n", i_nibble);
    mem_load_max       <= i_nibble + 1;
    o_mem_pos          <= 0;
    o_alu_no_stall     <= 1;
    o_alu_op           <= `ALU_OP_COPY;
    block_load_reg_imm <= 1;
    block_3x           <= 0;
`ifdef SIM
    o_unimplemented    <= 0;
`endif
  end

`include "saturn_decoder_block_8.v"

  if (do_block_Ax) begin
    o_fields_table <= i_nibble[3]?`FT_TABLE_b:`FT_TABLE_a;
    block_Aax      <= !i_nibble[3];
    block_Abx      <=  i_nibble[3];
    block_Ax       <= 0;
  end

  if (do_block_Aax) begin
    $display("block_Aax %h", i_nibble);
    o_dec_error <= 1;
  end

  if (do_block_Abx) begin
    o_ins_alu_op    <= 1;
    o_alu_op        <= (i_nibble[3] && i_nibble[2])?`ALU_OP_EXCH:`ALU_OP_COPY;
    next_nibble     <= 0;
    o_ins_decoded   <= 1;
`ifdef SIM
    o_unimplemented <= 0;
`endif
    block_Abx       <= 0;
  end

  if (do_block_Dx) begin
    $display("block_Dx %h", i_nibble);
    o_fields_table  <= `FT_TABLE_f;
    o_ins_alu_op    <= 1;
    o_alu_op        <= (i_nibble[3] && i_nibble[2])?`ALU_OP_EXCH:`ALU_OP_COPY;
    next_nibble     <= 0;
    o_ins_decoded   <= 1;
`ifdef SIM
    // o_unimplemented <= 0;
`endif
    block_Dx       <= 0;   
  end

  if (do_block_Fx) begin
    case (i_nibble)
      4'h8, 4'h9, 4'hA, 4'hB: // r=-r   A
      begin
        o_fields_table <= `FT_TABLE_f;
        //o_alu_debug    <= 1;
        o_ins_alu_op   <= 1;
        o_alu_op       <= `ALU_OP_2CMPL;
        next_nibble    <= 0;
        o_ins_decoded  <= 1;      
      end
      default: begin
        $display("block_Fx %h error", i_nibble);
        o_dec_error    <= 1;
      end
    endcase
    block_Fx           <= 0;
  end

  // utilities

  if (do_load_reg_imm) begin
    // $write("load reg imm %h | ", i_nibble);
    // $write("pos %d | max %d | ", o_mem_pos, mem_load_max);
    // $write("next %b | dec %b | ", (o_mem_pos+1) != mem_load_max, (o_mem_pos+1) == mem_load_max);
    // $write("\n");
    o_ins_alu_op               <= 1;
    o_imm_value                <= i_nibble;
    o_mem_load[o_mem_pos*4+:4] <= i_nibble;
    o_mem_pos                  <= o_mem_pos + 1;
    next_nibble                <= (o_mem_pos+1) != mem_load_max;
    o_ins_decoded              <= (o_mem_pos+1) == mem_load_max;
  end

  if (do_block_jmp) begin
    o_ins_alu_op               <= 1;
    o_imm_value                <= i_nibble;
    o_mem_load[o_mem_pos*4+:4] <= i_nibble;
    o_mem_pos                  <= o_mem_pos + 1;
    next_nibble                <= mem_load_max != o_mem_pos;
    o_ins_decoded              <= mem_load_max == o_mem_pos;

  end

  if (do_block_sr_bit) begin
    o_ins_alu_op               <= 1;
    o_imm_value                <= i_nibble;
    o_mem_load[3:0]            <= i_nibble;
    o_mem_pos                  <= 1;
    next_nibble                <= 0;
    o_ins_decoded              <= 1;
  end

end

`include "saturn_decoder_registers.v"
`include "saturn_decoder_fields.v"


endmodule