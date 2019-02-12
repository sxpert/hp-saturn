`ifndef _SATURN_ALU
`define _SATURN_ALU

`include "def-alu.v"

module saturn_alu (
    i_clk,
    i_reset,
	i_en_alu_prep,
	i_en_alu_calc,
	i_en_alu_save,

    i_field_start,
    i_field_last,

    i_alu_op,

    o_reg_p
);

input   wire [0:0]  i_clk;
input   wire [0:0]  i_reset;
input   wire [0:0]  i_en_alu_prep;
input   wire [0:0]  i_en_alu_calc;
input   wire [0:0]  i_en_alu_save;

input   wire [3:0]  i_field_start;
input   wire [3:0]  i_field_last;

input   wire [4:0]  i_alu_op;

output  wire [3:0]  o_reg_p;


assign o_reg_p = P;


reg [3:0]       P;

initial begin
  P = 3;
end

always @(posedge i_clk) begin
  if (!i_reset) begin
    if (i_en_alu_prep) begin
      `ifdef SIM
    //   $display("ALU_PREP: alu_op %h | f_start %h | f_last %h", i_alu_op, i_field_start, i_field_last);
      `endif
    end
  end
end

endmodule
