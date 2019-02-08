/******************************************************************************
 * 805		CONFIG
 *
 *
 */ 

`include "decstates.v"
`include "bus_commands.v"

begin
    next_cycle <= `BUSCMD_CONFIGURE;
    decstate <= `DEC_START;
`ifdef SIM
        $display("%05h CONFIG", inst_start_PC);
`endif
end

