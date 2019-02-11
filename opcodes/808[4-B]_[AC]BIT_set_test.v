/******************************************************************************
 * 82x
 * 
 * lots of things there
 *
 */
 
 `DEC_AC_BIT_SET_TEST: begin
    $display("ERROR: %h | t_reg %b | t_set_test %b | t_set_test_val %b", 
             nb_in, t_reg, t_set_test, t_set_test_val);
    if (!t_set_test) begin
        if (!t_reg) A[nb_in] <= t_set_test_val;
        else C[nb_in] <= t_set_test_val;
        decstate <= `DEC_START;
    end else begin
        if (!t_reg) Carry <= (A[nb_in] == t_set_test_val);
        else Carry <= (C[nb_in] == t_set_test_val);
        decstate <= `DEC_TEST_GO;
    end
`ifdef SIM
    $display("%5h %s%sBIT=%b\t%h", 
             inst_start_PC, t_set_test?"?":"",
             t_reg?"C":"A", t_set_test_val, nb_in);
`endif
end