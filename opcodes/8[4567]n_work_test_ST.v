/******************************************************************************
 * 84n	ST=0   n
 * 85n	ST=1   n
 */ 

`include "decstates.v"

`DEC_ST_EQ_0_N: begin
    ST[nb_in] <= 0;
    decstate <= `DEC_START;
`ifdef SIM
    $display("%05h ST=0\t%h", inst_start_PC, nb_in);
`endif
end
`DEC_ST_EQ_1_N: begin
    ST[nb_in] <= 1;
    decstate <= `DEC_START;
`ifdef SIM
    $display("%05h ST=1\t%h", inst_start_PC, nb_in);
`endif
end
`DEC_TEST_ST_EQ_0_N: begin
    Carry <= (!ST[nb_in]);
    decstate <= `DEC_TEST_GO;
`ifdef SIM
    $display("%05h ?ST=0\t%h", inst_start_PC, nb_in);
`endif    
end
`DEC_TEST_ST_EQ_1_N: begin
    Carry <= (ST[nb_in]);
    decstate <= `DEC_TEST_GO;
`ifdef SIM
    $display("%05h ?ST=1\t%h", inst_start_PC, nb_in);
`endif    
end
