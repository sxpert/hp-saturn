`include "decstates.v"

case (decstate)
`DEC_ALU_INIT, `DEC_ALU_CONT: begin
`ifdef SIM
    if (alu_debug) begin
    	$display("----------------------- z_alu_phase_2 - Do calculations ------------------------");
        $display("data received from reading : %h | carry %b", bus_nibble_out, alu_carry);
    end
`endif

    case (alu_op)
    `ALU_OP_ZERO: begin
        alu_res1 <= 0;
        alu_res_carry <= 0;
    end
    `ALU_OP_COPY: begin
        alu_res1 <=  (alu_reg_src1 == `ALU_REG_M)? bus_nibble_out : alu_src1;
        alu_res_carry <= 0;
    end
    `ALU_OP_EXCH: begin
        alu_res1 <= alu_src2;
        alu_res2 <= alu_src1;
        alu_res_carry <= 0;
    end
    `ALU_OP_2CMPL: begin
        {alu_res_carry, alu_res1} <= ~alu_src1 + alu_carry;
    end
   `ALU_OP_1CMPL: begin
        alu_res1 <= ~alu_src1;
        alu_res_carry <= 0;
    end
    `ALU_OP_INC: begin
        {alu_res_carry, alu_res1} <= alu_src1 + alu_carry;
    end
    `ALU_OP_ADD_CST: begin
        {alu_res_carry, alu_res1} <= alu_src1 + (((decstate==`DEC_ALU_INIT)?alu_src2:0) + alu_carry);
    end
    `ALU_OP_SUB_CST: begin
        {alu_res_carry, alu_res1} <= alu_src1 - (((decstate==`DEC_ALU_INIT)?alu_src2:0) + alu_carry);
    end
    `ALU_OP_TEST_EQ: begin
        alu_res_carry <= (alu_src1 == alu_src2) & alu_carry;
    end
    `ALU_OP_TEST_NEQ: begin
        alu_res_carry <= (alu_src1 != alu_src2) & alu_carry;
    end
    default: $display("ALU PHASE 2 ERROR : unknown op %d", alu_op);
    endcase
end
endcase
