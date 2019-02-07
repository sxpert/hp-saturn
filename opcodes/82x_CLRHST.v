/******************************************************************************
 * 82x
 * 
 * lots of things there
 *
 */

`include "decstates.v"

`DEC_82X_CLRHST: begin
    HST <= HST & ~nibble;
    decstate <= `DEC_START;
`ifdef SIM
    case (nibble)
        4'h1:	 $display("%5h XM=0", saved_PC);
        4'h2:	 $display("%5h SB=0", saved_PC);
        4'h4:    $display("%5h SR=0", saved_PC);
        4'h8:	 $display("%5h MP=0", saved_PC);
        4'hf:    $display("%5h CLRHST", saved_PC);
        default: $display("%5h CLRHST	%f", saved_PC, nibble);
    endcase
`endif
end
