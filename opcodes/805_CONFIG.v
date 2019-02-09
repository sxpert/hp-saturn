/******************************************************************************
 * 805		CONFIG
 *
 *
 */ 

`include "decstates.v"
`include "bus_commands.v"

begin
    add_out <= C[19:0];
    next_cycle <= `BUSCMD_CONFIGURE;
    decstate <= `DEC_START;
`ifdef SIM
        $display("%05h CONFIG", inst_start_PC);
`endif
end

