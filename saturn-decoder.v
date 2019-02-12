/******************************************************************************
 *
 * Instruction decoder module
 *
 *****************************************************************************/

`include "def-fields.v"
`include "def-alu.v"

module saturn_decoder(
  i_clk, 
  i_reset,
  i_cycles,
  i_en_dbg,
  i_en_dec,
  i_stalled,
  i_pc,
  i_nibble,

  i_reg_p,

  o_inc_pc,
  o_push,
  o_pop,
  o_dec_error,
  
  o_ins_addr,
  o_ins_decoded,

  o_fields_table,
  o_field,
  o_field_valid,
  o_field_start,
  o_field_last,

  o_alu_op,

  o_reg_dest,
  o_reg_src1,
  o_reg_src2,

  o_direction,
  o_ins_rtn,
  o_set_xm,
  o_set_carry,
  o_en_intr,
  o_carry_val,
  o_ins_set_mode,
  o_mode_dec,
  o_ins_alu_op
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

// instructions related outputs
output  reg [19:0]  o_ins_addr;
output  reg         o_ins_decoded;

output  reg [1:0]   o_fields_table;
output  reg [3:0]   o_field;
output  reg         o_field_valid;
output  reg [3:0]   o_field_start;
output  reg [3:0]   o_field_last;

output  reg [4:0]   o_alu_op;

output  reg [4:0]   o_reg_dest;
output  reg [4:0]   o_reg_src1;
output  reg [4:0]   o_reg_src2;

// generic
output  reg         o_direction;

// rtn specific
output  reg         o_ins_rtn;
output  reg         o_set_xm;
output  reg         o_set_carry;
output  reg         o_carry_val;
output  reg         o_en_intr;

// setdec/hex
output  reg         o_ins_set_mode;
output  reg         o_mode_dec;

// alu_operations
output  reg         o_ins_alu_op;



/*
 * state registers
 */

reg [31:0]  instr_ctr;

initial begin
`ifdef SIM
  // $monitor({"i_clk %b | i_reset %b | i_cycles %d | i_en_dec %b | i_en_exec %b |",
  //          " continue %b | instr_start %b | i_nibble %h"}, 
  //          i_clk, i_reset, i_cycles, i_en_dec, i_en_exec, continue, 
  //          instr_start, i_nibble);
  // $monitor("i_en_dec %b | i_cycles %d | nb %h | cont %b | b0x %b | rtn %b | sxm %b | sc %b | cv %b",
  //          i_en_dec, i_cycles, i_nibble, continue, block_0x, ins_rtn, set_xm, set_carry, carry_val);
`endif  
end

/*
 * debugger
 *
 */

wire [19:0] new_pc;
assign new_pc = i_pc + 1;

wire run_debugger;
assign run_debugger =  !i_reset && i_en_dbg && !i_stalled && !continue;

always @(posedge i_clk) begin
  if (run_debugger) begin
    /*
     * this whole thing is a large print statement
     * THIS PART IS NEVER GENERATED
     */
    `ifdef SIM
    if (o_ins_decoded) begin
      $write("\n%5h ", o_ins_addr);
      if (o_ins_rtn) begin
        $write("RT%s", o_en_intr?"I":"N");
        if (o_set_xm) $write("SXM");
        if (o_set_carry) $write("%sC", o_carry_val?"S":"C");
        $display("");
      end
      if (o_ins_set_mode) begin
        $display("SET%s", o_mode_dec?"DEC":"HEX");
      end
      if (o_ins_alu_op) begin
        
        case (o_reg_dest)
        `ALU_REG_A:    $write("A");
        `ALU_REG_B:    $write("B");
        `ALU_REG_C:    $write("C");
        `ALU_REG_D:    $write("D");
        `ALU_REG_RSTK: $write("RSTK");
        `ALU_REG_R0:   $write("R0");
        `ALU_REG_R1:   $write("R1");
        `ALU_REG_R2:   $write("R2");
        `ALU_REG_R3:   $write("R3");
        `ALU_REG_R4:   $write("R4");
        `ALU_REG_ST:   if (o_alu_op!=`ALU_OP_ZERO) $write("ST");
        `ALU_REG_P:    $write("P");
        default: $write("[dest:%d]", o_reg_dest);
        endcase
        
        case (o_alu_op)
        `ALU_OP_ZERO: if (o_reg_dest==`ALU_REG_ST) $write("CLRST"); else $write("=0");
        `ALU_OP_COPY,
        `ALU_OP_AND,
        `ALU_OP_OR,
        `ALU_OP_INC,
        `ALU_OP_DEC:  $write("=");
        `ALU_OP_EXCH: begin end
        default: $write("[op:%d]", o_alu_op);
        endcase
        
        case (o_alu_op)
        `ALU_OP_COPY,
        `ALU_OP_EXCH,
        `ALU_OP_AND,
        `ALU_OP_OR,
        `ALU_OP_INC,
        `ALU_OP_DEC:
          case (o_reg_src1)
          `ALU_REG_A:    $write("A");
          `ALU_REG_B:    $write("B");
          `ALU_REG_C:    $write("C");
          `ALU_REG_D:    $write("D");
          `ALU_REG_RSTK: $write("RSTK");
          `ALU_REG_R0:   $write("R0");
          `ALU_REG_R1:   $write("R1");
          `ALU_REG_R2:   $write("R2");
          `ALU_REG_R3:   $write("R3");
          `ALU_REG_R4:   $write("R4");
          `ALU_REG_ST:   $write("ST");
          `ALU_REG_P:    $write("P");
          default: $write("[src1:%d]", o_reg_src1);
          endcase
        endcase

        if (o_alu_op == `ALU_OP_EXCH)
          $write("EX");

        case (o_alu_op)
        `ALU_OP_AND,
        `ALU_OP_OR: begin
          case (o_alu_op)
          `ALU_OP_AND: $write("&");
          `ALU_OP_OR:  $write("!");
          default: $write("[op:%d]", o_alu_op);
          endcase
          
          case (o_reg_src2)
          `ALU_REG_A:    $write("A");
          `ALU_REG_B:    $write("B");
          `ALU_REG_C:    $write("C");
          `ALU_REG_D:    $write("D");
          `ALU_REG_RSTK: $write("RSTK");
          default: $write("[src2:%d]", o_reg_src2);
          endcase
        end
        `ALU_OP_INC:  $write("+1");
        `ALU_OP_DEC:  $write("-1");
        `ALU_OP_ZERO,
        `ALU_OP_COPY,
        `ALU_OP_EXCH: begin end
        endcase
        
        // if (!((o_reg_dest == `ALU_REG_RSTK) || (o_reg_src1 == `ALU_REG_RSTK) ||
        //       (o_reg_dest == `ALU_REG_ST)   || (o_reg_src1 == `ALU_REG_ST  ) ||
        //       (o_reg_dest == `ALU_REG_P)    || (o_reg_src1 == `ALU_REG_P   ))) begin
        $write("\t");
        if (o_field_valid)
          case (o_field)
          `FT_FIELD_P: $write("P");
          `FT_FIELD_WP: $write("WP");
          `FT_FIELD_XS: $write("XS");
          `FT_FIELD_X: $write("X");
          `FT_FIELD_S: $write("S");
          `FT_FIELD_M: $write("M");
          `FT_FIELD_B: $write("B");
          `FT_FIELD_W: $write("W");
          `FT_FIELD_A: $write("A");
          endcase
        else
          $write("[f:%d-%h:%h]", o_field, o_field_start, o_field_last);

        $display("");
      end
    end
    $display("new [%5h]--------------------------------------------------------------------", new_pc);  
    `endif
  end
end

/******************************************************************************
 *
 * handle decoding of the fist nibble 
 * that's pretty simple though, will get tougher later on :-)
 *
 *****************************************************************************/

// general variables
reg   continue;
reg   block_0x;
reg   block_0Efx;
reg   block_1x;
reg   block_save_to_R_W;
reg   block_rest_from_R_W;
reg   block_exch_with_R_W;
reg   block_pointer_assign_exch;
reg   block_mem_transfer;
reg   block_pointer_aryth_const;
reg   block_load_pointer_imm;

reg   go_fields_table;

/* lots'o-wires to decode common states
 */

wire  decoder_active;
wire  do_on_first_nibble;
wire  do_on_other_nibbles;

assign decoder_active = !i_reset && i_en_dec && !i_stalled;
assign do_on_first_nibble = decoder_active && !continue;
assign do_on_other_nibbles = decoder_active && continue;

wire  do_block_0x;
wire  do_block_0Efx;
wire  do_block_1x;
wire  do_block_save_to_R_W;
wire  do_block_rest_from_R_W;
wire  do_block_exch_with_R_W;
wire  do_block_Rn_A_C;
wire  do_block_pointer_assign_exch;
wire  do_block_mem_transfer;
wire  do_block_pointer_aryth_const;
wire  do_block_load_pointer_imm;
assign do_block_0x                  = do_on_other_nibbles && block_0x;
assign do_block_0Efx                = do_on_other_nibbles && block_0Efx;
assign do_block_1x                  = do_on_other_nibbles && block_1x;
assign do_block_save_to_R_W         = do_on_other_nibbles && block_save_to_R_W;                  
assign do_block_rest_from_R_W       = do_on_other_nibbles && block_rest_from_R_W;       
assign do_block_exch_with_R_W       = do_on_other_nibbles && block_exch_with_R_W;    
assign do_block_Rn_A_C              = do_on_other_nibbles && 
                                      ( block_save_to_R_W   ||
                                        block_rest_from_R_W ||
                                        block_exch_with_R_W );
assign do_block_pointer_assign_exch = do_on_other_nibbles && block_pointer_assign_exch; 
assign do_block_mem_transfer        = do_on_other_nibbles && block_mem_transfer;        
assign do_block_pointer_aryth_const = do_on_other_nibbles && block_pointer_aryth_const; 
assign do_block_load_pointer_imm    = do_on_other_nibbles && block_load_pointer_imm;    


wire in_fields_table;
assign in_fields_table = go_fields_table && !fields_table_done;

/* most instructions are groupped by sets of 4 with
 * varrying series of registers that are common
 * this generates all the required series from i_nibble
 */


always @(posedge i_clk) begin
  if (i_reset) begin
    continue      <= 0;
    o_inc_pc      <= 1;
    o_dec_error   <= 0;
    o_ins_decoded <= 0;
    o_alu_op      <= 0;
  end
  
  if (decoder_active) begin
    /* 
      * stuff that is always done
      */
    o_inc_pc <= 1; // may be set to 0 later
  end

    /*
      * cleanup
      */ 
  if (do_on_first_nibble) begin
    continue        <= 1;

    o_push          <= 0;
    o_pop           <= 0;

    o_ins_decoded   <= 0;
    // store the address where the instruction starts
    o_ins_addr      <= i_pc;

    // cleanup block variables
    block_0x                   <= 0;
    block_0Efx                 <= 0;
    block_1x                   <= 0;
    block_save_to_R_W          <= 0;
    block_rest_from_R_W        <= 0;
    block_exch_with_R_W        <= 0;
    block_pointer_assign_exch  <= 0;
    block_mem_transfer         <= 0;
    block_pointer_aryth_const  <= 0;
    block_load_pointer_imm     <= 0;

    // cleanup fields table variables
    go_fields_table <= 0;
    o_fields_table  <= 3;
    o_field         <= 0;
    o_field_start   <= 0;
    o_field_last    <= 0;

    o_alu_op        <= 0;

    // cleanup
    o_direction     <= 0;

    o_ins_rtn       <= 0;
    o_set_xm        <= 0;
    o_set_carry     <= 0;
    o_carry_val     <= 0;
    
    o_ins_set_mode  <= 0;
    o_mode_dec      <= 0;

    o_ins_alu_op    <= 0;

    /*
      * x first nibble
      */

    // assign block regs
    case (i_nibble) 
    4'h0: block_0x <= 1;
    4'h1: block_1x <= 1;
    default: begin
      `ifdef SIM
      $display("new_instruction: nibble %h not handled", i_nibble);
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
      o_set_xm       <=  i_nibble == 4'h0;
      o_set_carry    <= !i_nibble[3] && i_nibble[1];
      o_carry_val    <=  i_nibble[1] && i_nibble[0];
      o_en_intr      <=  i_nibble[3];
    end
    4'h4, 4'h5: begin
      o_ins_set_mode <= 1;
      o_mode_dec     <= (i_nibble[0]);
    end
    /* RSTK=C
    * C=RSTK
    * those 2 are alu copy ops between RSTK and C
    */
    4'h6, 6'h7: begin 
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
    4'hE: begin
      block_0x <= 0;
      o_fields_table <= `FT_TABLE_f;
    end
    default: begin
      `ifdef SIM
      $display("block_0x: nibble %h not handled", i_nibble);
      `endif
      o_dec_error <= 1;
    end
    endcase
    continue        <= (i_nibble == 4'hE);
    block_0Efx      <= (i_nibble == 4'hE);
    go_fields_table <= (i_nibble == 4'hE);
    o_ins_decoded   <= (i_nibble != 4'hE);
  end 

  /******************************************************************************
  *
  * 0Ex   R1=R1[&!]R2    table_f
  *
  *****************************************************************************/

  if (do_block_0Efx && !in_fields_table) begin
    o_ins_alu_op  <= 1;
    o_alu_op      <= (!i_nibble[3])?`ALU_OP_AND:`ALU_OP_OR;
    continue      <= 0;
    o_ins_decoded <= 1;
  end

  /******************************************************************************
  *
  * 1x   jump table to other things
  *
  *****************************************************************************/

  if (do_block_1x) begin
    case (i_nibble)
      4'h0: begin
        block_save_to_R_W         <= 1;
      end
      4'h1: 
        block_rest_from_R_W       <= 1;
      4'h2: 
        block_exch_with_R_W       <= 1;
      4'h3: 
        block_pointer_assign_exch <= 1;
      4'h4, 4'h5: 
        block_mem_transfer        <= 1;
      4'h6, 4'h7, 4'h8, 4'hC:
        block_pointer_aryth_const <= 1;
      4'h9, 4'hA, 4'hB, 4'hD, 4'hE, 4'hF:
        block_load_pointer_imm    <= 1;
    endcase
    block_1x <= 0;
  end

  if (do_block_save_to_R_W || do_block_rest_from_R_W) begin
    o_ins_alu_op        <= 1;
    o_alu_op            <= `ALU_OP_COPY;
    continue            <= 0;
    o_ins_decoded       <= 1;
    block_save_to_R_W   <= 0;
    block_rest_from_R_W <= 0;
  end

  if (do_block_exch_with_R_W) begin
    o_ins_alu_op  <= 1;
    o_alu_op      <= `ALU_OP_EXCH;
    continue      <= 0;
    o_ins_decoded <= 1;
  end

  if (do_block_pointer_assign_exch) begin
  end

  if (do_block_mem_transfer) begin
  end

  if (do_block_pointer_aryth_const) begin
  end

  if (do_block_load_pointer_imm) begin
  end

end


/******************************************************************************
*
* set registers from instruction nibble
*
*****************************************************************************/

wire [4:0]		reg_ABCD;
wire [4:0]		reg_BCAC;
wire [4:0]		reg_ABAC;
wire [4:0]		reg_BCCD;
wire [4:0]		reg_D0D1;

assign reg_ABCD = { 2'b000, i_nibble[1:0]};
assign reg_BCAC = { 2'b000, i_nibble[0], !(i_nibble[1] || i_nibble[0])};
assign reg_ABAC = { 2'b000, i_nibble[1] && i_nibble[0], (!i_nibble[1]) && i_nibble[0]};
assign reg_BCCD = { 2'b000, i_nibble[1] || i_nibble[0], (!i_nibble[1]) ^  i_nibble[0]};
assign reg_D0D1 = {3'b0010, (i_nibble[0] && i_nibble[1]) || (i_nibble[2] && i_nibble[3])};

always @(posedge i_clk) begin

  if (i_reset) begin
    o_reg_dest <= 0;
    o_reg_src1 <= 0;
    o_reg_src2 <= 0;
  end

  if (do_on_first_nibble) begin
    // reset values on instruction decode start
    o_reg_dest <= 0;
    o_reg_src1 <= 0;
    o_reg_src2 <= 0;
  end


  /************************************************************************
  *
  * set registers for specific instructions
  *
  ************************************************************************/

  if (do_block_0x) begin
    case (i_nibble)
    4'h6: begin
      o_reg_dest <= `ALU_REG_RSTK;
      o_reg_src1 <= `ALU_REG_C;
    end
    4'h7: begin
      o_reg_dest <= `ALU_REG_C;
      o_reg_src1 <= `ALU_REG_RSTK;
    end
    4'h8: o_reg_dest <= `ALU_REG_ST;
    4'h9, 4'hB: begin
      o_reg_dest <= `ALU_REG_C;
      o_reg_src1 <= `ALU_REG_ST;
    end
    4'hA: begin
      o_reg_dest <= `ALU_REG_ST;
      o_reg_src1 <= `ALU_REG_C;
    end
    4'hC, 4'hD: begin
      o_reg_dest <= `ALU_REG_P;
      o_reg_src1 <= `ALU_REG_P;
    end
    endcase
  end 

  if (do_block_0Efx && !in_fields_table) begin
    o_reg_dest <= i_nibble[2]?reg_BCAC:reg_ABCD;
    o_reg_src1 <= i_nibble[2]?reg_BCAC:reg_ABCD;
    o_reg_src2 <= i_nibble[2]?reg_ABCD:reg_BCAC;
  end   

  if (do_block_save_to_R_W) begin
    o_reg_dest <= {2'b01,  i_nibble[2:0]};
    o_reg_src1 <= {3'b000, i_nibble[3]?2'b10:2'b00};
  end
  
  if (do_block_rest_from_R_W || do_block_exch_with_R_W) begin
    o_reg_dest <= {3'b000, i_nibble[3]?2'b10:2'b00};
    o_reg_src1 <= {2'b01,  i_nibble[2:0]};
  end


end


/******************************************************************************
*
* set fields from instruction nibble
*
*****************************************************************************/

`ifdef SIM
// `define DEBUG_FIELDS_TABLE
`endif

reg fields_table_done;

/* more wires to decode common states.
 * can possibly be made less redundant / faster ?
 */

wire do_fields_table;
assign do_fields_table = decoder_active && go_fields_table && !fields_table_done;

wire table_a;
wire table_b;
wire table_f;
wire table_value;
assign table_a     = (o_fields_table == `FT_TABLE_a);
assign table_b     = (o_fields_table == `FT_TABLE_b);
assign table_f     = (o_fields_table == `FT_TABLE_f);
assign table_value = (o_fields_table == `FT_TABLE_value);

wire do_tables_a_f_b;
assign do_tables_a_f_b = do_fields_table && !table_value;

wire table_f_bit_3;
wire [3:0] table_a_f_b_case_value;
assign table_f_bit_3 = table_f && i_nibble[3];
assign table_a_f_b_case_value = {table_f_bit_3, i_nibble[2:0]};

/* value generation for debug
 */

wire table_a_nb_ok;
wire table_b_nb_ok;
wire table_f_cond;
wire table_f_nb_ok;
wire table_a_f_b_nb_ok;
assign table_a_nb_ok = table_a && !i_nibble[3];   
assign table_b_nb_ok = table_b &&  i_nibble[3];
assign table_f_cond  = !i_nibble[3] || (i_nibble == 4'hF);
assign table_f_nb_ok = table_f && table_f_cond;
assign table_a_f_b_nb_ok = table_a_nb_ok || table_b_nb_ok || table_f_nb_ok;

/* here we go
 */ 

always @(posedge i_clk) begin
  if (i_reset || do_on_first_nibble) begin
    // reset values
    fields_table_done <= 0;
    o_field           <= 0;
    o_field_valid     <= 0;
    o_field_start     <= 0;
    o_field_last      <= 0;
  end

  /******************************************************************************
  *
  * set field for specific instructions
  *
  *****************************************************************************/

  if (do_block_0x) begin
    case (i_nibble)
    4'h6, 4'h7: begin
      // virtual A
      o_field_start <= 0;
      o_field_last  <= 4;
    end
    4'h8, 4'h9, 4'hA, 4'hB: begin
      // ST is 0-3
      o_field_start <= 0;
      o_field_last  <= 3;
    end
    endcase
  end

  if (do_block_Rn_A_C) begin
    o_field_start <= 0;
    o_field_last  <= 15;
  end
  

  /******************************************************************************
  *
  * set field from a table
  *
  *
  *****************************************************************************/

  `ifdef DEBUG_FIELDS_TABLE
  if (do_tables_a_f_b) begin
    // debug info
    $display("====== fields_table | table %h | nibble %b", o_fields_table, i_nibble);
    $display("table_a     : %b", table_a_nb_ok);
    $display("table_b     : %b", table_b_nb_ok);
    $display("table_f_cond: %b", table_f_cond);
    $display("table_f     : %b", table_f_nb_ok);
    // $display("table_f nbl : %h", {4{o_fields_table == `FT_TABLE_f}} );
    $display("table_f val : %h", table_f_nibble_value);
    $display("case nibble : %h", table_a_f_b_case_value);
  end
  `endif


  // 
  if (do_tables_a_f_b) begin
    case (table_a_f_b_case_value)
    4'h0: begin 
      o_field       <= `FT_FIELD_P;
      o_field_start <= i_reg_p;
      o_field_last  <= i_reg_p;
      `ifdef DEBUG_FIELDS_TABLE
      $display("fields_table: field P (%h)", i_reg_p);
      `endif
    end
    4'h1: begin 
      o_field       <= `FT_FIELD_WP;
      o_field_start <= 0;
      o_field_last  <= i_reg_p;
      `ifdef DEBUG_FIELDS_TABLE
      $display("fields_table: field WP (0-%h)", i_reg_p);
      `endif
    end
    4'h2: begin 
      o_field       <= `FT_FIELD_XS;
      o_field_start <= 2;
      o_field_last  <= 2;
      `ifdef DEBUG_FIELDS_TABLE
      $display("fields_table: field XS");
      `endif
    end
    4'h3: begin 
      o_field       <= `FT_FIELD_X;
      o_field_start <= 0;
      o_field_last  <= 2;
      `ifdef DEBUG_FIELDS_TABLE
      $display("fields_table: field X");
      `endif
    end
    4'h4: begin 
      o_field       <= `FT_FIELD_S;
      o_field_start <= 15;
      o_field_last  <= 15;
      `ifdef DEBUG_FIELDS_TABLE
      $display("fields_table: field S");
      `endif
    end
    4'h5: begin 
      o_field       <= `FT_FIELD_M;
      o_field_start <= 3;
      o_field_last  <= 14;
      `ifdef DEBUG_FIELDS_TABLE
      $display("fields_table: field M");
      `endif
    end
    4'h6: begin 
      o_field       <= `FT_FIELD_B;
      o_field_start <= 0;
      o_field_last  <= 1;
      `ifdef DEBUG_FIELDS_TABLE
      $display("fields_table: field B");
      `endif
    end
    4'h7: begin 
      o_field       <= `FT_FIELD_W;
      o_field_start <= 0;
      o_field_last  <= 15;
      `ifdef DEBUG_FIELDS_TABLE
      $display("fields_table: field W");
      `endif
    end
    4'hF: begin
      o_field       <= `FT_FIELD_A;
      o_field_start <= 0;
      o_field_last  <= 4;
      `ifdef DEBUG_FIELDS_TABLE
      $display("fields_table: field A");
      `endif
    end
    `ifdef SIM
    default: begin
      o_dec_error <= 1;
      $display("fields_table: table %h nibble %h not handled", o_fields_table, i_nibble);
    end
    `endif
    endcase
    o_field_valid     <= 1;
    fields_table_done <= 1;
  end 
end


endmodule