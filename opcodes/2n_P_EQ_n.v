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
    $display("%05h P=\t%h", saved_PC, nibble);	
`endif
end
