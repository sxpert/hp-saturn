/******************************************************************************
 *1[678C]		D[01]=D[01][+-] (n+1)
 *
 *
 */ 

`DEC_PTR_MATH: begin
    field <= `T_FIELD_A;
    alu_first <= 0;
    alu_last  <= 4;
    alu_const <= nb_in;

    next_cycle <= `BUSCMD_NOP;
    decstate <= `DEC_ALU_INIT;
    alu_return <= `DEC_START;

`ifdef SIM
    $display("%5h D%b=D%b%s\t%2d", 
        inst_start_PC, alu_reg_dest[0], alu_reg_src1[0], 
        ((alu_op==`ALU_OP_SUB_CST)?"-":"+"), nb_in+1);
`endif
end