/******************************************************************************
 * 04			SETHEX
 *
 *
 */ 

`include "decstates.v"

begin
    hex_dec <= `MODE_HEX;
    decstate <= `DEC_START;
`ifdef SIM
    $display("%05h SETHEX", inst_start_PC);
`endif
end
