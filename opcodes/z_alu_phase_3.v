/*
 * Alu module
 * calculations are in here
 */

`include "fields.v"

`DEC_ALU_INIT, `DEC_ALU_CONT: begin
`ifdef SIM
    if (alu_debug) begin
        $display("------------------------ z_alu_phase_3 - Store results -------------------------");
        $display("SRC1 %h | SRC2 %h | RES1 %h | RES2 %h | AC %b | RC %b | DEST %h | TMP %h | CARRY %b", 
                 alu_src1, alu_src2, alu_res1, alu_res2, alu_carry, alu_res_carry,
                 alu_reg_dest, alu_tmp, alu_carry);
    end
`endif

    /*
     * put the result in destination register
     */
    case (alu_op)
    // cases where the result is useful
    `ALU_OP_ZERO,
    `ALU_OP_COPY,
    `ALU_OP_EXCH,
    `ALU_OP_2CMPL,
    `ALU_OP_1CMPL,
    `ALU_OP_INC,
    `ALU_OP_ADD_CST,
    `ALU_OP_SUB_CST: begin
        case ((alu_op==`ALU_OP_EXCH)?alu_reg_src1:alu_reg_dest)
        `ALU_REG_A:  A[alu_first*4+:4]  <= alu_res1;
        `ALU_REG_B:  B[alu_first*4+:4]  <= alu_res1;
        `ALU_REG_C:  C[alu_first*4+:4]  <= alu_res1;
        `ALU_REG_D:  D[alu_first*4+:4]  <= alu_res1;
        `ALU_REG_D0: D0[alu_first*4+:4] <= alu_res1;
        `ALU_REG_D1: D1[alu_first*4+:4] <= alu_res1;
        default: begin
`ifdef SIM
            $display("ALU_P3 ERROR: ALU_OP %d DEST REGISTER NOT IMPLEMENTED %d", alu_op, (alu_op==`ALU_OP_EXCH)?alu_reg_src1:alu_reg_dest);
            alu_p1_halt <= 1;
`endif
        end
        endcase   
        alu_first <= (alu_first + 1) & 4'hF;
    end
    // cases where there's no result
    `ALU_OP_TEST_EQ,
    `ALU_OP_TEST_NEQ: begin
        alu_first <= (alu_first + 1) & 4'hF;
    end
    default: begin
`ifdef SIM
        $display("ALU alu_res1: operation not implemented");
        decode_error <= 1;
`endif
    end
    endcase

    case (alu_op)
    `ALU_OP_ZERO,
    `ALU_OP_COPY,
    `ALU_OP_2CMPL,
    `ALU_OP_1CMPL,
    `ALU_OP_INC,
    `ALU_OP_ADD_CST,
    `ALU_OP_SUB_CST,
    `ALU_OP_TEST_EQ,
    `ALU_OP_TEST_NEQ: begin end // nothing do to with alu_res2
    // exchange requires res2
    `ALU_OP_EXCH: begin
        case (alu_reg_dest)
        `ALU_REG_A:  A[alu_first*4+:4]  <= alu_res2;
        `ALU_REG_B:  B[alu_first*4+:4]  <= alu_res2;
        `ALU_REG_C:  C[alu_first*4+:4]  <= alu_res2;
        `ALU_REG_D:  D[alu_first*4+:4]  <= alu_res2;
        `ALU_REG_D0: D0[alu_first*4+:4] <= alu_res2;
        `ALU_REG_D1: D1[alu_first*4+:4] <= alu_res2;
        default: begin
`ifdef SIM
            $display("ALU_P3 ERROR: ALU_OP %d DEST2 REGISTER NOT IMPLEMENTED %d", alu_op, alu_reg_dest);
            alu_p1_halt <= 1;
`endif
        end
        endcase  
    end
    default: begin
`ifdef SIM
        $display("ALU alu_res2: operation not implemented");
        decode_error <= 1;
`endif
    end
    endcase 

    /*
     * handle carry TODO: check if there are operations that don't touch carry
     */
    case (alu_op)
    // cases where carry is to be changed
    `ALU_OP_2CMPL,
    `ALU_OP_1CMPL,
    `ALU_OP_INC,
    `ALU_OP_ADD_CST,
    `ALU_OP_SUB_CST,
    `ALU_OP_TEST_EQ,
    `ALU_OP_TEST_NEQ: begin
        Carry <= alu_res_carry;
    end
    endcase


    if (alu_last == alu_first) begin
        // the alu is done
        next_cycle <= alu_next_cycle;
        decstate <= alu_return;
        alu_requested_halt <= alu_p1_halt | alu_p2_halt | alu_halt ;
    end else decstate <= `DEC_ALU_CONT;

end