/******************************************************************************
 * 03			RTNCC
 *
 *
 */ 

`include "decstates.v"

// `DEC_RTNCC:
begin
    Carry <= 0;
    new_PC <= RSTK[rstk_ptr];
    RSTK[rstk_ptr] <= 0;		
    rstk_ptr <= rstk_ptr - 1;
    bus_load_pc <= 1;
    // execute_cycle <= 0;
    decstate <= `DEC_START;
`ifdef SIM
    $display("%05h RTNCC", saved_PC);
`endif
end
