/******************************************************************************
 * 80A		RESET
 *
 *
 */ 

`include "decstates.v"

`DEC_RESET: begin
    execute_cycle <= 0;
    decstate <= `DEC_START;
`ifdef SIM
        $display("%05h RESET\t\t\t<= NOT IMPLEMENTED YET", inst_start_PC);
`endif
end
