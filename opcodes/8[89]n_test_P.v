/******************************************************************************
 * 88n		?P#     n
 * 89n      ?P=     n
 *
 */

`DEC_TEST_P_NEQ_N: begin
    Carry <= !(P == nb_in);
    decstate <= `DEC_TEST_GO;
`ifdef SIM
    $display("%5h ?P#\t\t%h", inst_start_PC, nb_in);
`endif
end
`DEC_TEST_P_EQ_N: begin
    Carry <= (P == nb_in);
    decstate <= `DEC_TEST_GO;
`ifdef SIM
    $display("%5h ?P=\t\t%h", inst_start_PC, nb_in);
`endif
end