/******************************************************************************
 * 805		CONFIG
 *
 *
 */ 

`include "decstates.v"

begin
    decstate <= `DEC_START;
`ifdef SIM
        $display("%05h CONFIG\t\t\t<= NOT IMPLEMENTED YET", inst_start_PC);
`endif
end

