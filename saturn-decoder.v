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
  $monitor({"i_clk %b | i_reset %b | i_cycles %d | i_en_dec %b | i_en_exec %b |",
           " continue %b | instr_start %b | i_nibble %h | block_0x %b | ins_rtnsxm %b"}, 
           i_clk, i_reset, i_cycles, i_en_dec, i_en_exec, continue, 
           instr_start, i_nibble, block_0x, ins_rtnsxm);
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
    if (instr_start && i_en_dec) begin
      continue <= 1;
      // assign block regs
      block_0x <= (i_nibble == 4'h0);
    end
  end
end

/*
 * handle block 0
 */

reg ins_rtnsxm;

always @(posedge i_clk) begin
  if (i_reset) begin
    ins_rtnsxm <= 0;
  end else begin
    if (continue && i_en_dec && block_0x) begin
      ins_rtnsxm <= (i_nibble == 4'h0);
      continue <= (i_nibble == 4'hE);
    end
  end
end

reg set_xm;

always @(posedge i_clk) begin
  if (i_reset) 
    set_xm <= 0;
  else
    if (i_en_exec && ins_rtnsxm) begin
`ifdef SIM
      $display("do something");
`endif
      set_xm <= 1;
    end
end


endmodule