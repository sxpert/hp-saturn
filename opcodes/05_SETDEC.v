/******************************************************************************
 * 05			SETDEC
 *
 *
 */ 


`include "decstates.v"

begin
    hex_dec <= `MODE_DEC;
    decstate <= `DEC_START;
`ifdef SIM
    $display("%05h SETDEC", inst_start_PC);
`endif
end
