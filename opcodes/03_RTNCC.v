/******************************************************************************
 * 03			RTNCC
 *
 *
 */ 

`include "decstates.v"

`DEC_RTNCC: begin
    Carry <= 0;
    PC <= RSTK[rstk_ptr];
    RSTK[rstk_ptr] <= 0;		
    rstk_ptr <= rstk_ptr - 1;
    bus_load_pc <= 1;
    execute_cycle <= 0;
    decstate <= `DEC_START;
`ifdef SIM
    $display("%05h RTNCC", saved_PC);
`endif
end
// `ifdef SIM
//     else 
//         begin
//             decode_error <= 1;
//             $display("RTNCC runstate %h", runstate);
//         end
// `endif
