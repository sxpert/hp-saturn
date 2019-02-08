/******************************************************************************
 * 805		CONFIG
 *
 *
 */ 

`include "decstates.v"

`DEC_CONFIG: begin
    execute_cycle <= 0;
    decstate <= `DEC_START;
`ifdef SIM
        $display("%05h CONFIG\t\t\t<= NOT IMPLEMENTED YET", saved_PC);
`endif
end

