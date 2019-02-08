/******************************************************************************
 * 2n			P= 		n
 *
 *
 */ 

`include "decstates.v"

`DEC_P_EQ_N: begin
    P <= nibble;
    decstate <= `DEC_START;
`ifdef SIM
    $display("%05h P=\t%h", inst_start_PC, nibble);	
`endif
end
