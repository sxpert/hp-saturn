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
  o_dec_error,
  
  o_ins_addr,
  o_ins_decoded,

  o_fields_table,
  o_field,
  o_field_start,
  o_field_last,

  o_alu_op,

  o_direction,
  o_ins_rtn,
  o_set_xm,
  o_set_carry,
  o_carry_val,
  o_ins_set_mode,
  o_mode_dec,
  o_ins_rstk_c,
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
output  reg         o_dec_error;

// instructions related outputs
output  reg [19:0]  o_ins_addr;
output  reg         o_ins_decoded;

output  reg [1:0]   o_fields_table;
output  reg [3:0]   o_field;
output  reg [3:0]   o_field_start;
output  reg [3:0]   o_field_last;

output  reg [4:0]   o_alu_op;

// generic
output  reg         o_direction;

// rtn specific
output  reg         o_ins_rtn;
output  reg         o_set_xm;
output  reg         o_set_carry;
output  reg         o_carry_val;

// setdec/hex
output  reg         o_ins_set_mode;
output  reg         o_mode_dec;

// rstk and c
output  reg         o_ins_rstk_c; 

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

always @(posedge i_clk) begin
  if (!i_reset && i_en_dbg && !i_stalled)
    if (!continue) begin
      `ifdef SIM
      $display("-------------------------------------------------------------------------------");  
      if (o_ins_decoded) begin
        $write("%5h ", o_ins_addr);
        if (o_ins_rtn) begin
          $write("RTN");
          if (o_set_xm) $write("SXM");
          if (o_set_carry) $write("%sC", o_carry_val?"S":"C");
          $display("");
        end
        if (o_ins_set_mode) begin
          $display("SET%s", o_mode_dec?"DEC":"HEX");
        end
        if (o_ins_rstk_c) begin
          $display("%s", o_direction?"C=RSTK":"RSTK=C");
        end
        if (o_ins_alu_op) begin
          $display("an alu operation (debugger code missing)");
        end
      end
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
reg         continue;
reg         block_0x;
reg         block_0Efx;

reg         fields_table;


always @(posedge i_clk) begin
  if (i_reset) begin
    continue      <= 0;
    o_inc_pc      <= 1;
    o_dec_error   <= 0;
    o_ins_decoded <= 0;

  end else begin
    if (i_en_dec && !i_stalled) begin

      /* 
       * stuff that is always done
       */
      o_inc_pc <= 1; // may be set to 0 later

      /*
       * cleanup
       */ 
      if (!continue) begin
        continue       <= 1;
        $display("resetting o_ins_decoded");
        o_ins_decoded  <= 0;
        // store the address where the instruction starts
        o_ins_addr     <= i_pc;

        // cleanup block variables
        block_0x       <= 0;
        block_0Efx     <= 0;

        // cleanup fields table variables
        fields_table   <= 0;
        o_fields_table <= 3;
        o_field        <= 0;
        o_field_start  <= 0;
        o_field_last   <= 0;

        o_alu_op       <= 0;

        // cleanup
        o_direction    <= 0;

        o_ins_rtn      <= 0;
        o_set_xm       <= 0;
        o_set_carry    <= 0;
        o_carry_val    <= 0;
        
        o_ins_set_mode <= 0;
        o_mode_dec     <= 0;
        
        o_ins_rstk_c   <= 0;

        o_ins_alu_op   <= 0;
      end

      /*
       * x first nibble
       */

      if (!continue) begin
        // assign block regs
        case (i_nibble) 
        4'h0: block_0x <= 1;
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
      * 00   RTNSXM
      * 01   RTN
      * 02   RTNSC
      * 03   RTNCC
      * 04   SETHEX
      * 05   SETDEC
      * 06   RSTK=C
      * 07   C=RSTK
      *
      *****************************************************************************/

      if (continue && block_0x) begin
        case (i_nibble)
        4'h0, 4'h1, 4'h2, 4'h3: begin
          o_ins_rtn      <= 1;
          o_set_xm       <= (i_nibble == 4'h0);
          o_set_carry    <= (i_nibble[3:1] == 1);
          o_carry_val    <= (i_nibble[1] && i_nibble[0]);
        end
        4'h4, 4'h5: begin
          o_ins_set_mode <= 1;
          o_mode_dec     <= (i_nibble[0]);
        end
        4'h6, 6'h7: begin
          o_ins_rstk_c   <= 1;
          o_direction    <= (i_nibble[0]);
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
        continue       <= (i_nibble == 4'hE);
        block_0Efx     <= (i_nibble == 4'hE);
        fields_table   <= (i_nibble == 4'hE);
        o_ins_decoded  <= (i_nibble != 4'hE);
      end 

      /******************************************************************************
      *
      * 0Ex
      *
      *
      *****************************************************************************/

      if (continue && block_0Efx && !fields_table) begin
        o_ins_alu_op  <= 1;
        o_alu_op      <= (!i_nibble[3])?`ALU_OP_AND:`ALU_OP_OR;
        continue      <= 0;
        o_ins_decoded <= 1;
      end

      /******************************************************************************
      *
      * fields f table
      *
      *
      *****************************************************************************/

`ifdef SIM
//`define DEBUG_FIELDS_TABLE
`endif

      if (continue && fields_table) begin
        if (fields_table != `FT_TABLE_value) begin

          // debug info

          `ifdef DEBUG_FIELDS_TABLE
          $display("====== fields_table | table %h | nibble %b", o_fields_table, i_nibble);
          $display("table_a     : %b", ((o_fields_table == `FT_TABLE_a) &&  (!i_nibble[3])));
          $display("table_b     : %b", ((o_fields_table == `FT_TABLE_b) &&  ( i_nibble[3])));
          $display("table_f_cond: %b", ((!i_nibble[3])  || (i_nibble == 4'hF)));
          $display("table_f     : %b", ((o_fields_table == `FT_TABLE_f) && ((!i_nibble[3])  || (i_nibble == 4'hF) )));
          $display("table_f nbl : %h", {4{o_fields_table == `FT_TABLE_f}} );
          $display("table_f val : %h", (i_nibble & {4{o_fields_table == `FT_TABLE_f}}) );
          $display("case nibble : %h", ((i_nibble & 4'h7) | (i_nibble & {4{fields_table == `FT_TABLE_f}})) );
          `endif

          // 

          if (((o_fields_table == `FT_TABLE_a) &&  (!i_nibble[3])) ||
              ((o_fields_table == `FT_TABLE_b) &&  ( i_nibble[3])) ||
              ((o_fields_table == `FT_TABLE_f) && ((!i_nibble[3])  || (i_nibble == 4'hF) ))) begin
            case ((i_nibble & 4'h7) | (i_nibble & {4{o_fields_table == `FT_TABLE_f}}))
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
              if (o_fields_table == `FT_TABLE_f) begin
                o_field       <= `FT_FIELD_A;
                o_field_start <= 0;
                o_field_last  <= 4;
                `ifdef DEBUG_FIELDS_TABLE
                $display("fields_table: field A");
                `endif
              end else begin
                // should never get here
                o_dec_error <= 1;
                `ifdef SIM
                $display("fields_table: table %h nibble %h", o_fields_table, i_nibble);
                `endif
              end
            end
            default: begin
              o_dec_error <= 1;
              `ifdef SIM
              $display("fields_table: table %h nibble %h not handled", o_fields_table, i_nibble);
              `endif
            end
            endcase
          end else begin
            o_dec_error <= 1;
            `ifdef SIM
            $display("fields_table: table %h invalid nibble %h", o_fields_table, i_nibble);
            `endif
          end
        end else begin
          o_dec_error <= 1;
          `ifdef SIM
          $display("fields_table: there is nothing to decode for table FT_TABLE_value");
          `endif
        end
        fields_table <= 0;
      end


    end
  end
end


endmodule