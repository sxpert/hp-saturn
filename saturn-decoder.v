/******************************************************************************
 *
 * Instruction decoder module
 *
 *****************************************************************************/

module saturn_decoder(
     i_clk, 
     i_reset,
     i_cycles,
     i_en_dbg,
     i_en_dec,
    //  i_stalled,
     i_pc,
     i_nibble,
     o_inc_pc,
     o_dec_error);

/*
 * module input / output ports
 */
input   wire        i_clk;
input   wire        i_reset;
input   wire [31:0] i_cycles;
input   wire        i_en_dbg;
input   wire        i_en_dec;
// input   wire            i_stalled;
input   wire [19:0] i_pc;
input   wire [3:0]  i_nibble;

output  reg         o_inc_pc;
output  reg         o_dec_error;

/*
 * state registers
 */

reg         ins_decoded;
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
  if (!i_reset && i_en_dbg) 
    if (!continue&ins_decoded) begin
`ifdef SIM
      $write("%5h ", ins_addr);
      if (ins_rtn) begin
        $write("RTN");
        if (set_xm) $write("SXM");
        if (set_carry) $write("%sC", carry_val?"S":"C");
        $display("");
      end
      if (ins_set_mode) begin
        $display("SET%s", mode_dec?"DEC":"HEX");
      end
      if (ins_rstk_c) begin
        $display("%s", direction?"C=RSTK":"RSTK=C");
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
reg [19:0]  ins_addr;
reg         continue;

reg         block_0x;

// generic
reg         direction;

// rtn specific
reg         ins_rtn;
reg         set_xm;
reg         set_carry;
reg         carry_val;

// setdec/hex
reg         ins_set_mode;
reg         mode_dec;

// rstk and c
reg         ins_rstk_c;        

always @(posedge i_clk) begin
  if (i_reset) begin
    continue     <= 0;
    o_inc_pc     <= 1;
    o_dec_error  <= 0;
    ins_decoded  <= 0;

  end else begin
    if (i_en_dec) begin

      /* 
       * stuff that is always done
       */
      o_inc_pc <= 1; // may be set to 0 later

      /*
       * cleanup
       */ 
      if (!continue) begin
        continue     <= 1;
        ins_decoded  <= 0;
        // store the address where the instruction starts
        ins_addr     <= i_pc;

        // cleanup
        direction    <= 0;

        ins_rtn      <= 0;
        set_xm       <= 0;
        set_carry    <= 0;
        carry_val    <= 0;
        
        ins_set_mode <= 0;
        mode_dec     <= 0;
        
        ins_rstk_c   <= 0;
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
      *
      *****************************************************************************/

      if (continue && block_0x) begin
        case (i_nibble)
        4'h0, 4'h1, 4'h2, 4'h3: begin
          ins_rtn      <= 1;
          set_xm       <= (i_nibble == 4'h0);
          set_carry    <= (i_nibble[3:1] == 1);
          carry_val    <= (i_nibble[1] && i_nibble[0]);
        end
        4'h4, 4'h5            : begin
          ins_set_mode <= 1;
          mode_dec     <= (i_nibble[0]);
        end
        4'h6, 6'h7            : begin
          ins_rstk_c   <= 1;
          direction    <= (i_nibble[0]);
        end
        default: begin
`ifdef SIM
          $display("block_0x: nibble %h not handled", i_nibble);
`endif
          o_dec_error <= 1;
        end
        endcase
        continue    <= (i_nibble == 4'hE);
        ins_decoded <= (i_nibble != 4'hE);
      end 




    end
  end
end


endmodule