/******************************************************************************
 * 3n[xxxxxx]	LC (n) [xxxxxx]
 *
 *
 */ 

`include "decstates.v"
`include "fields.v"

`DEC_LC: begin
    alu_first <= P;
    alu_last <= (P + nb_in) & 4'hF;
    alu_reg_src1 <= `ALU_REG_MEM;
    alu_reg_dest <= `ALU_REG_C;
    alu_op <= `ALU_OP_COPY;

    // alu_debug <= 1;
    decstate <= `DEC_ALU_INIT;
    alu_return <= `DEC_START;
// `ifdef SIM
//         $write("%5h LC (%h)\t%1h", inst_start_PC, t_cnt, nb_in);
//         for(t_ctr = 0; t_ctr != t_cnt; t_ctr ++)
//             $write("%1h", C[(((t_cnt - t_ctr - 4'h1)+P)%16)*4+:4]);
//         $write("\n");
// `endif
end
