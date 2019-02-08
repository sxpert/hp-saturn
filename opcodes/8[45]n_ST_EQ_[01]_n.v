/******************************************************************************
 * 84n	ST=0   n
 * 85n	ST=1   n
 */ 

`include "decstates.v"

`DEC_ST_EQ_0_N: begin
    ST[nibble] <= 0;
    decstate <= `DEC_START;
`ifdef SIM
    $display("%05h ST=0\t%h", inst_start_PC, nibble);
`endif
end
`DEC_ST_EQ_1_N: begin
    ST[nibble] <= 1;
    decstate <= `DEC_START;
`ifdef SIM
    $display("%05h ST=1\t%h", inst_start_PC, nibble);
`endif
end
