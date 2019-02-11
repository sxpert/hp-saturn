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
     i_en_exec,
    //  i_stalled,
     i_nibble,
     o_pc,
     o_dec_error);

/*
 * module input / output ports
 */
input   wire        i_clk;
input   wire        i_reset;
input   wire [31:0] i_cycles;
input   wire        i_en_dbg;
input   wire        i_en_dec;
input   wire        i_en_exec;
// input   wire            i_stalled;
input   wire [3:0]  i_nibble;

output  wire [19:0] o_pc;
output  reg         o_dec_error;

/*
 * state registers
 */

reg         ins_decoded;
reg [31:0]  instr_ctr;

initial begin
  o_dec_error = 0;
  ins_decoded = 0;
  // initialize all registers
  HST         = 0;
  CARRY       = 0;
  PC          = 0;
`ifdef SIM
  // $monitor({"i_clk %b | i_reset %b | i_cycles %d | i_en_dec %b | i_en_exec %b |",
  //          " continue %b | instr_start %b | i_nibble %h"}, 
  //          i_clk, i_reset, i_cycles, i_en_dec, i_en_exec, continue, 
  //          instr_start, i_nibble);
  // $monitor("i_en_dec %b | i_en_exec %b | i_cycles %d | nb %h | fn %b | cont %b | b0x %b | rtn %b | sxm %b | sc %b | cv %b",
  //          i_en_dec, i_en_exec, i_cycles, i_nibble, instr_start, continue, block_0x, ins_rtn, set_xm, set_carry, carry_val);
`endif
end

assign o_pc = PC;

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
`endif
    end
end

/******************************************************************************
 *
 * handle decoding of the fist nibble 
 * that's pretty simple though, will get tougher later on :-)
 *
 *****************************************************************************/

reg [19:0]  ins_addr;
reg         inc_pc_x;
reg         continue_x;
reg         block_0x;

wire        continue;

assign continue = continue_x || continue_0x;

always @(posedge i_clk) begin
  if (i_reset) begin
    inc_pc_x    <= 0;
    continue_x  <= 0;
    block_0x    <= 0;
    o_dec_error <= 0;
  end else begin
    if (i_en_dec)
      if (!continue) begin
        continue_x  <= 1;
        ins_decoded <= 0;
        // store the address where the instruction starts
        ins_addr    <= PC;
        inc_pc_x    <= 1;
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
      end else begin
        inc_pc_x <= 0;
        continue_x <= 0;
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
 * 02   RTNSC
 * 03   RTNCC
 *
 *****************************************************************************/

reg inc_pc_0x;
reg continue_0x;

reg ins_rtn;

reg set_xm;
reg set_carry;
reg carry_val;

always @(posedge i_clk) begin
  if (i_reset) begin
    inc_pc_0x   <= 0;
    continue_0x <= 0;
    ins_rtn     <= 0;
    set_xm      <= 0;
    set_carry   <= 0;
    carry_val   <= 0;
  end else begin
    if (i_en_dec)
      if (continue && block_0x) begin
        inc_pc_0x <= 1;
        case (i_nibble)
        4'h0, 4'h1, 4'h2, 4'h3: ins_rtn <= 1;
        default: begin
`ifdef SIM
          $display("block_0x: nibble %h not handled", i_nibble);
`endif
          o_dec_error <= 1;
        end
        endcase
        set_xm    <= (i_nibble == 4'h0);
        set_carry <= (i_nibble[3:1] == 1);
        carry_val <= (i_nibble[1] && i_nibble[0]);
        continue_0x <= (i_nibble == 4'hE);
        ins_decoded <= (i_nibble != 4'hE);
      end else begin
        inc_pc_0x   <= 0;
        continue_0x <= 0;
        // cleanup 
        ins_rtn     <= 0;
        set_xm      <= 0;
        set_carry   <= 0;
        carry_val   <= 0;
      end
    end
end




/******************************************************************************
 *
 * execute things
 * 
 *****************************************************************************/

reg [3:0]     HST;     // hardware satus flags |MP|SR|SB|XM|
reg           CARRY;   // public carry
reg           DEC;     // decimal mode

reg [19:0]    PC;

/****
 * PC handler
 *
 */
wire          inc_pc;

assign inc_pc = inc_pc_x || inc_pc_0x;

always @(posedge i_clk) begin
  if (!i_reset)
    if(i_en_exec)
      if (inc_pc) begin
        PC <= PC + 1;
      end
end


/****
 * RTN[SXM,,SC,CC]
 *
 */

always @(posedge i_clk) begin
  if (!i_reset)
    if (i_en_exec)
      if (ins_rtn) begin
        HST[0] <= set_xm?1:HST[0];
        CARRY <= set_carry?carry_val:CARRY;
        // do RTN things
      end
end


endmodule