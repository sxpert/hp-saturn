/******************************************************************************
 * 8
 * a lot of things start with 8...
 *
 */ 


`include "decstates.v"

`DEC_FX: begin
    field <= `T_FIELD_A;
    alu_first <= 0;
    alu_last  <= 4;
    alu_reg_dest <= {2'b00, nb_in[1:0]};

    if (!nb_in[3]) begin
        $display("F%h shifts not implemented");
        decode_error <= 1;
    end else begin
        alu_reg_src1 <= {2'b00, nb_in[1:0]};
        alu_op <= nb_in[2]?`ALU_OP_1CMPL:`ALU_OP_2CMPL;
    end
    alu_debug <= 1;
    next_cycle <= `BUSCMD_NOP;
    decstate <= `DEC_ALU_INIT;
    alu_return <= `DEC_START;

`ifdef SIM
    $write("%5h ", inst_start_PC);
    case ({2'b00, nb_in[1:0]})
    `ALU_REG_A: $write("A");
    `ALU_REG_B: $write("B");
    `ALU_REG_C: $write("C");
    `ALU_REG_D: $write("D");
    endcase
    if (!nb_in[3]) begin
        $write("S");
        if (!nb_in[2]) $write("L");
        else $write("R");
    end else begin
       $write("=-");
        case ({2'b00, nb_in[1:0]})
        `ALU_REG_A: $write("A");
        `ALU_REG_B: $write("B");
        `ALU_REG_C: $write("C");
        `ALU_REG_D: $write("D");
        endcase
        if (nb_in[2]) $write("-1"); 
    end
    $display("\tA");
`endif
end
