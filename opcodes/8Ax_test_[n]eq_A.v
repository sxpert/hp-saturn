/******************************************************************************
 * 8Ax
 * a lot of things start with 8...
 *
 */ 


`include "decstates.v"

`DEC_8AX: begin
    // prepare ALU for register A
    field <= `T_FIELD_A;
    alu_first <= 0;
    alu_last  <= 4;
    alu_op    <= nb_in[2]?`ALU_OP_TEST_NEQ:`ALU_OP_TEST_EQ;
    if (!nb_in[3]) begin
        alu_reg_src1 <= {2'b00, nb_in[0], !(nb_in[1] | nb_in[0])};
        alu_reg_src2 <= {2'b00, nb_in[1:0]};
    end
    else begin
        alu_reg_src1 <= {2'b00, nb_in[1:0]};
        alu_reg_src2 <= `ALU_REG_0;
    end
    // alu_debug <= 1;
    next_cycle <= `BUSCMD_NOP;
    decstate <= `DEC_ALU_INIT;    
    alu_return <= `DEC_TEST_GO;

`ifdef SIM
    $write("%5h ?",  inst_start_PC);

    case ({2'b00, (nb_in[3]?nb_in[1:0]:{nb_in[0], !(nb_in[1] | nb_in[0])})})
    `ALU_REG_A: $write("A");
    `ALU_REG_B: $write("B");
    `ALU_REG_C: $write("C");
    `ALU_REG_D: $write("D");
    endcase

    $write("%s", nb_in[2]?"#":"=");

    case  (nb_in[3]?`ALU_REG_0:{2'b00, nb_in[1:0]})   
    `ALU_REG_A: $write("A");
    `ALU_REG_B: $write("B");
    `ALU_REG_C: $write("C");
    `ALU_REG_D: $write("D");
    `ALU_REG_0: $write("0");
    endcase

    $display("\tA");
`endif
end
