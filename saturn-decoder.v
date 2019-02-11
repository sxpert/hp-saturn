/******************************************************************************
 *
 * Instruction decoder module
 *
 *****************************************************************************/

module saturn_decoder(
     i_clk, 
     i_reset,
     i_cycles,
     i_en_dec,
     i_en_exec,
    //  i_stalled,
     i_nibble);

/*
 * module input / output ports
 */
input   wire        i_clk;
input   wire        i_reset;
input   wire [31:0] i_cycles;
input   wire        i_en_dec;
input   wire        i_en_exec;
// input   wire            i_stalled;
input   wire [3:0]  i_nibble;

/*
 * state registers
 */

reg         continue;
wire        instr_start;
reg [31:0]  instr_ctr;

initial begin
  continue = 0;
`ifdef SIM
  // $monitor({"i_clk %b | i_reset %b | i_cycles %d | i_en_dec %b | i_en_exec %b |",
  //          " continue %b | instr_start %b | i_nibble %h"}, 
  //          i_clk, i_reset, i_cycles, i_en_dec, i_en_exec, continue, 
  //          instr_start, i_nibble);
  // $monitor("i_en_dec %b | i_en_exec %b | i_cycles %d | nb %h | fn %b | cont %b | b0x %b | rtn %b | sxm %b | sc %b | cv %b",
  //          i_en_dec, i_en_exec, i_cycles, i_nibble, instr_start, continue, block_0x, ins_rtn, set_xm, set_carry, carry_val);
`endif
end

/*
 * handle the fist nibble decoding
 * that's pretty simple though, will get tougher later on :-)
 */

reg block_0x;

assign instr_start = ~continue || i_reset;

always @(posedge i_clk) begin
  if (i_reset) begin
    block_0x <= 0;
  end else begin
    if (i_en_dec)
      if (instr_start && i_en_dec) begin
`ifdef SIM
        $display("%d | %b | %b | first nibble", i_cycles, i_en_dec, i_en_exec);
`endif
        continue <= 1;
        // assign block regs
        block_0x <= (i_nibble == 4'h0);
      end else begin
        $display("%d | first_nibble: clear block_0x", i_cycles);
        block_0x <= 0;
      end
    end
end

/******************************************************************************
 *
 * 0x
 *
 * 00   RTNSXM
 * 01   RTN
 *
 */

reg ins_rtn;

reg set_xm;
reg set_carry;
reg carry_val;

always @(posedge i_clk) begin
  if (i_reset) begin
    ins_rtn   <= 0;
    set_xm    <= 0;
    set_carry <= 0;
    carry_val <= 0;
  end else begin
    if (i_en_dec)
      if (continue && block_0x) begin
`ifdef SIM
        $display("%d | block_0x:", i_cycles);
`endif
        block_0x <= 0;
        case (i_nibble)
        4'h0, 4'h1, 4'h2, 4'h3:
          ins_rtn <= 1;
        endcase
        set_xm    <= (i_nibble == 4'h0);
        set_carry <= (i_nibble[3:1] == 1);
        carry_val <= (i_nibble[1] && i_nibble[0]);
        continue <= (i_nibble == 4'hE);
      end else begin
        $display("%d | block_0x: clearing rtn, xm, sc, cv", i_cycles);
        ins_rtn <= 0;
        set_xm <= 0;
        set_carry <= 0;
        carry_val <= 0;
      end
    end
end




/******************************************************************************
 *
 * execute things
 * 
 *****************************************************************************/

always @(posedge i_clk) begin
  if (i_reset) 
    set_xm <= 0;
  else
    if (i_en_exec && ins_rtn) begin
`ifdef SIM
      $display("RTN (XM: %b SC %b CV %b)", set_xm, set_carry, carry_val);
`endif
    end;
end


endmodule