`include "decstates.v"

case (decstate)
`DEC_ALU_INIT, `DEC_ALU_CONT: begin
`ifdef SIM
    if (alu_debug) begin
    	$display("------------------------ z_alu_phase_1 - Prepare params ------------------------");
        $write("ALU OP ");
        case (alu_op)
        `ALU_OP_ZERO:     $write("ZERO    ");
        `ALU_OP_COPY:     $write("COPY    ");
        `ALU_OP_EXCH:     $write("EXCH    ");
        `ALU_OP_SHL:      $write("SHL     ");
        `ALU_OP_SHR:      $write("SHR     ");
        `ALU_OP_2CMPL:    $write("2CMPL   ");
        `ALU_OP_1CMPL:    $write("1CMPL   ");
        `ALU_OP_INC:      $write("INC     ");
        `ALU_OP_TEST_EQ:  $write("TEST_EQ ");
        `ALU_OP_TEST_NEQ: $write("TEST_NEQ");
        endcase
        $display(" | FRST %h | LAST %h | SRC1 %h | SRC2 %h | DEST %h",
                alu_first, alu_last, alu_reg_src1, alu_reg_src2,alu_reg_dest);
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

/*
 *
 * Setting up SRC1 register for operations
 * 
 */

    case (alu_op)
    `ALU_OP_2CMPL,
    `ALU_OP_1CMPL,
    `ALU_OP_INC,
    `ALU_OP_TEST_EQ, 
    `ALU_OP_TEST_NEQ: begin
        case (alu_reg_src1)
        `ALU_REG_A: alu_src1 <= A[alu_first*4+:4];
        `ALU_REG_B: alu_src1 <= B[alu_first*4+:4];
        `ALU_REG_C: alu_src1 <= C[alu_first*4+:4];
        `ALU_REG_D: alu_src1 <= D[alu_first*4+:4];
        endcase
    end
    default: begin
`ifdef SIM
        // $display("no source 1 required");
`endif
    end
    endcase

/*
 *
 * Setting up SRC2 register for operations
 * 
 */

    case (alu_op)
    `ALU_OP_TEST_EQ, 
    `ALU_OP_TEST_NEQ: begin
        case (alu_reg_src2)
        `ALU_REG_A: alu_src2 <= A[alu_first*4+:4];
        `ALU_REG_B: alu_src2 <= B[alu_first*4+:4];
        `ALU_REG_C: alu_src2 <= C[alu_first*4+:4];
        `ALU_REG_D: alu_src2 <= D[alu_first*4+:4];
        `ALU_REG_0: alu_src2 <= 0;
        endcase
    end
    default: begin
`ifdef SIM
        // $display("no source 2 required");
`endif
    end
    endcase

/*
 *
 * update internal carry
 * 
 */

    case (alu_op)
    /*
     * option 1: carry starts at 0 (not used yet)
     */
//        alu_carry <= (decstate == `DEC_ALU_INIT)?0:Carry;
    /*
     * option 2: carry starts at 1
     */
    `ALU_OP_2CMPL,
    `ALU_OP_1CMPL,
    `ALU_OP_INC,
    `ALU_OP_TEST_EQ, 
    `ALU_OP_TEST_NEQ: 
        alu_carry <= (decstate == `DEC_ALU_INIT)?1:Carry;
    /*
     * option 3: carry is always cleared
     */
    `ALU_OP_1CMPL:
        Carry <= 0;
    endcase

    if (alu_last == alu_first) alu_next_cycle <= `BUSCMD_PC_READ;
    else alu_next_cycle <= `BUSCMD_NOP;    
end
endcase
