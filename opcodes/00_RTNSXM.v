/******************************************************************************
 * 00			RTNSXM
 *
 *
 */ 

`include "decstates.v"

begin
    HST[0] <= 1;
    new_PC <= RSTK[rstk_ptr];
    RSTK[rstk_ptr] <= 0;		
    rstk_ptr <= rstk_ptr - 1;
    next_cycle <= `BUSCMD_LOAD_PC;
    decstate <= `DEC_START;
`ifdef SIM
    $display("%05h RTNSXM", inst_start_PC);
`endif
end
