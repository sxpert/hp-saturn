/******************************************************************************
 * 13X
 *
 *
 */ 

`include "decstates.v"

`DEC_13X: begin
    field <= `T_FIELD_A;
    alu_first <= 0;
    alu_last  <= nb_in[3]?3:4;
    alu_reg_dest <= {1'b0, !nb_in[1], nb_in[2] &&  nb_in[1], !nb_in[1] && nb_in[0]};
    alu_reg_src1 <= {1'b0,  nb_in[1], nb_in[2] && !nb_in[1],  nb_in[1] && nb_in[0]};
    alu_op <= nb_in[1]?`ALU_OP_EXCH:`ALU_OP_COPY;

    next_cycle <= `BUSCMD_NOP;
    decstate <= `DEC_ALU_INIT;
    alu_return <= `DEC_START;

    alu_debug <= 1;

`ifdef SIM
    $write("%5h ", inst_start_PC);
    if (!nb_in[1]) 
        $write("D");
    else 
        $write("%sD", nb_in[3]?"C":"A");
    $write("%b", nb_in[0]);
    if (!nb_in[1]) 
        $write("=%s%s", nb_in[2]?"C":"A", nb_in[3]?"S":"");
    else
        $write("%s", nb_in[3]?"XS":"EX");
    $display("");
`endif
end
