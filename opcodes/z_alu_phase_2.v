case (decstate)
`DEC_ALU_INIT, `DEC_ALU_CONT: begin
`ifdef SIM
    if (alu_debug) begin
    	$display("------------------------------- z_alu_phase_2 ---------------------------------");
        $display("ALU OP %h | FRST %h | LAST %h | SRC1 %h | SRC2 %h | DEST %h",
                alu_op, alu_first, alu_last, alu_reg_src1, alu_reg_src2,alu_reg_dest);
        $display("CARRY %b | STICKY-BIT %b", Carry, HST[1]);
        case (alu_reg_dest)
        `ALU_REG_A: $display("A: %h", A);
        `ALU_REG_B: $display("B: %h", B);
        `ALU_REG_C: $display("C: %h", C);
        `ALU_REG_D: $display("D: %h", D);
        endcase
        $write("xxx");
        for (display_counter = 15; display_counter != 255; display_counter = display_counter - 1)
            case (display_counter[3:0])
            alu_last:  
                if (alu_first == alu_last) $write("!");
                else $write("L");
            alu_first: $write("^");
            default:   $write(".");
            endcase
        $display("");
    end
`endif
    case (alu_op)
    `ALU_OP_INC: begin
        case (alu_reg_src1)
        `ALU_REG_A: alu_src1 <= A[alu_first*4+:4];
        `ALU_REG_B: alu_src1 <= B[alu_first*4+:4];
        `ALU_REG_C: alu_src1 <= C[alu_first*4+:4];
        `ALU_REG_D: alu_src1 <= D[alu_first*4+:4];
        endcase
        alu_carry <= (decstate == `DEC_ALU_INIT)?1:Carry;
    end
    default: begin
`ifdef SIM
        $display("nothing to do I suppose");
`endif
    end
    endcase
end
endcase
