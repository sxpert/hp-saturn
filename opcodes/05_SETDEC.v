/******************************************************************************
 * 05			SETDEC
 *
 *
 */ 


`include "decstates.v"

`DEC_SETDEC: begin
    hex_dec <= `MODE_DEC;
    execute_cycle <= 0;
    decstate <= `DEC_START;
`ifdef SIM
    $display("%05h SETDEC", inst_start_PC);
`endif
end
