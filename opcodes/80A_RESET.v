/******************************************************************************
 * 80A		RESET
 *
 *
 */ 

`include "decstates.v"

begin
    decstate <= `DEC_START;
`ifdef SIM
        $display("%05h RESET\t\t\t<= NOT IMPLEMENTED YET", inst_start_PC);
`endif
end
