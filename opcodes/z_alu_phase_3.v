/*
 * Alu module
 * calculations are in here
 */

`include "fields.v"

`DEC_ALU_INIT, `DEC_ALU_CONT: begin
`ifdef SIM
    if (alu_debug) begin
        $display("------------------------------- z_alu_phase_3 ---------------------------------");
        $display("alu_src1 %h | alu_src2 %h | alu_tmp %h | alu_carry %b", 
                 alu_src1, alu_src2, alu_tmp, alu_carry);
    end
`endif

    case (alu_op)
    `ALU_OP_ZERO: begin
        $display("ALU_OP_ZERO");
        case (alu_reg_dest)
        `ALU_REG_A: A[alu_first*4+:4] <= 0;
        `ALU_REG_B: B[alu_first*4+:4] <= 0;
        `ALU_REG_C: C[alu_first*4+:4] <= 0;
        `ALU_REG_D: D[alu_first*4+:4] <= 0;
        default: $display("ALU_OP_ZERO register not handled");
        endcase
        alu_first <= (alu_first + 1) & 4'hF;
    end
    `ALU_OP_SHR: begin

    end
    `ALU_OP_INC: begin
        $display("ALU_OP_INC");
        case (alu_reg_dest)
        `ALU_REG_D: {Carry, D[alu_first*4+:4]} <= alu_src1 + alu_carry;
        default: $display("ALU_OP_INC register not handled");
        endcase
        alu_first <= (alu_first + 1) & 4'hF;
    end
    default: begin
`ifdef SIM

`endif
    end
    endcase


    if (alu_last == alu_first) begin
        // the alu is done
        decstate <= `DEC_START;
        alu_requested_halt <= alu_halt;
    end else decstate <= `DEC_ALU_CONT;

end