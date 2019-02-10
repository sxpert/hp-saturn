/******************************************************************************
 * 80Cn		C=P	n
 *
 *
 */

`include "decstates.v"

`DEC_C_EQ_P_N: begin
    C[nb_in*4+:4] <= P;
    decstate <= `DEC_START;
`ifdef SIM
    $display("%05h C=P\t%h", inst_start_PC, nb_in);	
`endif
end
`DEC_P_EQ_C_N: begin
    P <= C[nb_in*4+:4];
    decstate <= `DEC_START;
`ifdef SIM
    $display("%05h P=C\t%h", inst_start_PC, nb_in);	
`endif
end

