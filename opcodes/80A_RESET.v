/******************************************************************************
 * 80A		RESET
 *
 *
 */ 

`include "decstates.v"
`include "bus_commands.v"

begin
    next_cycle <= `BUSCMD_RESET;
    decstate <= `DEC_START;
`ifdef SIM
        $display("%05h RESET", inst_start_PC);
`endif
end
