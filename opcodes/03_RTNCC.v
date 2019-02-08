/******************************************************************************
 * 03			RTNCC
 *
 *
 */ 

`include "decstates.v"

begin
    Carry <= 0;
    new_PC <= RSTK[rstk_ptr];
    RSTK[rstk_ptr] <= 0;		
    rstk_ptr <= rstk_ptr - 1;
    next_cycle <= `BUSCMD_LOAD_PC;
    decstate <= `DEC_START;
`ifdef SIM
    $display("%05h RTNCC", inst_start_PC);
`endif
end
