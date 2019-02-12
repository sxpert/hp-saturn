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

always @(posedge i_clk) begin
  if (!i_reset && i_en_dbg && !i_stalled)
    if (!continue) begin
      `ifdef SIM
      $display("\n-------------------------------------------------------------------------------");  
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
        if (o_ins_alu_op) begin
          
          case (o_reg_dest)
          `ALU_REG_A:    $write("A");
          `ALU_REG_C:    $write("C");
          `ALU_REG_RSTK: $write("RSTK");
          `ALU_REG_ST:   if (o_alu_op!=`ALU_OP_ZERO) $write("ST");
          default: $write("[dest:%d]", o_reg_dest);
          endcase
          
          case (o_alu_op)
          `ALU_OP_ZERO: if (o_reg_dest==`ALU_REG_ST) $write("CLRST"); else $write("=0");
          `ALU_OP_COPY: $write("=");
          `ALU_OP_EXCH: begin end
          default: $write("[op:%d]", o_alu_op);
          endcase
          
          case (o_alu_op)
          `ALU_OP_COPY,
          `ALU_OP_EXCH,
          `ALU_OP_AND,
          `ALU_OP_OR:
            case (o_reg_src1)
            `ALU_REG_A:    $write("A");
            `ALU_REG_C:    $write("C");
            `ALU_REG_RSTK: $write("RSTK");
            `ALU_REG_ST:   $write("ST");
            default: $write("[src1:%d]", o_reg_src1);
            endcase
          endcase

          if (o_alu_op == `ALU_OP_EXCH)
            $write("EX");

          case (o_alu_op)
          `ALU_OP_AND,
          `ALU_OP_OR: begin
            case (o_alu_op)
            default: $write("[op:%d]", o_alu_op);
            endcase
            
            case (o_reg_src2)
            `ALU_REG_A:    $write("A");
            `ALU_REG_C:    $write("C");
            `ALU_REG_RSTK: $write("RSTK");
            default: $write("[src2:%d]", o_reg_src2);
            endcase
          end
          endcase
          
          if (!((o_reg_dest == `ALU_REG_RSTK) || (o_reg_src1 == `ALU_REG_RSTK) ||
                (o_reg_dest == `ALU_REG_ST)   || (o_reg_src1 == `ALU_REG_ST  ))) begin
            $write("\t");
            case (o_field)
            default: $write("[f:%d]", o_field);
            endcase
          end

          $display("");
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
    o_alu_op      <= 0;
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

        o_push         <= 0;
        o_pop          <= 0;

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
    end
  end
end


/******************************************************************************
*
* set registers from instruction nibble
*
*****************************************************************************/

always @(posedge i_clk) begin
  if (i_reset) begin
    o_reg_dest <= 0;
    o_reg_src1 <= 0;
    o_reg_src2 <= 0;
  end else begin

    // reset values on instruction decode start
    if (i_en_dec && !i_stalled && !continue) begin
      o_reg_dest <= 0;
      o_reg_src1 <= 0;
      o_reg_src2 <= 0;
    end

      /************************************************************************
      *
      * set registers for specific instructions
      *
      ************************************************************************/

    if (i_en_dec && !i_stalled && continue) begin

      if (block_0x) begin
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
        endcase
      end      

    end    

  end
end


/******************************************************************************
*
* set fields from instruction nibble
*
*****************************************************************************/

`ifdef SIM
//`define DEBUG_FIELDS_TABLE
`endif


always @(posedge i_clk) begin
  if (i_reset) begin
      // reset values
      o_field       <= 0;
      o_field_start <= 0;
      o_field_last  <= 0;
  end else begin

    // reset values on instruction decode start
    if (i_en_dec && !i_stalled && !continue) begin
      // reset values
      o_field       <= 0;
      o_field_start <= 0;
      o_field_last  <= 0;
    end

    if (i_en_dec && !i_stalled && continue) begin

      /******************************************************************************
      *
      * set field for specific instructions
      *
      *****************************************************************************/

      if (block_0x) begin
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

      /******************************************************************************
      *
      * set field from a table
      *
      *
      *****************************************************************************/

      if (fields_table) begin
        if (o_fields_table != `FT_TABLE_value) begin

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