/******************************************************************************
 * 04			SETHEX
 *
 *
 */ 

`include "decstates.v"

//`DEC_SETHEX: 
begin
    hex_dec <= `MODE_HEX;
//    execute_cycle <= 0;
    decstate <= `DEC_START;
`ifdef SIM
    $display("%05h SETHEX", saved_PC);
`endif
end
